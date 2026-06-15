import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/game_snapshot.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ludo_board.dart';
import '../widgets/dice_widget.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  GAME SCREEN — Live match view with fixed board sizing
// ═══════════════════════════════════════════════════════════════════════════════

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final _diceKey = GlobalKey<DiceWidgetState>();
  int _prevDiceValue = 0;
  bool _rolling = false;

  late final AnimationController _bgCtrl;
  late final AnimationController _turnPulse;

  @override
  void initState() {
    super.initState();
    _bgCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat(reverse: true);
    _turnPulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _turnPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final snapshot = state.lastSnapshot;

        if (snapshot != null) {
          final dv = snapshot.diceValue;
          if (dv > 0 && dv != _prevDiceValue) {
            _prevDiceValue = dv;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_rolling) {
                _rolling = true;
                _diceKey.currentState?.startRoll(dv, () {
                  if (mounted) setState(() => _rolling = false);
                });
              }
            });
          }
        }

        final mySeat = state.mySeat;
        final myTurn = snapshot?.currentTurnSeat == mySeat;
        final canRoll = myTurn && (snapshot?.diceValue ?? 0) == 0 && !_rolling;
        final legalCount = snapshot?.availableMoves.length ?? 0;
        final seatColor =
            mySeat != null ? AppColors.seatColor(mySeat) : goldColor;

        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: const Color(0xFF1A0520),
            body: Stack(
              children: [
                // ── Animated background ──────────────────────
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _bgCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _GameBgPainter(_bgCtrl.value, seatColor),
                    ),
                  ),
                ),

                // ── UI ────────────────────────────────────────
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final boardSize = math.min(
                        constraints.maxWidth - 16,
                        constraints.maxHeight * 0.55,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Top bar — opponents
                          _GameTopBar(
                            state: state,
                            snapshot: snapshot,
                            mySeat: mySeat,
                            onMenu: () => _showResignDialog(context, state),
                          ),

                          // Board — wrapped in AspectRatio to fix zero-size rendering bug
                          SizedBox(
                            width: boardSize,
                            height: boardSize,
                            child: LudoBoard(
                              snapshot: snapshot,
                              mySeat: mySeat,
                              onPieceTap: (id) => state.movePiece(id),
                            ),
                          ),
                          const SizedBox(height: 18),

                          if (myTurn)
                            _TurnPointer(color: seatColor, pulse: _turnPulse),

                          // Player row — dice + actions
                          _PlayerActionRow(
                            state: state,
                            snapshot: snapshot,
                            mySeat: mySeat,
                            diceKey: _diceKey,
                            canRoll: canRoll,
                            legalCount: legalCount,
                            rolling: _rolling,
                            turnPulse: _turnPulse,
                          ),

                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showResignDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D0A35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x55FFD426)),
        ),
        title: const Text('Resign Match?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('This counts as a loss and reduces your rating.',
            style: TextStyle(color: Colors.white60)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay', style: TextStyle(color: goldColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              state.resign();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('Resign', style: TextStyle(color: boardRed)),
          ),
        ],
      ),
    );
  }
}

// ── Game background ──────────────────────────────────────────────────────────

class _GameBgPainter extends CustomPainter {
  final double t;
  final Color seatColor;
  _GameBgPainter(this.t, this.seatColor);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;

    // Warm deep base
    p.shader = ui.Gradient.radial(
      Offset(size.width * 0.5, size.height * 0.4),
      size.height * 0.7,
      [const Color(0xFF2D0A3A), const Color(0xFF1A0520)],
    );
    canvas.drawRect(Offset.zero & size, p);

    // Seat-color glow at bottom (player zone)
    p.shader = ui.Gradient.radial(
      Offset(size.width * 0.5, size.height),
      size.width * 0.6,
      [seatColor.withAlpha(30), Colors.transparent],
    );
    canvas.drawRect(Offset.zero & size, p);
    p.shader = null;

    // Moving accent orb
    final ax = size.width * (0.5 + 0.3 * math.sin(t * math.pi * 2));
    final ay = size.height * 0.15;
    p.shader = ui.Gradient.radial(
      Offset(ax, ay),
      size.width * 0.4,
      [const Color(0x10FF9A00), Colors.transparent],
    );
    canvas.drawRect(Offset.zero & size, p);
    p.shader = null;

    // Dim warm stars
    for (int i = 0; i < 40; i++) {
      final sx = ((i * 137 + 41) % 1000) / 1000.0 * size.width;
      final sy = ((i * 211 + 17) % 1000) / 1000.0 * size.height;
      p.color = Colors.white.withAlpha(20 + (i % 4) * 8);
      canvas.drawCircle(Offset(sx, sy), 0.8, p);
    }
  }

  @override
  bool shouldRepaint(_GameBgPainter old) => old.t != t;
}

// ── Game top bar ─────────────────────────────────────────────────────────────

class _GameTopBar extends StatelessWidget {
  final AppState state;
  final GameSnapshot? snapshot;
  final int? mySeat;
  final VoidCallback onMenu;
  const _GameTopBar({
    required this.state,
    required this.snapshot,
    required this.mySeat,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final opponents =
        snapshot?.seats.where((s) => s.seat != mySeat).toList() ?? [];
    final activeSeat = snapshot?.currentTurnSeat;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xBB2D0A35),
        border: Border(bottom: BorderSide(color: Color(0x33FFD426))),
      ),
      child: Row(
        children: [
          // Menu / resign button
          GestureDetector(
            onTap: onMenu,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.menu_rounded,
                  color: Colors.white60, size: 18),
            ),
          ),
          const SizedBox(width: 8),

