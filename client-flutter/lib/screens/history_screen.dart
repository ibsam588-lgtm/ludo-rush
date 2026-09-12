import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match_history_entry.dart';
import '../services/app_platform_service.dart';
import '../services/sound_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      final history = state.matchHistory;
      final completed = history.where((entry) => !entry.practice).toList();
      final recentWins = completed.where((entry) => entry.won).length;
      final winRate = completed.isEmpty
          ? 0
          : ((recentWins / completed.length) * 100).round();
      return Scaffold(
        backgroundColor: bgDeep,
        appBar: AppBar(
          backgroundColor: const Color(0xFF42104F),
          foregroundColor: Colors.white,
          title: const Text('Match History'),
          actions: [
            IconButton(
              tooltip: 'Share diagnostics',
              onPressed: () async {
                SoundService.tap();
                await AppPlatformService.shareText(state.diagnosticsSummary());
              },
              icon: const Icon(Icons.health_and_safety_outlined),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: state.refreshSocial,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
            children: [
              Semantics(
                label:
                    '${state.gamesPlayed} games, ${state.wins} wins, $winRate percent recent win rate',
                child: Row(children: [
                  _StatCard(
                      'Games', '${state.gamesPlayed}', Icons.casino_rounded),
                  const SizedBox(width: 8),
                  _StatCard(
                      'Wins', '${state.wins}', Icons.emoji_events_rounded),
                  const SizedBox(width: 8),
                  _StatCard('Recent', '$winRate%', Icons.insights_rounded),
                ]),
              ),
              const SizedBox(height: 16),
              if (history.isEmpty)
                const _EmptyHistory()
              else
                for (final entry in history) ...[
                  _HistoryTile(entry: entry),
                  const SizedBox(height: 9),
                ],
              if (state.diagnosticEvents.isNotEmpty) ...[
                const SizedBox(height: 10),
                ExpansionTile(
                  collapsedIconColor: Colors.white70,
                  iconColor: goldColor,
                  textColor: Colors.white,
                  collapsedTextColor: Colors.white,
                  title: const Text('Connection diagnostics'),
                  subtitle: const Text(
                    'Recent local events for troubleshooting',
                    style: TextStyle(color: Colors.white60),
                  ),
                  children: [
                    for (final event in state.diagnosticEvents.take(8))
                      ListTile(
                        dense: true,
                        leading:
                            const Icon(Icons.circle, size: 8, color: goldColor),
                        title: Text(event,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFF42104F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x55FFD426)),
          ),
          child: Column(children: [
            Icon(icon, color: goldColor, size: 21),
            const SizedBox(height: 5),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ]),
        ),
      );
}

class _HistoryTile extends StatelessWidget {
  final MatchHistoryEntry entry;
  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = entry.practice
        ? boardBlue
        : entry.won
            ? boardGreen
            : boardRed;
    final title = entry.practice
        ? 'Practice match'
        : entry.won
            ? 'Victory'
            : 'Match complete';
    final date = DateTime.fromMillisecondsSinceEpoch(entry.playedAt).toLocal();
    final when =
        '${date.month}/${date.day}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Semantics(
      label: '$title, ${_modeLabel(entry.mode)}, $when',
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFF32103C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(150)),
        ),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(55),
            foregroundColor: color,
            child: Icon(entry.won ? Icons.emoji_events : Icons.sports_esports),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  '${_modeLabel(entry.mode)}${entry.opponents.isEmpty ? '' : ' • ${entry.opponents}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(when,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${entry.coinsDelta >= 0 ? '+' : ''}${entry.coinsDelta} coins',
                style: TextStyle(color: color, fontWeight: FontWeight.w800)),
            if (!entry.practice)
              Text(
                  '${entry.ratingDelta >= 0 ? '+' : ''}${entry.ratingDelta} rating',
                  style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ]),
        ]),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Column(children: [
          Icon(Icons.history_rounded, size: 54, color: Colors.white38),
          SizedBox(height: 12),
          Text('Your completed matches will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 15)),
        ]),
      );
}

String _modeLabel(String mode) => switch (mode) {
      AppState.snakesLaddersMode => 'Snakes & Ladders',
      'classic_3p' => '3 Player Ludo',
      'classic_4p' => '4 Player Ludo',
      'rush_2p' => '2 Player Rush',
      'rush_4p' => '4 Player Rush',
      _ => '2 Player Ludo',
    };
