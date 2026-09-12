import { authenticatedPlayerId } from "./auth";
import type { Env } from "./types";
import { badRequest, json, notFound, readJson, unauthorized } from "./utils/http";
import { createId } from "./utils/id";

const PACKAGE_NAME = "com.ludorush.game";
const ANDROID_PUBLISHER_SCOPE = "https://www.googleapis.com/auth/androidpublisher";

export interface StoreProduct {
  consumable: boolean;
  coins: number;
}

export const GOOGLE_PLAY_PRODUCTS: Readonly<Record<string, StoreProduct>> = {
  "dice.ruby": { consumable: false, coins: 0 },
  "dice.cosmic": { consumable: false, coins: 0 },
  "board.neon": { consumable: false, coins: 0 },
  "avatar.premium_cosmic_empress": { consumable: false, coins: 0 },
  "avatar.premium_gold_champion": { consumable: false, coins: 0 },
  "avatar.premium_neon_heroine": { consumable: false, coins: 0 },
  "avatar.premium_emerald_prince": { consumable: false, coins: 0 },
  "coins.stack_1200": { consumable: true, coins: 1200 },
  "coins.chest_3500": { consumable: true, coins: 3500 },
  "coins.vault_7500": { consumable: true, coins: 7500 }
};

interface VerifyPurchaseBody {
  productId?: string;
  purchaseToken?: string;
}

interface ServiceAccount {
  client_email: string;
  private_key: string;
  token_uri?: string;
}

interface GoogleProductPurchase {
  purchaseState?: number;
  consumptionState?: number;
  acknowledgementState?: number;
  obfuscatedExternalAccountId?: string;
}

interface PurchaseRow {
  user_id: string;
  product_id: string;
  status: string;
}

let cachedAccessToken: { token: string; expiresAt: number } | null = null;

export async function routePurchaseRequest(
  request: Request,
  env: Env,
  url: URL
): Promise<Response> {
  if (
    request.method !== "POST" ||
    url.pathname !== "/api/v1/purchases/google-play/verify"
  ) {
    return notFound();
  }

  const playerId = await authenticatedPlayerId(request, env);
  if (!playerId) return unauthorized();

  const body = await readJson<VerifyPurchaseBody>(request);
  const productId = (body.productId ?? "").trim();
  const purchaseToken = (body.purchaseToken ?? "").trim();
  const product = GOOGLE_PLAY_PRODUCTS[productId];
  if (!product) return badRequest("Unknown Google Play product.");
  if (purchaseToken.length < 16 || purchaseToken.length > 4096) {
    return badRequest("A valid Google Play purchase token is required.");
  }
  if (!env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON) {
    return json(
      { error: "Google Play purchase verification is not configured." },
      { status: 503 }
    );
  }

  const transactionId = `google_play:${await sha256(purchaseToken)}`;
  const existing = await env.DB.prepare(
    "SELECT user_id, product_id, status FROM purchases WHERE transaction_id = ?"
  ).bind(transactionId).first<PurchaseRow>();
  if (
    existing &&
    (existing.user_id !== playerId || existing.product_id !== productId)
  ) {
    return json(
      { error: "This Google Play purchase is already linked to another account." },
      { status: 409 }
    );
  }
  if (existing?.status === "consumed") {
    return purchaseResponse(env, playerId, productId);
  }

  const accessToken = await googleAccessToken(env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON);
  const googlePurchase = await getGooglePurchase(
    accessToken,
    productId,
    purchaseToken
  );
  if (googlePurchase.purchaseState !== 0) {
    return json(
      { error: "Google Play has not completed this purchase." },
      { status: 409 }
    );
  }
  if (
    googlePurchase.obfuscatedExternalAccountId &&
    googlePurchase.obfuscatedExternalAccountId !== playerId
  ) {
    return json(
      { error: "This Google Play purchase belongs to another player." },
      { status: 409 }
    );
  }

  const now = Date.now();
  if (!existing) {
    const statements = [
      env.DB.prepare(
        `INSERT OR IGNORE INTO purchases
          (id, user_id, store, product_id, transaction_id, status, created_at, updated_at)
         VALUES (?, ?, 'google_play', ?, ?, 'granting', ?, ?)`
      ).bind(createId("pur"), playerId, productId, transactionId, now, now)
    ];
    if (product.coins > 0) {
      statements.push(
        env.DB.prepare(
          `UPDATE wallets
              SET coins = coins + ?, updated_at = ?
            WHERE user_id = ?
              AND EXISTS (
                SELECT 1 FROM purchases
                 WHERE transaction_id = ? AND status = 'granting'
              )`
        ).bind(product.coins, now, playerId, transactionId)
      );
    }
    statements.push(
      env.DB.prepare(
        "UPDATE purchases SET status = 'verified', updated_at = ? WHERE transaction_id = ? AND status = 'granting'"
      ).bind(now, transactionId)
    );
    await env.DB.batch(statements);
  }

  await finalizeGooglePurchase(
    accessToken,
    productId,
    purchaseToken,
    product.consumable,
    googlePurchase
  );
  if (product.consumable) {
    await env.DB.prepare(
      "UPDATE purchases SET status = 'consumed', updated_at = ? WHERE transaction_id = ?"
    ).bind(Date.now(), transactionId).run();
  }

  return purchaseResponse(env, playerId, productId);
}