          // Status text
          Expanded(
            child: Text(
              state.statusText.isNotEmpty ? state.statusText : 'LIVE MATCH',
              style: const TextStyle(
                color: goldColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Opponent chips
          ...opponents.take(3).map((s) {
            final active = s.seat == activeSeat;
            final color = AppColors.seatColor(s.seat);
            final publicName = state.publicSeatName(s);
            return Container(
              margin: const EdgeInsets.only(left: 5),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: active ? color.withAlpha(40) : Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? color.withAlpha(200) : Colors.white24,
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: active
                        ? [
                            BoxShadow(
                                color: color.withAlpha(150), blurRadius: 6)
                          ]
                        : null,
                  ),
                  child: Center(
                      child: Text(
                    publicName.isNotEmpty ? publicName[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
                ),
                const SizedBox(width: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(publicName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (active)
                      const Text('TURN',
                          style: TextStyle(
                            color: goldColor,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          )),
                  ],
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }
}

// ── Player action row ────────────────────────────────────────────────────────

class _PlayerActionRow extends StatelessWidget {
  final AppState state;
  final GameSnapshot? snapshot;
  final int? mySeat;
  final GlobalKey<DiceWidgetState> diceKey;
  final bool canRoll;
  final int legalCount;
  final bool rolling;
  final AnimationController turnPulse;

  const _PlayerActionRow({
    required this.state,
    required this.snapshot,
    required this.mySeat,
    required this.diceKey,
    required this.canRoll,
    required this.legalCount,
    required this.rolling,
    required this.turnPulse,
  });

  @override
  Widget build(BuildContext context) {
    final seat = mySeat ?? 0;
    final seatColor = AppColors.seatColor(seat);
    final isMyTurn = snapshot?.currentTurnSeat == mySeat;
    final hasDice = (snapshot?.diceValue ?? 0) > 0;
    final showMove = hasDice && legalCount > 0 && isMyTurn && !rolling;
    final enabled = canRoll || showMove;
    final playerName = state.displayName.trim().isEmpty
        ? 'You'
        : (state.displayName == 'Ludo Player' ? 'Ibsam' : state.displayName);

    return Container(
      width: double.infinity,
      height: 136,
      margin: const EdgeInsets.fromLTRB(8, 2, 8, 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 14,
            top: -3,
            child: Text(
              playerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 31,
            child: _PlayerTimerBadge(
              color: seatColor,
              active: isMyTurn,
              pulse: turnPulse,
              label: playerName.isNotEmpty ? playerName[0].toUpperCase() : 'Y',
            ),
          ),
          Positioned(
            left: 96,
            top: 24,
            child: _DiceActionButton(
              diceKey: diceKey,
              enabled: enabled,
              moving: showMove,
              color: showMove ? boardGreen : seatColor,
              pulse: turnPulse,
              onTap: showMove
                  ? state.moveBestPiece
                  : (canRoll ? state.rollDice : null),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 9,
            child: _ActionPill(
              label: 'EMOJI',
              icon: Icons.mood_rounded,
              onTap: () => _comingSoon(context, 'Emoji'),
            ),
          ),
          Positioned(
            left: 98,
            bottom: 9,
            child: _ActionPill(
              label: 'CHAT',
              icon: Icons.chat_bubble_rounded,
              onTap: () => _comingSoon(context, 'Chat'),
            ),
          ),
        ],
      ),
    );
  }

  static void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label coming soon.')));
  }
}

class _TurnPointer extends StatelessWidget {
  final Color color;
  final AnimationController pulse;

  const _TurnPointer({required this.color, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, 4 * pulse.value),
          child: Icon(
            Icons.arrow_downward_rounded,
            color: color.withAlpha((150 + pulse.value * 90).round()),
            size: 42,
            shadows: [Shadow(color: color.withAlpha(120), blurRadius: 10)],
          ),
        ),
      ),
    );
  }
}

class _PlayerTimerBadge extends StatelessWidget {
  final Color color;
  final bool active;
  final AnimationController pulse;
  final String label;

  const _PlayerTimerBadge({
    required this.color,
    required this.active,
    required this.pulse,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final glow = active ? (0.5 + pulse.value * 0.5) : 0.0;
        return Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                color,
                color.withAlpha(70),
                Colors.white.withAlpha(210),
                color,
              ],
              stops: const [0.0, 0.58, 0.62, 1.0],
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: color.withAlpha((90 * glow).round()),
                        blurRadius: 14)
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.white70, width: 2),
              ),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DiceActionButton extends StatelessWidget {
  final GlobalKey<DiceWidgetState> diceKey;
  final bool enabled;
  final bool moving;
  final Color color;
  final AnimationController pulse;
  final VoidCallback? onTap;

  const _DiceActionButton({
    required this.diceKey,
    required this.enabled,
    required this.moving,
    required this.color,
    required this.pulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final glow = enabled ? (0.45 + pulse.value * 0.55) : 0.0;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: enabled
                    ? [
                        color.withAlpha(240),
                        Color.lerp(color, Colors.black, 0.22)!
                      ]
                    : const [Color(0xFFD9E2E8), Color(0xFFB7C1CC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: enabled ? const Color(0xFFFFF0A0) : Colors.white,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(120),
                    blurRadius: 7,
                    offset: const Offset(0, 4)),
                if (enabled)
                  BoxShadow(
                      color: color.withAlpha((120 * glow).round()),
                      blurRadius: 16)
              ],
            ),
            child: moving
                ? const Icon(Icons.touch_app_rounded,
                    color: Colors.white, size: 31)
                : Center(child: DiceWidget(key: diceKey, size: 54)),
          ),
        );
      },
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionPill({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        SoundService.tap();
        onTap();
      },
      child: Container(
        width: 74,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF8C7A91), Color(0xFF5A4A61)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 3))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
