/// The deltas actually applied for the completed match, before optional bonuses.
class MatchRewards {
  final int coins;
  final int rating;
  final bool practice;
  const MatchRewards(
      {required this.coins, required this.rating, required this.practice});
}
