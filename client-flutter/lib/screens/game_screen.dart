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

        // Detect new dice roll and trigger animation
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

        final mySeat  = state.mySeat;
        final myTurn  = snapshot?.currentTurnSeat == mySeat;
        final canRoll = myTurn && (snapshot?.diceValue ?? 0) == 0 && !_rolling;
        final legalCount = snapshot?.availableMoves.length ?? 0;

        return WillPopScope(
          onWillPop: () async {
            _showLeaveDialog(context, state);
            return false;
          },
          child: Scaffold(
            backgroundColor: context.bgPage,
            body: SafeArea(
              child: Column(
                children: [
                  _Header(state: state, onResign: () => _showResignDialog(context, state)),
                  _OpponentStrip(snapshot: snapshot, mySeat: mySeat),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: LudoBoard(
                        snapshot: snapshot,
                        mySeat: mySeat,
                        onPieceTapped: (pieceId) => state.movePiece(pieceId),
                      ),
                    ),
                  ),
                  _MyRow(
                    state: state,
                    snapshot: snapshot,
                    mySeat: mySeat,
                    legalCount: legalCount,
                    diceKey: _diceKey,
                  ),
                  _StatusBar(statusText: state.statusText),
                  _ActionButtons(
                    canRoll: canRoll,
                    hasLegal: legalCount > 0 && !_rolling,
                    onRoll: () => state.rollDice(),
                    onAuto: () => state.moveBestPiece(),
                  ),
                  const SizedBox(height: 8),
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
        backgroundColor: context.bgCard,
        title: Text('Leave Match?', style: TextStyle(color: context.txtPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'You will forfeit the match and lose rating points.',
          style: TextStyle(color: context.txtMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay', style: TextStyle(color: AppColors.gold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              state.resign();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('Leave', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  void _showResignDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.bgCard,
        title: Text('Resign?', style: TextStyle(color: context.txtPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Resigning will end the match immediately and you will lose rating.',
          style: TextStyle(color: context.txtMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.gold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              state.resign();
            },
            child: const Text('Resign', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AppState state;
  final VoidCallback onResign;
  const _Header({required this.state, required this.onResign});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: context.bgHeader,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: context.bgCard,
                  title: Text('Leave Match?',
                    style: TextStyle(color: context.txtPrimary, fontWeight: FontWeight.bold)),
                  content: Text('You will forfeit the match.',
                    style: TextStyle(color: context.txtMuted)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Stay', style: TextStyle(color: AppColors.gold)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        state.resign();
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      },
                      child: const Text('Leave', style: TextStyle(color: AppColors.red)),
                    ),
                  ],
                ),
              );
            },
            child: const Icon(Icons.arrow_back_ios, color: AppColors.gold, size: 20),
          ),
          const Expanded(
            child: Text('LIVE MATCH', textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.2)),
          ),
          GestureDetector(
            onTap: onResign,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.red.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.red.withAlpha(100)),
              ),
              child: const Text('Resign', style: TextStyle(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpponentStrip extends StatelessWidget {
  final GameSnapshot? snapshot;
  final int? mySeat;
  const _OpponentStrip({required this.snapshot, required this.mySeat});

  @override
  Widget build(BuildContext context) {
    if (snapshot == null) return const SizedBox(height: 48);
    final opponents = snapshot!.seats.where((s) => s.seat != mySeat).toList();
    if (opponents.isEmpty) return const SizedBox(height: 48);

    return Container(
      height: 52,
      color: context.bgHeader,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: opponents.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = opponents[i];
          final isActive = snapshot!.currentTurnSeat == s.seat;
          final color = AppColors.seatColors[s.seat.clamp(0, 3)];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? color.withAlpha(40) : context.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isActive ? color : context.strokeCard),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(s.displayName, style: TextStyle(color: context.txtPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                if (isActive) ...[
                  const SizedBox(width: 6),
                  Text('▶ TURN', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MyRow extends StatelessWidget {
  final AppState state;
  final GameSnapshot? snapshot;
  final int? mySeat;
  final int legalCount;
  final GlobalKey<DiceWidgetState> diceKey;
  const _MyRow({
    required this.state, required this.snapshot, required this.mySeat,
    required this.legalCount, required this.diceKey,
  });

  @override
  Widget build(BuildContext context) {
    final seat = mySeat ?? 0;
    final color = AppColors.seatColors[seat.clamp(0, 3)];
    final isMyTurn = snapshot?.currentTurnSeat == mySeat;
    final dv = snapshot?.diceValue ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: context.bgHeader,
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.displayName, style: TextStyle(color: context.txtPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                if (isMyTurn && legalCount > 0)
                  Text('$legalCount move${legalCount == 1 ? "" : "s"} available',
                    style: const TextStyle(color: AppColors.green, fontSize: 11)),
              ],
            ),
          ),
          if (isMyTurn)
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
              margin: const EdgeInsets.only(right: 8),
            ),
          SizedBox(
            width: 44, height: 44,
            child: DiceWidget(key: diceKey),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final String statusText;
  const _StatusBar({required this.statusText});

  @override
  Widget build(BuildContext context) {
    if (statusText.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      color: context.bgPage,
      child: Text(statusText,
        textAlign: TextAlign.center,
        style: TextStyle(color: context.txtMuted, fontSize: 12)),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final bool canRoll;
  final bool hasLegal;
  final VoidCallback onRoll;
  final VoidCallback onAuto;
  const _ActionButtons({
    required this.canRoll, required this.hasLegal,
    required this.onRoll, required this.onAuto,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _GradBtn(
              label: '🎲  Roll Dice',
              enabled: canRoll,
              colors: canRoll
                  ? [const Color(0xffE53935), const Color(0xff880E4F)]
                  : [const Color(0xff444444), const Color(0xff333333)],
              onTap: canRoll ? onRoll : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _GradBtn(
              label: '⚡  Auto Move',
              enabled: hasLegal,
              colors: hasLegal
                  ? [AppColors.navy, const Color(0xff1565C0)]
                  : [const Color(0xff333333), const Color(0xff222222)],
              onTap: hasLegal ? onAuto : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradBtn extends StatelessWidget {
  final String label;
  final bool enabled;
  final List<Color> colors;
  final VoidCallback? onTap;
  const _GradBtn({required this.label, required this.enabled, required this.colors, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ),
    );
  }
}