async function purchaseResponse(
  env: Env,
  playerId: string,
  productId: string
): Promise<Response> {
  const [wallet, entitlements] = await Promise.all([
    env.DB.prepare("SELECT coins FROM wallets WHERE user_id = ?")
      .bind(playerId)
      .first<{ coins: number }>(),
    env.DB.prepare(
      "SELECT DISTINCT product_id AS productId FROM purchases WHERE user_id = ? AND status = 'verified' ORDER BY product_id"
    ).bind(playerId).all<{ productId: string }>()
  ]);
  return json({
    verified: true,
    productId,
    coins: wallet?.coins ?? 0,
    ownedProductIds: (entitlements.results ?? []).map((row) => row.productId)
  });
}

async function getGooglePurchase(
  accessToken: string,
  productId: string,
  purchaseToken: string
): Promise<GoogleProductPurchase> {
  const endpoint = googleProductEndpoint(productId, purchaseToken);
  const response = await fetch(endpoint, {
    headers: { authorization: `Bearer ${accessToken}` }
  });
  if (!response.ok) {
    throw new Error("Google Play could not verify this purchase.");
  }
  return response.json<GoogleProductPurchase>();
}

async function finalizeGooglePurchase(
  accessToken: string,
  productId: string,
  purchaseToken: string,
  consumable: boolean,
  purchase: GoogleProductPurchase
): Promise<void> {
  if (consumable && purchase.consumptionState === 1) return;
  if (!consumable && purchase.acknowledgementState === 1) return;
  const action = consumable ? "consume" : "acknowledge";
  const response = await fetch(`${googleProductEndpoint(productId, purchaseToken)}:${action}`, {
    method: "POST",
    headers: {
      authorization: `Bearer ${accessToken}`,
      "content-type": "application/json"
    },
    body: "{}"
  });
  if (!response.ok) {
    throw new Error("Google Play could not finalize this purchase. Please try again.");
  }
}

function googleProductEndpoint(productId: string, purchaseToken: string): string {
  return `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE_NAME}/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`;
}

async function googleAccessToken(rawServiceAccount: string): Promise<string> {
  if (cachedAccessToken && cachedAccessToken.expiresAt > Date.now() + 60_000) {
    return cachedAccessToken.token;
  }
  let account: ServiceAccount;
  try {
    account = JSON.parse(rawServiceAccount) as ServiceAccount;
  } catch {
    throw new Error("Google Play purchase verification credentials are invalid.");
  }
  if (!account.client_email || !account.private_key) {
    throw new Error("Google Play purchase verification credentials are incomplete.");
  }
  const tokenUri = account.token_uri || "https://oauth2.googleapis.com/token";
  const now = Math.floor(Date.now() / 1000);
  const header = base64UrlJson({ alg: "RS256", typ: "JWT" });
  const claims = base64UrlJson({
    iss: account.client_email,
    scope: ANDROID_PUBLISHER_SCOPE,
    aud: tokenUri,
    iat: now,
    exp: now + 3600
  });
  const unsigned = `${header}.${claims}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemBytes(account.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned)
  );
  const assertion = `${unsigned}.${base64UrlBytes(new Uint8Array(signature))}`;
  const response = await fetch(tokenUri, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion
    })
  });
  if (!response.ok) {
    throw new Error("Google Play purchase verification could not authenticate.");
  }
  const payload = await response.json<{ access_token?: string; expires_in?: number }>();
  if (!payload.access_token) {
    throw new Error("Google Play purchase verification returned no access token.");
  }
  cachedAccessToken = {
    token: payload.access_token,
    expiresAt: Date.now() + (payload.expires_in ?? 3600) * 1000
  };
  return payload.access_token;
}

async function sha256(value: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function pemBytes(value: string): ArrayBuffer {
  const base64 = value
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index++) {
    bytes[index] = binary.charCodeAt(index);
  }
  return bytes.buffer;
}

function base64UrlJson(value: unknown): string {
  return base64UrlBytes(new TextEncoder().encode(JSON.stringify(value)));
}

function base64UrlBytes(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}
