import { createHash } from "node:crypto";
import type { AppTransaction } from "@apple/app-store-server-library/dist/models/AppTransaction";
import { appStoreVerifier } from "./app-store-purchases";
import { authenticatedPlayerId, issueSession } from "./auth";
import type { Env } from "./types";
import { badRequest, json, readJson, unauthorized } from "./utils/http";

const BUNDLE_ID = "com.corsairlabs.ludocheer";
const APPLE_APP_ID = 6834993861;

export function validateAppStoreAccount(transaction: AppTransaction, environment: string,
  now = Date.now()): string | null {
  if (transaction.bundleId !== BUNDLE_ID ||
      (environment === "Production" && transaction.appAppleId !== APPLE_APP_ID)) {
    return "This App Store account proof is for a different app.";
  }
  if (transaction.receiptType !== environment) return "This App Store account proof is for a different environment.";
  if (!transaction.appTransactionId || !/^\d{1,40}$/.test(transaction.appTransactionId)) {
    return "The App Store did not provide a recovery identity.";
  }
  if (!transaction.receiptCreationDate || transaction.receiptCreationDate > now + 300_000) {
    return "Invalid App Store account proof date.";
  }
  return null;
}

// The Apple-signed appTransactionId is stable for this Apple Account and app
// across reinstalls/devices. Never accept a client-supplied ID by itself.
export async function recoverAppStoreAccount(request: Request, env: Env): Promise<Response> {
  const body = await readJson<{ signedAppTransaction?: string }>(request);
  const proof = typeof body.signedAppTransaction === "string" ? body.signedAppTransaction.trim() : "";
  if (proof.length < 100 || proof.length > 32_768 || proof.split(".").length !== 3) {
    return badRequest("A signed App Store account proof is required.");
  }
  const sandbox = env.APP_STORE_ENVIRONMENT === "Sandbox";
  let transaction: AppTransaction;
  try {
    transaction = await (await appStoreVerifier(sandbox)).verifyAndDecodeAppTransaction(proof);
  } catch {
    return badRequest("Apple could not verify your purchasing account. Please try Restore Purchases again.");
  }
  const environment = sandbox ? "Sandbox" : "Production";
  const error = validateAppStoreAccount(transaction, environment);
  if (error) return badRequest(error);
  const accountHash = createHash("sha256")
    .update(`${BUNDLE_ID}:${environment}:${transaction.appTransactionId}`).digest("hex");
  const existing = await env.DB.prepare("SELECT user_id FROM app_store_accounts WHERE account_hash = ?")
    .bind(accountHash).first<{ user_id: string }>();
  if (!existing) {
    const guest = await authenticatedPlayerId(request, env);
    if (!guest) return unauthorized();
    // A guest cannot silently merge two different Apple accounts. Concurrent
    // first-device requests converge on one mapping through the unique keys.
    await env.DB.prepare("INSERT OR IGNORE INTO app_store_accounts (account_hash, user_id, created_at) VALUES (?, ?, ?)")
      .bind(accountHash, guest, Date.now()).run();
  }
  const account = existing ?? await env.DB.prepare("SELECT user_id FROM app_store_accounts WHERE account_hash = ?")
    .bind(accountHash).first<{ user_id: string }>();
  if (!account) return json({ error: "This player is linked to another App Store account. Reopen the game with the original Apple Account." }, { status: 409 });
  const [player, wallet, token] = await Promise.all([
    env.DB.prepare("SELECT id, display_name AS displayName, region, rating, age, country_code AS countryCode FROM users WHERE id = ?")
      .bind(account.user_id).first<Record<string, unknown>>(),
    env.DB.prepare("SELECT coins FROM wallets WHERE user_id = ?").bind(account.user_id).first<{ coins: number }>(),
    issueSession(env, account.user_id),
  ]);
  if (!player || !wallet) return json({ error: "Your purchasing account is temporarily unavailable." }, { status: 503 });
  return json({ token, player: { ...player, coins: wallet.coins } }, { headers: { "cache-control": "no-store" } });
}
