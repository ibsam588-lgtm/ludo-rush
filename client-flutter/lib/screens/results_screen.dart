import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/game_snapshot.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  RESULTS SCREEN — Celebratory match end screen
// ═══════════════════════════════════════════════════════════════════════════════

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {

  late final AnimationController _confettiCtrl;
  late final AnimationController _entryCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _shimmerCtrl;

  late final Animation<double> _entryScale;
  late final Animation<double> _entryFade;

  @override
  void initState() {
    super.initState();

    _confettiCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 4),
    )..repeat();

    _entryCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    );
    _entryScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut),
    );
    _entryFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: const Interval(0, 0.4, curve: Curves.easeOut)),
    );

    _glowCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _shimmerCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat();

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _entryCtrl.dispose();
    _glowCtrl.dispose();
    _shimmerCtrl.dispose();
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
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred dark backdrop
          Container(color: const Color(0xEE08001A)),

          // Confetti (winner only)
          if (won)
            AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, __) => CustomPaint(
                painter: _ConfettiPainter(_confettiCtrl.value),
              ),
            ),

          // Floating glow orbs
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ResultGlowPainter(_glowCtrl.value, won),
            ),
          ),

          // Modal card
          Center(
            child: FadeTransition(
              opacity: _entryFade,
              child: ScaleTransition(
                scale: _entryScale,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0030),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: won
                            ? const Color(0xAAFFD426)
                            : const Color(0x55FFFFFF),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: won
                              ? const Color(0x44FFD426)
                              : const Color(0x22FFFFFF),
                          blurRadius: 32,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Trophy / result icon
                        _TrophyBadge(won: won, glow: _glowCtrl, shimmer: _shimmerCtrl),
                        const SizedBox(height: 16),

                        // Result headline
                        _ResultHeadline(won: won, winnerName: winnerName, state: state),
                        const SizedBox(height: 18),

                        // Rewards row
                        _RewardsRow(won: won),
                        const SizedBox(height: 14),

                        // Player list
                        if (snapshot != null)
                          _PlayerList(snapshot: snapshot, myId: myId),

                        const SizedBox(height: 18),

                        // Action buttons
                        _ActionBtn(
                          label: won ? '⚡  Play Again' : '🎲  Try Again',
                          colors: [const Color(0xFF43A047), const Color(0xFF1B5E20)],
                          onTap: () {
                            Navigator.of(context).popUntil((r) => r.isFirst);
                            state.startBotMatch('classic_2p');
                          },
                        ),
                        const SizedBox(height: 10),
                        _ActionBtn(
                          label: '🏠  Back to Lobby',
                          colors: [const Color(0xFF0288D1), const Color(0xFF01579B)],
                          onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                        ),
                        const SizedBox(height: 10),
                        _ActionBtn(
                          label: '📤  Share Result',
                          colors: [const Color(0xFF8E24AA), const Color(0xFF4A148C)],
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trophy badge ─────────────────────────────────────────────────────────────

class _TrophyBadge extends StatelessWidget {
  final bool won;
  final AnimationController glow;
  final AnimationController shimmer;
  const _TrophyBadge({required this.won, required this.glow, required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glow,
      builder: (_, __) {
        final g = 0.4 + 0.6 * glow.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_rounded,
                  color: won ? goldColor.withAlpha((g * 180).round()) : Colors.grey.shade700,
                  size: 28),
                Icon(Icons.star_rounded,
                  color: won ? goldColor.withAlpha((g * 220).round()) : Colors.grey.shade700,
                  size: 36),
                // Center icon
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: won
                          ? [
                              goldColor.withAlpha((g * 80).round()),
                              const Color(0xFF1A0040),
                            ]
                          : [const Color(0x225A5A5A), const Color(0xFF1A0040)],
                    ),
                    border: Border.all(
                      color: won
                          ? goldColor.withAlpha((g * 200).round())
                          : Colors.white24,
                      width: 2,
                    ),
                    boxShadow: won ? [
                      BoxShadow(
                        color: goldColor.withAlpha((g * 80).round()),
                        blurRadius: 20,
                      ),
                    ] : null,
                  ),
                  child: Center(
                    child: Text(won ? '🏆' : '🎮',
                      style: const TextStyle(fontSize: 32)),
                  ),
                ),
                Icon(Icons.star_rounded,
                  color: won ? goldColor.withAlpha((g * 220).round()) : Colors.grey.shade700,
                  size: 36),
                Icon(Icons.star_rounded,
                  color: won ? goldColor.withAlpha((g * 180).round()) : Colors.grey.shade700,
                  size: 28),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ── Result headline ──────────────────────────────────────────────────────────

class _ResultHeadline extends StatelessWidget {
  final bool won;
  final String winnerName;
  final AppState state;
  const _ResultHeadline({required this.won, required this.winnerName, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: won
                  ? [const Color(0xFFFF6B35), const Color(0xFFE53935)]
                  : [const Color(0xFF455A64), const Color(0xFF263238)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            won ? '🎉  VICTORY!' : '😔  BETTER LUCK NEXT TIME',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          won
              ? '${state.displayName} wins the match!'
              : '$winnerName won the match',
          style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Rewards row ──────────────────────────────────────────────────────────────

class _RewardsRow extends StatelessWidget {
  final bool won;
  const _RewardsRow({required this.won});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: goldColor.withAlpha(60)),
      ),
      child: Row(
        children: [
          _RewardItem(
            emoji: '🏆',
            label: 'RATING',
            value: won ? '+12' : '−6',
            color: won ? boardGreen : boardRed,
          ),
          _Divider(),
          _RewardItem(
            emoji: '🪙',
            label: 'COINS',
            value: won ? '+100' : '+15',
            color: goldColor,
          ),
          _Divider(),
          _RewardItem(
            emoji: '⭐',
            label: 'XP',
            value: won ? '+150' : '+50',
            color: const Color(0xFF00E5FF),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: Colors.white12);
}

class _RewardItem extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _RewardItem({
    required this.emoji, required this.label,
    required this.value, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
            color: color, fontSize: 20, fontWeight: FontWeight.bold,
            shadows: [Shadow(color: color.withAlpha(120), blurRadius: 6)],
          )),
          Text(label, style: const TextStyle(
            color: Colors.white38,
            fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5,
          )),
        ],
      ),
    );
  }
}

// ── Player list ──────────────────────────────────────────────────────────────

class _PlayerList extends StatelessWidget {
  final GameSnapshot snapshot;
  final String? myId;
  const _PlayerList({required this.snapshot, required this.myId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: snapshot.seats.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;
        final isWinner = s.playerId == snapshot.winnerPlayerId;
        final isMe     = s.playerId == myId;
        final color    = AppColors.seatColor(s.seat);

        return Container(
          margin: EdgeInsets.only(bottom: i < snapshot.seats.length - 1 ? 6 : 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isWinner
                ? goldColor.withAlpha(20)
                : Colors.white.withAlpha(6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isWinner ? goldColor.withAlpha(80) : Colors.white12,
              width: isWinner ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Seat dot
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color.withAlpha(120), blurRadius: 4)],
                ),
              ),
              const SizedBox(width: 10),

              // Name
              Expanded(
                child: Text(
                  '${isMe ? "You" : s.displayName}${s.isBot ? " 🤖" : ""}',
                  style: TextStyle(
                    color: isWinner ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),

              // Badge
              if (isWinner)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: goldColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: goldColor.withAlpha(100)),
                  ),
                  child: const Text('★ Winner', style: TextStyle(
                    color: goldColor, fontSize: 10, fontWeight: FontWeight.bold,
                  )),
                )
              else
                const Text('—', style: TextStyle(color: Colors.white24, fontSize: 13)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Action button ────────────────────────────────────────────────────────────

class _ActionBtn extends StatefulWidget {
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.colors, required this.onTap});

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp:   (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.colors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: widget.colors.first.withAlpha(80),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(widget.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white, fontSize: 15,
              fontWeight: FontWeight.bold, letterSpacing: 0.3,
              shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
            )),
        ),
      ),
    );
  }
}

