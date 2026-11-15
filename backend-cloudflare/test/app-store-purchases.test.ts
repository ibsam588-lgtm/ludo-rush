import { describe, expect, it } from "vitest";
import { SignedDataVerifier } from "@apple/app-store-server-library/dist/jws_verification";
import { Environment } from "@apple/app-store-server-library/dist/models/Environment";
import { Buffer } from "node:buffer";
import { appAccountToken, validateAppStoreClaims } from "../src/app-store-purchases";
import { APPLE_ROOT_CERTIFICATES } from "../src/apple-roots";

const player = "usr_example_player";
const valid = {
  productId: "coins.stack_1200", bundleId: "com.corsairlabs.ludocheer",
  transactionId: "200000000001", environment: "Production", quantity: 1,
  type: "Consumable", purchaseDate: Date.now() - 60_000,
  appAccountToken: appAccountToken(player),
};

describe("App Store purchase security", () => {
  it("binds checkout to a stable UUIDv5 player identity", () => {
    expect(appAccountToken('https://example.com')).toBe('4fd35a71-71ef-5a55-a9d9-aa75c889a6d0');
    expect(appAccountToken(player)).toMatch(/^[0-9a-f-]{14}5[0-9a-f-]{21}$/);
    expect(appAccountToken(player)).not.toBe(appAccountToken('another_player'));
  });
  it("accepts a matching verified Apple purchase", () => {
    expect(validateAppStoreClaims(valid, valid.productId, player, "Production")).toBeNull();
  });
  it("rejects replay to another guest, mismatched products, refunds and sandbox grants", () => {
    for (const changed of [
      { appAccountToken: appAccountToken('attacker') }, { productId: 'coins.vault_7500' },
      { bundleId: 'com.other.game' }, { revocationDate: Date.now() },
      { environment: 'Sandbox' }, { quantity: 10 }, { type: 'Non-Consumable' },
      { transactionId: '' }, { purchaseDate: Date.now() + 3_600_000 },
    ]) {
      expect(validateAppStoreClaims({ ...valid, ...changed }, valid.productId, player, 'Production')).not.toBeNull();
    }
  });
  it("does not accept an unsigned or client-forged JWS", async () => {
    const verifier = new SignedDataVerifier(APPLE_ROOT_CERTIFICATES.map(c => Buffer.from(c, 'base64')),
      true, Environment.PRODUCTION, valid.bundleId, 6834993861);
    const encode = (value: unknown) => Buffer.from(JSON.stringify(value)).toString('base64url');
    await expect(verifier.verifyAndDecodeTransaction(`${encode({ alg: 'none' })}.${encode(valid)}.`)).rejects.toThrow();
  });
});
