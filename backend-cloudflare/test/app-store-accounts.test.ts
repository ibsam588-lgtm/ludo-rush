import { DatabaseSync } from "node:sqlite";
import { readFileSync } from "node:fs";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { recoverAppStoreAccount, validateAppStoreAccount } from "../src/app-store-accounts";
import { appStoreVerifier } from "../src/app-store-purchases";
import { authenticatedPlayerId, issueSession } from "../src/auth";
import type { Env } from "../src/types";

vi.mock("../src/app-store-purchases", () => ({ appStoreVerifier: vi.fn() }));
const proof = "a".repeat(90) + "." + "b".repeat(90) + ".signature";
const valid = { bundleId: "com.corsairlabs.ludocheer", appAppleId: 6834993861,
  appTransactionId: "1000000123456", receiptType: "Production", receiptCreationDate: Date.now() - 1000 };
let sql: DatabaseSync;
let env: Env;
const decode = vi.fn();

beforeEach(() => {
  sql = new DatabaseSync(":memory:");
  sql.exec("CREATE TABLE users (id TEXT PRIMARY KEY, display_name TEXT, region TEXT, rating INTEGER, age INTEGER, country_code TEXT);" +
    "CREATE TABLE wallets (user_id TEXT PRIMARY KEY, coins INTEGER);" +
    "CREATE TABLE auth_sessions (token_hash TEXT PRIMARY KEY, user_id TEXT, created_at INTEGER, expires_at INTEGER);");
  sql.exec(readFileSync(new URL("../migrations/0007_app_store_accounts.sql", import.meta.url), "utf8"));
  for (const [id, coins] of [["original", 4300], ["new-device", 500]]) {
    sql.prepare("INSERT INTO users VALUES (?, 'James', 'auto', 1000, 25, 'US')").run(id,);
    sql.prepare("INSERT INTO wallets VALUES (?, ?)").run(id, coins);
  }
  env = { DB: { prepare(query: string) {
    return { bind(...values: Array<string | number>) {
      return {
        first: async () => sql.prepare(query).get(...values) ?? null,
        run: async () => ({ meta: { changes: sql.prepare(query).run(...values).changes } }),
      };
    } };
  } } } as unknown as Env;
  decode.mockReset().mockResolvedValue(valid);
  vi.mocked(appStoreVerifier).mockResolvedValue({ verifyAndDecodeAppTransaction: decode } as never);
});
afterEach(() => sql.close());

function request(token?: string) {
  return new Request("https://game/api/v1/auth/app-store", { method: "POST",
    headers: { "content-type": "application/json", ...(token ? { authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify({ signedAppTransaction: proof, playerId: "attacker-supplied-id" }),
  });
}

describe("App Store account recovery", () => {
  it("links verified Apple identity once and recovers the same wallet after reinstall", async () => {
    const first = await recoverAppStoreAccount(request(await issueSession(env, "original")), env);
    expect(first.status).toBe(200);
    const recovery = await recoverAppStoreAccount(request(await issueSession(env, "new-device")), env);
    const data = await recovery.json() as { token: string; player: { id: string; coins: number } };
    expect(data.player).toMatchObject({ id: "original", coins: 4300 });
    expect(recovery.headers.get("cache-control")).toBe("no-store");
    expect(await authenticatedPlayerId(new Request("https://game", { headers: { authorization: `Bearer ${data.token}` } }), env)).toBe("original");
    expect(sql.prepare("SELECT COUNT(*) AS count FROM app_store_accounts").get()?.count).toBe(1);
    expect(sql.prepare("SELECT coins FROM wallets WHERE user_id='new-device'").get()?.coins).toBe(500);
  });
  it("recovers with Apple proof when the previous guest session is gone", async () => {
    await recoverAppStoreAccount(request(await issueSession(env, "original")), env);
    const response = await recoverAppStoreAccount(request(), env);
    expect(response.status).toBe(200);
    expect((await response.json() as { player: { id: string } }).player.id).toBe("original");
  });
  it("does not create an account link from unauthenticated input", async () => {
    expect((await recoverAppStoreAccount(request(), env)).status).toBe(401);
    expect(sql.prepare("SELECT COUNT(*) AS count FROM app_store_accounts").get()?.count).toBe(0);
  });
  it("never merges two Apple accounts into the same guest", async () => {
    const token = await issueSession(env, "original");
    await recoverAppStoreAccount(request(token), env);
    decode.mockResolvedValue({ ...valid, appTransactionId: "1000000987654" });
    expect((await recoverAppStoreAccount(request(token), env)).status).toBe(409);
  });
  it("refuses forged Apple proof before reading or granting an account", async () => {
    decode.mockRejectedValue(new Error("Invalid Apple signature"));
    expect((await recoverAppStoreAccount(request(), env)).status).toBe(400);
    expect(sql.prepare("SELECT COUNT(*) AS count FROM app_store_accounts").get()?.count).toBe(0);
  });
  it("rejects mismatched apps, environments, IDs and future-dated proofs", async () => {
    for (const changed of [{ bundleId: "other.app" }, { appAppleId: 1 }, { receiptType: "Sandbox" },
      { appTransactionId: "" }, { receiptCreationDate: Date.now() + 600_000 }]) {
      const value = { ...valid, ...changed };
      expect(validateAppStoreAccount(value, "Production")).not.toBeNull();
      decode.mockResolvedValue(value);
      expect((await recoverAppStoreAccount(request(), env)).status).toBe(400);
    }
  });
  it("uses the Sandbox verifier only in the isolated Sandbox environment", async () => {
    decode.mockResolvedValue({ ...valid, receiptType: "Sandbox" });
    const response = await recoverAppStoreAccount(request(await issueSession(env, "original")), { ...env, APP_STORE_ENVIRONMENT: "Sandbox" });
    expect(response.status).toBe(200);
    expect(appStoreVerifier).toHaveBeenLastCalledWith(true);
  });
});
