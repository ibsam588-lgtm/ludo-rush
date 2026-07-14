import { describe, expect, it } from "vitest";
import { ECONOMY, earnedGoldChests } from "../src/economy";

describe("reward economy", () => {
  it("keeps progression rewards positive and internally ordered", () => {
    expect(ECONOMY.startingCoins).toBeGreaterThan(0);
    expect(ECONOMY.dailyCoins).toBeGreaterThan(ECONOMY.onlineWinCoins);
    expect(ECONOMY.onlineWinCoins).toBeGreaterThan(
      ECONOMY.onlineFinishCoins
    );
    expect(ECONOMY.clubWinContribution).toBeGreaterThan(
      ECONOMY.clubFinishContribution
    );
    expect(ECONOMY.goldChestCoins).toBeGreaterThan(
      ECONOMY.onlineWinCoins * ECONOMY.winsPerGoldChest
    );
    expect(ECONOMY.giftCoinCosts).toEqual({
      lucky_dice: 25,
      friendship_heart: 40,
      coin_ship: 50,
      mascot_cheer: 75,
      crown_chest: 125,
      firework_castle: 200
    });
  });

  it("awards one Gold Chest for every three online wins", () => {
    expect(earnedGoldChests(0)).toBe(0);
    expect(earnedGoldChests(2)).toBe(0);
    expect(earnedGoldChests(3)).toBe(1);
    expect(earnedGoldChests(6)).toBe(2);
  });
});
