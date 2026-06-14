import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/game_snapshot.dart';
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
  int  _prevDiceValue = 0;
  bool _rolling = false;

  late final AnimationController _bgCtrl;
  late final AnimationController _turnPulse;

  @override
  void initState() {
    super.initState();
    _bgCtrl    = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _turnPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
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

        final mySeat     = state.mySeat;
        final myTurn     = snapshot?.currentTurnSeat == mySeat;
        final canRoll    = myTurn && (snapshot?.diceValue ?? 0) == 0 && !_rolling;
        final legalCount = snapshot?.availableMoves.length ?? 0;
        final seatColor  = mySeat != null ? AppColors.seatColor(mySeat) : goldColor;

        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: const Color(0xFF08001A),
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
                  child: Column(
                    children: [
                      // Top bar — opponents
                      _GameTopBar(
                        state: state,
                        snapshot: snapshot,
                        mySeat: mySeat,
                        onMenu: () => _showResignDialog(context, state),
                      ),

                      // Board — wrapped in AspectRatio to fix zero-size rendering bug
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: LudoBoard(
                                snapshot: snapshot,
                                mySeat: mySeat,
                                onPieceTap: (id) => state.movePiece(id),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // My turn indicator
                      if (myTurn)
                        AnimatedBuilder(
                          animation: _turnPulse,
                          builder: (_, __) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: seatColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: seatColor.withAlpha(
                                    (120 + _turnPulse.value * 80).round()),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: seatColor.withAlpha(
                                      (_turnPulse.value * 60).round()),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_upward_rounded,
                                    color: seatColor, size: 14),
                                const SizedBox(width: 6),
                                Text('YOUR TURN', style: TextStyle(
                                  color: seatColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                )),
                              ],
                            ),
                          ),
                        ),

                      // Player row — dice + actions
                      _PlayerActionRow(
                        state:      state,
                        snapshot:   snapshot,
                        mySeat:     mySeat,
                        diceKey:    _diceKey,
                        canRoll:    canRoll,
                        legalCount: legalCount,
                        rolling:    _rolling,
                        turnPulse:  _turnPulse,
                      ),

                      const SizedBox(height: 8),
                    ],
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
        backgroundColor: const Color(0xFF1A0040),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x55E040FB)),
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

    // Deep base
    p.shader = ui.Gradient.radial(
      Offset(size.width * 0.5, size.height * 0.4),
      size.height * 0.7,
      [const Color(0xFF160040), const Color(0xFF08001A)],
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
      [const Color(0x0E00E5FF), Colors.transparent],
    );
    canvas.drawRect(Offset.zero & size, p);
    p.shader = null;

    // Dim stars
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
    required this.state, required this.snapshot,
    required this.mySeat, required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final opponents  = snapshot?.seats.where((s) => s.seat != mySeat).toList() ?? [];
    final activeSeat = snapshot?.currentTurnSeat;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xBB1A0040),
        border: Border(bottom: BorderSide(color: Color(0x33FFD426))),
      ),
      child: Row(
        children: [
          // Menu / resign button
          GestureDetector(
            onTap: onMenu,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.menu_rounded, color: Colors.white60, size: 18),
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
            final color  = AppColors.seatColor(s.seat);
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
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: active
                        ? [BoxShadow(color: color.withAlpha(150), blurRadius: 6)]
                        : null,
                  ),
                  child: Center(child: Text(
                    s.displayName.isNotEmpty
                        ? s.displayName[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold,
                    ),
                  )),
                ),
                const SizedBox(width: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.displayName,
                      style: const TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (active)
                      const Text('▶ TURN',
                        style: TextStyle(
                          color: goldColor, fontSize: 8,
                          fontWeight: FontWeight.bold, letterSpacing: 0.5,
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
    required this.state, required this.snapshot, required this.mySeat,
    required this.diceKey, required this.canRoll, required this.legalCount,
    required this.rolling, required this.turnPulse,
  });

  @override
  Widget build(BuildContext context) {
    final seat      = mySeat ?? 0;
    final seatColor = AppColors.seatColor(seat);
    final isMyTurn  = snapshot?.currentTurnSeat == mySeat;
    final hasDice   = (snapshot?.diceValue ?? 0) > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xBB1A0040),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isMyTurn ? seatColor.withAlpha(180) : Colors.white12,
          width: isMyTurn ? 1.5 : 1,
        ),
        boxShadow: isMyTurn
            ? [BoxShadow(color: seatColor.withAlpha(40), blurRadius: 16)]
            : null,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: seatColor,
              border: Border.all(color: Colors.white54, width: 1.5),
              boxShadow: [BoxShadow(color: seatColor.withAlpha(130), blurRadius: 8)],
            ),
            child: Center(child: Text(
              state.displayName.isNotEmpty
                  ? state.displayName[0].toUpperCase() : 'Y',
              style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold,
              ),
            )),
          ),
          const SizedBox(width: 8),

          // Player name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('You', style: TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold,
                )),
                Text(
                  isMyTurn
                      ? (hasDice ? 'Move a piece!' : 'Roll the dice!')
                      : 'Waiting for turn...',
                  style: TextStyle(
                    color: isMyTurn ? seatColor : Colors.white38,
                    fontSize: 10, fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Dice widget
          GestureDetector(
            onTap: canRoll ? state.rollDice : null,
            child: SizedBox(
              width: 60, height: 60,
              child: DiceWidget(key: diceKey),
            ),
          ),

          const SizedBox(width: 8),

          // Action button (Roll / Move / Wait)
          AnimatedBuilder(
            animation: turnPulse,
            builder: (_, __) {
              final showMove = hasDice && legalCount > 0 && isMyTurn && !rolling;
              final showRoll = canRoll;
              final active   = showMove || showRoll;

              if (!active) {
                return Container(
                  width: 68,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_top_rounded,
                          color: Colors.white24, size: 18),
                      SizedBox(height: 3),
                      Text('Wait',
                        style: TextStyle(color: Colors.white24, fontSize: 10)),
                    ],
                  ),
                );
              }

              final glow    = 0.4 + 0.6 * turnPulse.value;
              final btnColor = showMove ? boardGreen : seatColor;
              return GestureDetector(
                onTap: showMove
                    ? state.moveBestPiece
                    : (showRoll ? state.rollDice : null),
                child: Container(
                  width: 68,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: showMove
                          ? [const Color(0xFF43A047), const Color(0xFF2E7D32)]
                          : [seatColor, seatColor.withAlpha(180)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: btnColor.withAlpha((glow * 200).round()),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: btnColor.withAlpha((glow * 90).round()),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        showMove
                            ? Icons.touch_app_rounded
                            : Icons.casino_rounded,
                        color: Colors.white, size: 20,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        showMove ? 'Move' : 'Roll',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11, fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
