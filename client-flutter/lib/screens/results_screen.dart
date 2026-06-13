import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/game_snapshot.dart';
import '../theme/app_theme.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _confettiCtrl;
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryAnim;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

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
      backgroundColor: bgDeep.withAlpha(204),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dark overlay
          Container(color: bgDeep.withAlpha(200)),

          // Confetti
          if (won)
            AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, __) => CustomPaint(
                painter: _ConfettiPainter(_confettiCtrl.value),
              ),
            ),

          // Modal content
          Center(
            child: ScaleTransition(
              scale: _entryAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gold stars badge
                    _StarsBadge(won: won),
                    const SizedBox(height: 16),

                    // Red ribbon banner
                    _RibbonBanner(won: won),
                    const SizedBox(height: 16),

                    // Result text
                    Text(
                      won ? 'YOU WON!' : 'GOOD GAME!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28, fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      won ? '${state.displayName} wins this match!' : '$winnerName won the match',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Rewards
                    _RewardsRow(won: won),
                    const SizedBox(height: 16),

                    // Player list
                    if (snapshot != null) ...[
                      _PlayerList(snapshot: snapshot, myId: myId),
                      const SizedBox(height: 20),
                    ],

                    // Buttons
                    _ActionBtn(
                      label: won ? '⚡  Play Again' : '🎲  Try Again',
                      gradient: const [greenBtn, greenDark],
                      onTap: () {
                        Navigator.of(context).popUntil((r) => r.isFirst);
                        state.startBotMatch('classic_2p');
                      },
                    ),
                    const SizedBox(height: 10),
                    _ActionBtn(
                      label: '🏠  Home',
                      gradient: [blueBtn, const Color(0xFF1565C0)],
                      onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    ),
                    const SizedBox(height: 10),
                    _ActionBtn(
                      label: '📤  Share',
                      gradient: [bgMagenta, bgPurple],
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stars badge ────────────────────────────────────────────────────────────────

class _StarsBadge extends StatelessWidget {
  final bool won;
  const _StarsBadge({required this.won});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.star, color: won ? goldColor : Colors.grey, size: 36),
        Icon(Icons.star, color: won ? goldColor : Colors.grey, size: 48),
        Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('👑', style: TextStyle(fontSize: 22)),
          Text('LUDO RUSH',
            style: TextStyle(
              color: won ? goldColor : Colors.grey,
              fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1,
            )),
        ]),
        Icon(Icons.star, color: won ? goldColor : Colors.grey, size: 48),
        Icon(Icons.star, color: won ? goldColor : Colors.grey, size: 36),
      ],
    );
  }
}

// ── Ribbon banner ──────────────────────────────────────────────────────────────

class _RibbonBanner extends StatelessWidget {
  final bool won;
  const _RibbonBanner({required this.won});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: won
              ? [const Color(0xFFE53935), const Color(0xFFC62828)]
              : [const Color(0xFF9E9E9E), const Color(0xFF616161)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
      ),
      child: Text(
        won ? 'GREAT GAME!' : 'BETTER LUCK NEXT TIME',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18, fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
        ),
      ),
    );
  }
}

// ── Rewards row ────────────────────────────────────────────────────────────────

class _RewardsRow extends StatelessWidget {
  final bool won;
  const _RewardsRow({required this.won});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: bgPurple,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: goldColor.withAlpha(80)),
      ),
      child: Row(
        children: [
          _RewardItem(
            label: 'RATING',
            value: won ? '+12' : '−6',
            color: won ? greenBtn : boardRed,
            icon: '🏆',
          ),
          Container(width: 1, height: 48, color: Colors.white12),
          _RewardItem(
            label: 'COINS',
            value: won ? '+100' : '+15',
            color: goldColor,
            icon: '🪙',
          ),
          Container(width: 1, height: 48, color: Colors.white12),
          _RewardItem(
            label: 'XP',
            value: won ? '+150' : '+50',
            color: blueBtn,
            icon: '⭐',
          ),
        ],
      ),
    );
  }
}

class _RewardItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String icon;
  const _RewardItem({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
            color: color, fontSize: 20, fontWeight: FontWeight.bold,
          )),
          Text(label, style: const TextStyle(
            color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5,
          )),
        ],
      ),
    );
  }
}

// ── Player list ────────────────────────────────────────────────────────────────

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
        final color    = AppColors.seatColor(s.seat);

        return Container(
          margin: EdgeInsets.only(bottom: i < snapshot.seats.length - 1 ? 6 : 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isWinner ? goldColor.withAlpha(25) : bgPurple,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isWinner ? goldColor.withAlpha(100) : Colors.white12),
          ),
          child: Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${isMe ? "You" : s.displayName}${s.isBot ? " (Bot)" : ""}',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isWinner)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: goldColor.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('★ Winner',
                    style: TextStyle(color: goldColor, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              else
                const Text('–', style: TextStyle(color: Colors.white38, fontSize: 13)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Action button ──────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: gradient.first.withAlpha(80), blurRadius: 10)],
        ),
        child: Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
          )),
      ),
    );
  }
}

// ── Confetti painter ───────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter(this.t);

  static const _colors = [
    goldColor, boardRed, boardGreen, boardBlue, boardYellow,
    Colors.white, Colors.pink,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (int i = 0; i < 60; i++) {
      final baseX = ((i * 137 + 11) % 1000) / 1000.0 * size.width;
      final speedY = 80.0 + (i % 5) * 40.0;
      final y = (((i * 0.1) + t * speedY) % (size.height + 20)) - 10;
      final x = baseX + math.sin(t * 4 + i * 0.3) * 20;

      paint.color = _colors[i % _colors.length].withAlpha(200);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 3 + i * 0.5);
      canvas.drawRect(Rect.fromLTWH(-4, -4, 8, 5), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
