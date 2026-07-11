import type { Env } from "./types";

const SESSION_TTL_MS = 180 * 24 * 60 * 60 * 1000;

export async function issueSession(env: Env, userId: string): Promise<string> {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  const token = base64Url(bytes);
  const tokenHash = await hashToken(token);
  const now = Date.now();
  await env.DB.prepare(
    "INSERT INTO auth_sessions (token_hash, user_id, created_at, expires_at) VALUES (?, ?, ?, ?)"
  ).bind(tokenHash, userId, now, now + SESSION_TTL_MS).run();
  return token;
}

export async function authenticatedPlayerId(
  request: Request,
  env: Env
): Promise<string | null> {
  const authorization = request.headers.get("authorization") ?? "";
  const match = /^Bearer\s+(.+)$/i.exec(authorization.trim());
  const queryToken = new URL(request.url).searchParams.get("token") ?? "";
  const token = match?.[1] ?? queryToken;
  if (!token) return null;
  const tokenHash = await hashToken(token);
  const row = await env.DB.prepare(
    "SELECT user_id FROM auth_sessions WHERE token_hash = ? AND expires_at > ?"
  ).bind(tokenHash, Date.now()).first<{ user_id: string }>();
  return row?.user_id ?? null;
}

async function hashToken(token: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(token)
  );
  return Array.from(new Uint8Array(digest))
    .map((value) => value.toString(16).padStart(2, "0"))
    .join("");
}

function base64Url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}
