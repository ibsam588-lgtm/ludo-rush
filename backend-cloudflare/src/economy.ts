export const ECONOMY = {
  startingCoins: 500,
  dailyCoins: 150,
  onlineWinCoins: 100,
  onlineFinishCoins: 15,
  clubWinContribution: 10,
  clubFinishContribution: 3,
  goldChestCoins: 500,
  winsPerGoldChest: 3,
  giftCoinCosts: {
    lucky_dice: 25,
    coin_ship: 50,
    crown_chest: 125
  } as Record<string, number>
} as const;

export function earnedGoldChests(wins: number): number {
  const completedWins = Number.isFinite(wins) ? Math.max(0, wins) : 0;
  return Math.floor(completedWins / ECONOMY.winsPerGoldChest);
}
