import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/game_snapshot.dart';
import '../theme/app_theme.dart';
import '../widgets/ludo_board.dart';
import '../widgets/dice_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _diceKey = GlobalKey<DiceWidgetState>();
  int _prevDiceValue = 0;
  bool _rolling = false;

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

        final mySeat    = state.mySeat;
        final myTurn    = snapshot?.currentTurnSeat == mySeat;
        final canRoll   = myTurn && (snapshot?.diceValue ?? 0) == 0 && !_rolling;
        final legalCount = snapshot?.availableMoves.length ?? 0;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _showLeaveDialog(context, state);
          },
          child: Scaffold(
            backgroundColor: bgDeep,
            body: SafeArea(
              child: Column(
                children: [
                  // ── Top bar (opponent) ──────────────────────────────
                  _TopBar(state: state, snapshot: snapshot, mySeat: mySeat),

                  // ── Board ───────────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: LudoBoard(
                        snapshot: snapshot,
                        mySeat: mySeat,
                        onPieceTap: (pieceId) => state.movePiece(pieceId),
                      ),
                    ),
                  ),

                  // ── Turn indicator arrow ────────────────────────────
                  if (myTurn)
                    _TurnArrow(seat: mySeat ?? 0),

                  // ── Player dice row ─────────────────────────────────
                  _PlayerRow(
                    state:      state,
                    snapshot:   snapshot,
                    mySeat:     mySeat,
                    diceKey:    _diceKey,
                    canRoll:    canRoll,
                    legalCount: legalCount,
                    rolling:    _rolling,
                  ),

                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLeaveDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgPurple,
        title: const Text('Leave Match?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Leaving counts as a resignation and you lose rating.',
          style: TextStyle(color: Colors.white70)),
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
            child: const Text('Leave', style: TextStyle(color: boardRed)),
          ),
        ],
      ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final AppState state;
  final GameSnapshot? snapshot;
  final int? mySeat;
  const _TopBar({required this.state, required this.snapshot, required this.mySeat});

  @override
  Widget build(BuildContext context) {
    final opponents = snapshot?.seats
        .where((s) => s.seat != mySeat)
        .toList() ?? [];
    final activeSeat = snapshot?.currentTurnSeat;

    return Container(
      color: const Color(0xFF1E002E),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          // Hamburger
          GestureDetector(
            onTap: () => _showResignDialog(context, state),
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: bgPurple,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.menu, color: Colors.white70, size: 18),
            ),
          ),
          const SizedBox(width: 6),

          // Status / title
          Expanded(
            child: Text(
              state.statusText.isNotEmpty ? state.statusText : 'LIVE MATCH',
              style: const TextStyle(
                color: goldColor, fontSize: 13, fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Opponents
          ...opponents.take(2).map((s) {
            final active = s.seat == activeSeat;
            final color  = AppColors.seatColor(s.seat);
            return Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: active ? color.withAlpha(50) : bgPurple,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? color : Colors.white24),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(color: goldColor, width: active ? 2 : 0),
                  ),
                  child: Center(
                    child: Text(
                      s.displayName.isNotEmpty ? s.displayName[0].toUpperCase() : 'P',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.displayName,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (active)
                      const Text('▶ TURN',
                        style: TextStyle(color: goldColor, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }

  void _showResignDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgPurple,
        title: const Text('Resign?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('This counts as a loss.',
          style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: goldColor)),
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

// ── Turn arrow ─────────────────────────────────────────────────────────────────

class _TurnArrow extends StatelessWidget {
  final int seat;
  const _TurnArrow({required this.seat});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.seatColor(seat);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Icon(Icons.arrow_drop_up, color: color, size: 28),
    );
  }
}

// ── Player dice row ────────────────────────────────────────────────────────────

class _PlayerRow extends StatelessWidget {
  final AppState state;
  final GameSnapshot? snapshot;
  final int? mySeat;
  final GlobalKey<DiceWidgetState> diceKey;
  final bool canRoll;
  final int legalCount;
  final bool rolling;

  const _PlayerRow({
    required this.state,
    required this.snapshot,
    required this.mySeat,
    required this.diceKey,
    required this.canRoll,
    required this.legalCount,
    required this.rolling,
  });

  @override
  Widget build(BuildContext context) {
    final seat  = mySeat ?? 0;
    final color = AppColors.seatColor(seat);
    final isMyTurn = snapshot?.currentTurnSeat == mySeat;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E002E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMyTurn ? color.withAlpha(180) : Colors.white12,
          width: isMyTurn ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Player avatar
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: goldColor, width: isMyTurn ? 2 : 0),
            ),
            child: Center(
              child: Text(
                state.displayName.isNotEmpty ? state.displayName[0].toUpperCase() : 'Y',
                style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Name
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(state.displayName,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(isMyTurn ? '▶ YOUR TURN' : 'Waiting...',
                style: TextStyle(
                  color: isMyTurn ? color : Colors.white38,
                  fontSize: 10, fontWeight: FontWeight.bold,
                )),
            ],
          ),

          const Spacer(),

          // Auto move button
          if (legalCount > 0 && !rolling)
            GestureDetector(
              onTap: state.moveBestPiece,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: blueBtn.withAlpha(200),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Auto', style: TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold,
                )),
              ),
            ),

          // Green circle roll button
          GestureDetector(
            onTap: canRoll ? state.rollDice : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: canRoll
                      ? [const Color(0xFF81C784), greenBtn]
                      : [Colors.grey.shade700, Colors.grey.shade900],
                  center: const Alignment(-0.3, -0.3),
                ),
                boxShadow: canRoll ? [
                  BoxShadow(color: greenBtn.withAlpha(160), blurRadius: 14, spreadRadius: 2),
                ] : [],
                border: Border.all(
                  color: canRoll ? const Color(0xFFA5D6A7) : Colors.white12, width: 2.5,
                ),
              ),
              child: Center(
                child: rolling
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('🎲', style: TextStyle(fontSize: 26)),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Small dice display
          SizedBox(
            width: 48, height: 48,
            child: DiceWidget(key: diceKey, size: 48),
          ),
        ],
      ),
    );
  }
}