// ── Confetti painter ─────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter(this.t);

  static const _colors = [
    goldColor, boardRed, boardGreen, boardBlue, boardYellow,
    Color(0xFFE040FB), Color(0xFF00E5FF), Colors.white, Colors.pink,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (int i = 0; i < 80; i++) {
      final baseX = ((i * 137 + 11) % 1000) / 1000.0 * size.width;
      final speed = 60.0 + (i % 7) * 30.0;
      final y = (((i * 0.1) + t * (speed / size.height)) % 1.0) * (size.height + 30) - 15;
      final x = baseX + math.sin(t * 5 + i * 0.4) * 22;

      p.color = _colors[i % _colors.length].withAlpha(180 + (i % 3) * 25);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 4 + i * 0.6);

      // Alternate shapes
      if (i % 3 == 0) {
        // Square
        canvas.drawRect(Rect.fromLTWH(-4, -4, 8, 5), p);
      } else if (i % 3 == 1) {
        // Circle
        canvas.drawCircle(Offset.zero, 4, p);
      } else {
        // Diamond
        final path = Path()
          ..moveTo(0, -5)
          ..lineTo(4, 0)
          ..lineTo(0, 5)
          ..lineTo(-4, 0)
          ..close();
        canvas.drawPath(path, p);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

// ── Result background glow ───────────────────────────────────────────────────

class _ResultGlowPainter extends CustomPainter {
  final double t;
  final bool won;
  _ResultGlowPainter(this.t, this.won);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    final pulse = 0.5 + 0.5 * math.sin(t * math.pi * 2);

    // Top glow
    p.shader = ui.Gradient.radial(
      Offset(size.width * 0.5, 0),
      size.width * 0.6,
      [
        (won ? goldColor : Colors.white).withAlpha((pulse * 25).round()),
        Colors.transparent,
      ],
    );
    canvas.drawRect(Offset.zero & size, p);

    // Bottom glow
    p.shader = ui.Gradient.radial(
      Offset(size.width * 0.5, size.height),
      size.width * 0.5,
      [
        (won ? const Color(0xFFFF6B35) : Colors.blue).withAlpha((pulse * 20).round()),
        Colors.transparent,
      ],
    );
    canvas.drawRect(Offset.zero & size, p);
    p.shader = null;
  }

  @override
  bool shouldRepaint(_ResultGlowPainter old) => old.t != t;
}
