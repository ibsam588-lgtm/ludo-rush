import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game_snapshot.dart';
import 'dice_widget.dart';
import 'ludo_board.dart';
import 'snakes_ladders_board.dart';

/// Uses the same board renderer as a match, with isolated demonstration state.
class LiveBoardPreview extends StatefulWidget {
  final String theme;
  final bool snakes;
  final bool live;
  const LiveBoardPreview(
      {super.key, required this.theme, this.snakes = false, this.live = true});
  @override
  State<LiveBoardPreview> createState() => _LiveBoardPreviewState();
}

class _LiveBoardPreviewState extends State<LiveBoardPreview> {
  Timer? _timer;
  int _step = 0;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      // Supported by the app's older Flutter release builders too.
      if (mounted &&
          widget.live &&
          // ignore: deprecated_member_use
          TickerMode.of(context) &&
          !MediaQuery.disableAnimationsOf(context)) setState(() => _step++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snakes = widget.snakes;
    final progress =
        snakes ? [1, 4, 26, 30, 37, 42, 13, 18][_step % 8] : (_step * 3) % 45;
    final snapshot = GameSnapshot(
      seats: [
        for (var i = 0; i < 4; i++)
          SeatState(
              seat: i,
              playerId: 'preview_$i',
              displayName: 'Preview',
              isBot: true)
      ],
      pieces: [
        for (var seat = 0; seat < 4; seat++)
          for (var token = 0; token < (snakes ? 1 : 4); token++)
            PieceState(
                pieceId: 's${seat}_p$token',
                seat: seat,
                state: token == 0 ? 'track' : 'yard',
                progress: token == 0
                    ? (snakes
                        ? (seat == 0 ? progress : [1, 23, 64, 79][seat])
                        : progress)
                    : -1,
                trackIndex: token == 0
                    ? (snakes
                        ? (seat == 0 ? progress : [1, 23, 64, 79][seat])
                        : (1 + seat * 13 + progress) % 52)
                    : -1)
      ],
      diceValue: 0,
      currentTurnSeat: 0,
      status: 'playing',
      availableMoves: const [],
      winnerPlayerId: '',
      mode: snakes ? 'snakes_ladders' : 'classic_4p',
    );
    return IgnorePointer(
        child: Stack(children: [
      Positioned.fill(
          child: snakes
              ? SnakesLaddersBoard(
                  snapshot: snapshot,
                  animate: widget.live,
                  mySeat: 0,
                  boardTheme: widget.theme,
                  onPieceTap: (_) {})
              : LudoBoard(
                  snapshot: snapshot,
                  animate: widget.live,
                  mySeat: 0,
                  boardTheme: widget.theme,
                  onPieceTap: (_) {},
                  showWaitingOverlay: false)),
      if (widget.live)
        Positioned(
            right: 8,
            bottom: 8,
            child: DiceWidget(
                key: ValueKey(_step), value: _step % 6 + 1, size: 30)),
    ]));
  }
}
