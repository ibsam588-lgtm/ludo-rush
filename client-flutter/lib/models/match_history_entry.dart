class MatchHistoryEntry {
  final String id;
  final String mode;
  final bool won;
  final bool practice;
  final int playedAt;
  final int finishRank;
  final int ratingDelta;
  final int coinsDelta;
  final String opponents;

  const MatchHistoryEntry({
    required this.id,
    required this.mode,
    required this.won,
    required this.practice,
    required this.playedAt,
    required this.finishRank,
    required this.ratingDelta,
    required this.coinsDelta,
    required this.opponents,
  });

  factory MatchHistoryEntry.fromJson(Map<String, dynamic> json) =>
      MatchHistoryEntry(
        id: json['id'] as String? ?? '',
        mode: json['mode'] as String? ?? 'classic_2p',
        won: json['won'] == true || json['won'] == 1,
        practice: json['practice'] == true,
        playedAt: (json['endedAt'] as num?)?.toInt() ??
            (json['playedAt'] as num?)?.toInt() ??
            0,
        finishRank: (json['finishRank'] as num?)?.toInt() ?? 0,
        ratingDelta: (json['ratingDelta'] as num?)?.toInt() ?? 0,
        coinsDelta: (json['coinsDelta'] as num?)?.toInt() ?? 0,
        opponents: json['opponents'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode,
        'won': won,
        'practice': practice,
        'playedAt': playedAt,
        'finishRank': finishRank,
        'ratingDelta': ratingDelta,
        'coinsDelta': coinsDelta,
        'opponents': opponents,
      };
}
