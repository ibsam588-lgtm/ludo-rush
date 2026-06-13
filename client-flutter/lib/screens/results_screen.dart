import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/game_snapshot.dart';
import '../theme/app_theme.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state    = context.read<AppState>();
    final snapshot = state.lastSnapshot;
    final myId     = state.playerId;

    bool won = false;
    String winnerName = 'Unknown';
    if (snapshot != null) {
      won = myId != null && myId == snapshot.winnerPlayerId;
      for (final s in snapshot.seats) {
        if (s.playerId == snapshot.winnerPlayerId) {
          winnerName = s.displayName;
          break;
        }
      }
    }

    return Scaffold(
      backgroundColor: context.bgPage,
      appBar: AppBar(
        backgroundColor: context.bgHeader,
        title: const Text('Match Over', style: TextStyle(
          color: AppColors.gold, fontWeight: FontWeight.bold,
        )),
        iconTheme: const IconThemeData(color: AppColors.gold),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _HeroBanner(won: won, winnerName: won ? state.displayName : winnerName),
          const SizedBox(height: 20),
          _RewardsCard(won: won),
          const SizedBox(height: 20),
          if (snapshot != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('PLAYERS', style: TextStyle(
                color: context.txtMuted, fontSize: 10, fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              )),
            ),
            _PlayerList(snapshot: snapshot, myId: myId),
            const SizedBox(height: 28),
          ],
          _ActionButtons(state: state),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final bool won;
  final String winnerName;
  const _HeroBanner({required this.won, required this.winnerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: won
              ? [const Color(0xffA51FE0), const Color(0xff1E0638)]
              : [const Color(0xffFF67B7), const Color(0xff37D5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Text(won ? '🏆' : '😞', style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 10),
          Text(won ? 'Victory!' : 'Defeat', style: const TextStyle(
            fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 4),
          Text('$winnerName ${won ? "wins this match" : "won the match"}',
            style: const TextStyle(fontSize: 13, color: Color(0xCCFFFFFF)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RewardsCard extends StatelessWidget {
  final bool won;
  const _RewardsCard({required this.won});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.strokeCardGlow),
      ),
      child: Row(
        children: [
          Expanded(child: _RewardCol(
            label: 'RATING',
            value: won ? '+12' : '−6',
            color: won ? AppColors.green : AppColors.red,
          )),
          Container(width: 1, height: 44, color: context.strokeCard),
          Expanded(child: _RewardCol(
            label: 'COINS',
            value: won ? '+100' : '+15',
            color: AppColors.gold,
          )),
        ],
      ),
    );
  }
}

class _RewardCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _RewardCol({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(
          fontSize: 24, color: color, fontWeight: FontWeight.bold,
        )),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(
          fontSize: 10, color: context.txtMuted, fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        )),
      ],
    );
  }
}

class _PlayerList extends StatelessWidget {
  final GameSnapshot snapshot;
  final String? myId;
  const _PlayerList({required this.snapshot, required this.myId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: snapshot.seats.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        final isWinner = s.playerId == snapshot.winnerPlayerId;
        final isMe     = s.playerId == myId;
        final name     = isMe ? 'You' : s.displayName;
        final color    = AppColors.seatColors[s.seat.clamp(0, 3)];

        return Container(
          margin: EdgeInsets.only(bottom: i < snapshot.seats.length - 1 ? 8 : 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: isWinner ? context.bgSel : context.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isWinner ? const Color(0x44F5B700) : context.strokeCard),
          ),
          child: Row(
            children: [
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$name${s.isBot ? " (Bot)" : ""}',
                  style: TextStyle(
                    color: context.txtPrimary, fontSize: 14, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isWinner)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0x22F5B700),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('★ Winner',
                    style: TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              else
                Text('–', style: TextStyle(color: context.txtMuted, fontSize: 13)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final AppState state;
  const _ActionButtons({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: const Color(0xff1A0800),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
              state.startBotMatch('classic_2p');
            },
            child: const Text('⚡  Play Again', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff1565C0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.gold),
              ),
            ),
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('⌂  Home', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
