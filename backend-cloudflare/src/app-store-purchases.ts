import { Buffer } from "node:buffer";
import { createHash } from "node:crypto";
import type { SignedDataVerifier } from "@apple/app-store-server-library/dist/jws_verification";
import { Environment } from "@apple/app-store-server-library/dist/models/Environment";
import type { JWSTransactionDecodedPayload } from "@apple/app-store-server-library/dist/models/JWSTransactionDecodedPayload";
import { APPLE_ROOT_CERTIFICATES } from "./apple-roots";
import { authenticatedPlayerId } from "./auth";
import { GOOGLE_PLAY_PRODUCTS, purchaseResponse } from "./purchases";
import type { Env } from "./types";
import { badRequest, json, readJson, unauthorized } from "./utils/http";
import { createId } from "./utils/id";

const BUNDLE_ID = "com.corsairlabs.ludocheer";
const APPLE_APP_ID = 6834993861;
const roots = APPLE_ROOT_CERTIFICATES.map((certificate) => Buffer.from(certificate, "base64"));
let productionVerifier: SignedDataVerifier | undefined;
let sandboxVerifier: SignedDataVerifier | undefined;

async function verifier(sandbox: boolean): Promise<SignedDataVerifier> {
  // Apple's OCSP dependency seeds a random generator while its module loads.
  // Workers allow this only inside a request, so defer importing the library.
  const { SignedDataVerifier } = await import("@apple/app-store-server-library/dist/jws_verification");
  if (sandbox) {
    return sandboxVerifier ??= new SignedDataVerifier(roots, true, Environment.SANDBOX, BUNDLE_ID);
  }
  return productionVerifier ??= new SignedDataVerifier(roots, true, Environment.PRODUCTION, BUNDLE_ID, APPLE_APP_ID);
}

// RFC 4122 UUIDv5, matching Uuid.NAMESPACE_URL in the Flutter checkout. An
// authenticated guest ID is bound to Apple's signed appAccountToken claim.
export function appAccountToken(playerId: string): string {
  const namespace = Buffer.from("6ba7b8119dad11d180b400c04fd430c8", "hex");
  const hash = createHash("sha1").update(namespace).update(playerId, "utf8").digest();
  hash[6] = (hash[6] & 0x0f) | 0x50;
  hash[8] = (hash[8] & 0x3f) | 0x80;
  const value = hash.subarray(0, 16).toString("hex");
  return `${value.slice(0, 8)}-${value.slice(8, 12)}-${value.slice(12, 16)}-${value.slice(16, 20)}-${value.slice(20)}`;
}

export function validateAppStoreClaims(
  transaction: JWSTransactionDecodedPayload,
  productId: string,
  playerId: string,
  expectedEnvironment: string,
  now = Date.now()
): string | null {
  const product = GOOGLE_PLAY_PRODUCTS[productId];
  if (!product || transaction.productId !== productId || transaction.bundleId !== BUNDLE_ID) {
    return "This App Store transaction is for a different product or app.";
  }
  if (transaction.environment !== expectedEnvironment) return "This purchase is for a different App Store environment.";
  if (!transaction.transactionId || !/^\d{1,40}$/.test(transaction.transactionId)) return "Invalid App Store transaction.";
  if (transaction.appAccountToken?.toLowerCase() !== appAccountToken(playerId)) return "This App Store purchase belongs to another player.";
  if (transaction.revocationDate != null) return "This App Store purchase was revoked or refunded.";
  if (transaction.quantity !== 1) return "Unsupported App Store purchase quantity.";
  if (transaction.type !== (product.consumable ? "Consumable" : "Non-Consumable")) return "Incorrect App Store product type.";
  if (!transaction.purchaseDate || transaction.purchaseDate > now + 300_000) return "Invalid App Store purchase date.";
  return null;
}

export async function verifyAppStorePurchase(request: Request, env: Env): Promise<Response> {
  const playerId = await authenticatedPlayerId(request, env);
  if (!playerId) return unauthorized();
  const body = await readJson<{ productId?: string; signedTransaction?: string }>(request);
  const productId = typeof body.productId === "string" ? body.productId.trim() : "";
  const signedTransaction = typeof body.signedTransaction === "string" ? body.signedTransaction.trim() : "";
  const product = GOOGLE_PLAY_PRODUCTS[productId];
  if (!product) return badRequest("Unknown App Store product.");
  if (signedTransaction.length < 100 || signedTransaction.length > 32_768 || signedTransaction.split(".").length !== 3) {
    return badRequest("A valid signed App Store transaction is required.");
  }
  // Sandbox must be explicitly configured on an isolated beta backend. Never
  // fall back from production to sandbox verification for a live coin wallet.
  const sandbox = env.APP_STORE_ENVIRONMENT === "Sandbox";
  let transaction: JWSTransactionDecodedPayload;
  try {
    transaction = await (await verifier(sandbox)).verifyAndDecodeTransaction(signedTransaction);
  } catch {
    return badRequest("Apple could not verify this transaction. Please try restoring your purchase.");
  }
  const claimError = validateAppStoreClaims(transaction, productId, playerId, sandbox ? "Sandbox" : "Production");
  if (claimError) return badRequest(claimError);

  const transactionId = `app_store:${sandbox ? "sandbox:" : ""}${transaction.transactionId}`;
  const existing = await env.DB.prepare("SELECT user_id, product_id FROM purchases WHERE transaction_id = ?")
    .bind(transactionId).first<{ user_id: string; product_id: string }>();
  if (existing && (existing.user_id !== playerId || existing.product_id !== productId)) {
    return json({ error: "This App Store purchase is already linked to another account." }, { status: 409 });
  }
  const now = Date.now();
  // D1 executes this batch as one transaction. The inserted row's unique ID
  // fences the wallet grant, including concurrent retries of the same JWS.
  const purchaseId = createId("pur");
  const statements = [env.DB.prepare(
    `INSERT OR IGNORE INTO purchases
       (id, user_id, store, product_id, transaction_id, status, created_at, updated_at)
     VALUES (?, ?, 'app_store', ?, ?, 'granting', ?, ?)`
  ).bind(purchaseId, playerId, productId, transactionId, now, now)];
  if (product.coins > 0) {
    statements.push(env.DB.prepare(
      `UPDATE wallets SET coins = coins + ?, updated_at = ? WHERE user_id = ?
       AND EXISTS (SELECT 1 FROM purchases WHERE id = ? AND status = 'granting')`
    ).bind(product.coins, now, playerId, purchaseId));
  }
  statements.push(env.DB.prepare(
    "UPDATE purchases SET status = ?, updated_at = ? WHERE id = ? AND status = 'granting'"
  ).bind(product.consumable ? "consumed" : "verified", now, purchaseId));
  await env.DB.batch(statements);
  return purchaseResponse(env, playerId, productId);
}
