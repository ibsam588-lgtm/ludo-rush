import { describe, expect, it } from "vitest";
import { GOOGLE_PLAY_PRODUCTS } from "../src/purchases";

describe("Google Play product catalog", () => {
  it("uses unique immutable ids and positive coin grants", () => {
    const ids = Object.keys(GOOGLE_PLAY_PRODUCTS);
    expect(ids).toHaveLength(10);
    expect(new Set(ids).size).toBe(ids.length);
    expect(ids.every((id) => /^[a-z0-9._]+$/.test(id))).toBe(true);

    const consumables = Object.entries(GOOGLE_PLAY_PRODUCTS)
      .filter(([, product]) => product.consumable);
    expect(consumables.map(([id]) => id)).toEqual([
      "coins.stack_1200",
      "coins.chest_3500",
      "coins.vault_7500"
    ]);
    expect(consumables.every(([, product]) => product.coins > 0)).toBe(true);
  });

  it("never grants coins for permanent cosmetic entitlements", () => {
    for (const product of Object.values(GOOGLE_PLAY_PRODUCTS)) {
      if (!product.consumable) expect(product.coins).toBe(0);
    }
  });
});
