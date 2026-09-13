import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/game_snapshot.dart';
import '../services/levelplay_ad_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ludo_board.dart';
import '../widgets/snakes_ladders_board.dart';
import '../widgets/dice_widget.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/six_celebration.dart';
import '../data/table_reactions.dart';
import '../widgets/match_style.dart';
import '../models/match_moment.dart';

String _shortNumber(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 10000) return '${(value / 1000).toStringAsFixed(1)}K';
  return value.toString();
}

// -----------------------------------------------------------------------------
// GAME SCREEN - Live match view with fixed board sizing
// -----------------------------------------------------------------------------

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final _diceKey = GlobalKey<DiceWidgetState>();
  int _prevRollSequence = 0;
  bool _rolling = false;
  bool _piecesMoving = false;
  final _boardScroll = ScrollController();
  String? _positionedBoardMode;
  GameSnapshot? _seenSnapshot;
  MatchMoment? _moment;
  int _avatarSequence = 0;
  Timer? _momentTimer;

  void _showMoment(MatchMoment moment) {
    _momentTimer?.cancel();
    setState(() {
      _moment = moment;
      _avatarSequence++;
    });
    _momentTimer = Timer(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => _moment = null);
    });
  }

  void _onMotionChanged(bool moving) {
    if (mounted && _piecesMoving != moving)
      setState(() => _piecesMoving = moving);
  }

  int _sixSequence = 0;
  bool _quitDialogOpen = false;
  bool _quitting = false;
  Timer? _quickBubbleTimer;
  String? _quickBubbleText;
  bool _quickBubbleIsEmoji = false;
  int _prevReactionSequence = 0;
  Timer? _clockTimer;
  int? _followedSnakeProgress;
  int _lastWarnedDeadline = 0;
  bool _tutorialScheduled = false;

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
    _clockTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      final state = context.read<AppState>();
      state.expireLocalTurnIfNeeded();
      final snap = state.lastSnapshot;
      if (snap?.status != 'playing') return;
      final left = snap!.turnDeadlineAt - DateTime.now().millisecondsSinceEpoch;
      if (left > 0 &&
          left <= 5000 &&
          _lastWarnedDeadline != snap.turnDeadlineAt) {
        _lastWarnedDeadline = snap.turnDeadlineAt;
        if (snap.currentTurnSeat == state.mySeat) {
          SoundService.warning();
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _quickBubbleTimer?.cancel();
    _momentTimer?.cancel();
    _boardScroll.dispose();
    _clockTimer?.cancel();
    _bgCtrl.dispose();
    _turnPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final snapshot = state.lastSnapshot;
        final palette = MatchPalette.forTheme(
            snapshot?.mode == AppState.snakesLaddersMode
                ? state.snakesBoardTheme
                : state.ludoBoardTheme);
        final reduced = MediaQuery.disableAnimationsOf(context);
        if (!identical(snapshot, _seenSnapshot)) {
          final moment = snapshot == null
              ? null
              : MatchMoment.between(_seenSnapshot, snapshot);
          _seenSnapshot = snapshot;
          if (moment != null)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _showMoment(moment);
            });
        }

        if (snapshot != null) {
          final rollSequence = state.lastRollSequence;
          final rollValue = state.lastRollValue;
          final rollerId = state.lastRollPlayerId;
          if (rollSequence != _prevRollSequence && rollValue > 0) {
            _prevRollSequence = rollSequence;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final dice = _diceKey.currentState;
              if (dice == null) return;
              setState(() => _rolling = true);
              dice.startRoll(rollValue, () {
                if (!mounted) return;
                setState(() {
                  _rolling = false;
                  if (rollValue == 6) _sixSequence++;
                });
                if (rollValue == 6) {
                  final roller =
                      snapshot.seats.where((s) => s.playerId == rollerId);
                  if (roller.isNotEmpty)
                    _showMoment(MatchMoment(
                        roller.first.seat, AvatarMood.lucky, 'Lucky six!'));
                }
              });
            });
          }
          final reactionSequence = state.reactionSequence;
          if (reactionSequence != _prevReactionSequence &&
              state.lastReactionText != null &&
              state.lastReactionPlayerId != state.playerId) {
            _prevReactionSequence = reactionSequence;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showQuickBubble(
                  state.lastReactionText!,
                  isEmoji: state.lastReactionIsEmoji,
                );
              }
            });
          }
        }

        final mySeat = state.mySeat;
        final myTurn = snapshot?.currentTurnSeat == mySeat;
        final canRoll = snapshot?.status == 'playing' &&
            myTurn &&
            (snapshot?.diceValue ?? 0) == 0 &&
            !_rolling &&
            !_piecesMoving;
        final legalCount = snapshot?.availableMoves.length ?? 0;
        final seatColor =
            mySeat != null ? AppColors.seatColor(mySeat) : goldColor;
        final snakesTable = snapshot?.mode == AppState.snakesLaddersMode;
        if (snapshot?.status == 'playing' &&
            !state.gameTutorialSeen &&
            !_tutorialScheduled) {
          _tutorialScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showFirstMatchGuide(context, state, snakesTable);
          });
        }
        if (snakesTable && snapshot != null && mySeat != null) {
          final progress = snapshot.pieces
              .where((piece) => piece.seat == mySeat)
              .map((piece) => piece.progress)
              .firstOrNull;
          if (progress != null && progress != _followedSnakeProgress) {
            _followedSnakeProgress = progress;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _followMySnakesToken(progress, animated: true);
            });
          }
        }
        if (snapshot != null && _positionedBoardMode != snapshot.mode) {
          _positionedBoardMode = snapshot.mode;
          if (snakesTable) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _boardScroll.hasClients) {
                // The starting squares are at the bottom of a Snakes board.
                _boardScroll.jumpTo(_boardScroll.position.maxScrollExtent);
              }
            });
          }
        }

        return MatchStyle(
            palette: palette,
            child: PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) _showQuitDialog(context, state);
              },
              child: Scaffold(
                backgroundColor: const Color(0xFF1A0520),
                body: Stack(
                  children: [
                    Positioned.fill(
                        child: AnimatedBuilder(
                      animation: _bgCtrl,
                      builder: (_, __) => MatchBackdrop(
                          palette: palette, phase: reduced ? 0 : _bgCtrl.value),
                    )),
                    SafeArea(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxHeight < 760;
                          final topBarHeight = compact ? 50.0 : 58.0;
                          final heroHeight = compact ? 90.0 : 108.0;
                          final actionHeight = snakesTable
                              ? (compact ? 158.0 : 188.0)
                              : (compact ? 166.0 : 202.0);
                          final boardGap = compact ? 5.0 : 8.0;
                          final boardAspect = snakesTable ? 1.13 : 1.0;
                          final availableWidth =
                              math.min(560.0, constraints.maxWidth - 14);
                          final boardWidth = snakesTable
                              ? availableWidth
                              : math.min(
                                  availableWidth,
                                  math.max(
                                      160.0,
                                      constraints.maxHeight -
                                          topBarHeight -
                                          heroHeight -
                                          actionHeight -
                                          26));
                          final boardHeight = boardWidth * boardAspect;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: topBarHeight,
                                child: _GameTopBar(
                                  state: state,
                                  snapshot: snapshot,
                                  mySeat: mySeat,
                                  onMenu: () => _showQuitDialog(context, state),
                                ),
                              ),
                              SizedBox(height: compact ? 4 : 6),
                              SizedBox(
                                height: heroHeight,
                                child: _PlayerHeroBand(
                                  state: state,
                                  snapshot: snapshot,
                                  mySeat: mySeat,
                                  pulse: _turnPulse,
                                  compact: compact,
                                  snakesTable: snakesTable,
                                  moment: _moment,
                                  celebration: _avatarSequence,
                                ),
                              ),
                              SizedBox(height: boardGap),
                              Expanded(
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                        child: Scrollbar(
                                      controller: _boardScroll,
                                      thumbVisibility: true,
                                      interactive: true,
                                      thickness: compact ? 3 : 4,
                                      radius: const Radius.circular(8),
                                      child: SingleChildScrollView(
                                        key: const ValueKey(
                                            'match-board-scroll'),
                                        controller: _boardScroll,
                                        physics: const ClampingScrollPhysics(),
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Center(
                                            child: SizedBox(
                                          width: boardWidth,
                                          height: boardHeight,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                                boxShadow: [
                                                  const BoxShadow(
                                                      color: Colors.black45,
                                                      blurRadius: 22,
                                                      offset: Offset(0, 10)),
                                                  BoxShadow(
                                                      color: palette.accent
                                                          .withAlpha(18),
                                                      blurRadius: 16)
                                                ]),
                                            child: snakesTable
                                                ? SnakesLaddersBoard(
                                                    snapshot: snapshot,
                                                    mySeat: mySeat,
                                                    onMotionChanged:
                                                        _onMotionChanged,
                                                    boardTheme:
                                                        state.snakesBoardTheme,
                                                    onPieceTap: (id) =>
                                                        state.movePiece(id),
                                                  )
                                                : LudoBoard(
                                                    snapshot: snapshot,
                                                    mySeat: mySeat,
                                                    onMotionChanged:
                                                        _onMotionChanged,
                                                    boardTheme:
                                                        state.ludoBoardTheme,
                                                    onPieceTap: (id) =>
                                                        state.movePiece(id),
                                                    showWaitingOverlay: false,
                                                  ),
                                          ),
                                        )),
                                      ),
                                    )),
                                    if (snakesTable && mySeat != null)
                                      Positioned(
                                        right: 12,
                                        bottom: 12,
                                        child: Semantics(
                                          button: true,
                                          label: 'Find my token on the board',
                                          child: FloatingActionButton.small(
                                            key:
                                                const ValueKey('find-my-token'),
                                            heroTag: 'find-my-token',
                                            tooltip: 'Find my token',
                                            backgroundColor: palette.surface,
                                            foregroundColor: palette.accent,
                                            onPressed: () {
                                              final progress = snapshot?.pieces
                                                  .where((piece) =>
                                                      piece.seat == mySeat)
                                                  .map(
                                                      (piece) => piece.progress)
                                                  .firstOrNull;
                                              if (progress != null) {
                                                SoundService.tap();
                                                _followMySnakesToken(progress,
                                                    animated: true);
                                              }
                                            },
                                            child: const Icon(
                                                Icons.my_location_rounded),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              _PlayerActionRow(
                                state: state,
                                snapshot: snapshot,
                                mySeat: mySeat,
                                diceKey: _diceKey,
                                canRoll: canRoll,
                                legalCount: legalCount,
                                rolling: _rolling,
                                piecesMoving: _piecesMoving,
                                moment: _moment,
                                celebration: _avatarSequence,
                                turnPulse: _turnPulse,
                                height: actionHeight,
                                onEmoji: () => _showEmojiPicker(context),
                                onChat: () => _showChatPicker(context),
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        },
                      ),
                    ),
                    Positioned.fill(
                        child: SixCelebration(sequence: _sixSequence)),
                    if (_quickBubbleText != null)
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: MediaQuery.of(context).padding.bottom + 172,
                        child: IgnorePointer(
                          child: _QuickBubble(
                            text: _quickBubbleText!,
                            isEmoji: _quickBubbleIsEmoji,
                            color: seatColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ));
      },
    );
  }

  void _followMySnakesToken(int progress, {required bool animated}) {
    if (!_boardScroll.hasClients) return;
    final position = _boardScroll.position;
    if (position.maxScrollExtent <= 0) return;
    final square = progress.clamp(1, 100);
    final rowFromBottom = (square - 1) ~/ 10;
    final rowFromTop = 9 - rowFromBottom;
    final contentHeight = position.maxScrollExtent + position.viewportDimension;
    final tokenY = contentHeight * (0.15 + ((rowFromTop + 0.5) / 10) * 0.84);
    final target = (tokenY - position.viewportDimension / 2)
        .clamp(0.0, position.maxScrollExtent)
        .toDouble();
    if (animated && !MediaQuery.disableAnimationsOf(context)) {
      _boardScroll.animateTo(
        target,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } else {
      _boardScroll.jumpTo(target);
    }
  }

  Future<void> _showFirstMatchGuide(
      BuildContext context, AppState state, bool snakes) async {
    state.markGameTutorialSeen();
    final steps = snakes
        ? const [
            (
              Icons.casino_rounded,
              'Roll once',
              'Your token moves automatically.'
            ),
            (
              Icons.stairs_rounded,
              'Climb ladders',
              'Land on the bottom to jump ahead.'
            ),
            (
              Icons.my_location_rounded,
              'Follow your token',
              'The board follows you. Use the target button any time.'
            ),
          ]
        : const [
            (
              Icons.casino_rounded,
              'Roll the dice',
              'A six brings a goti onto the board.'
            ),
            (
              Icons.touch_app_rounded,
              'Choose a goti',
              'Highlighted gotis are legal moves.'
            ),
            (
              Icons.flag_rounded,
              'Reach home',
              'Bring all four gotis home to win.'
            ),
          ];
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF32103C),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: goldColor, width: 1.5),
          ),
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.82),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(snakes ? 'Your first Snakes match' : 'Your first Ludo match',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              for (final step in steps)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: goldColor.withAlpha(35),
                    foregroundColor: goldColor,
                    child: Icon(step.$1),
                  ),
                  title: Text(step.$2,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w900)),
                  subtitle: Text(step.$3,
                      style: const TextStyle(color: Colors.white70)),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Let’s play'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showQuickBubble(String text, {bool isEmoji = false}) {
    _quickBubbleTimer?.cancel();
    setState(() {
      _quickBubbleText = text;
      _quickBubbleIsEmoji = isEmoji;
    });
    _quickBubbleTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() {
        _quickBubbleText = null;
        _quickBubbleIsEmoji = false;
      });
    });
  }

  void _showEmojiPicker(BuildContext context) {
    final state = context.read<AppState>();
    const emojis = tableEmojis;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _GameActionSheet(
          title: 'Emoji',
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.15,
            children: [
              for (final emoji in emojis)
                GestureDetector(
                  onTap: () {
                    SoundService.tap();
                    Navigator.pop(sheetContext);
                    state.sendReaction(emoji);
                    _showQuickBubble(emoji, isEmoji: true);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xAA250631),
                      border: Border.all(color: const Color(0x55FFD426)),
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showChatPicker(BuildContext context) {
    final state = context.read<AppState>();
    if (!state.canUseChat) {
      _showChatUnlockSheet(context, state);
      return;
    }

    final controller = TextEditingController();
    const quickMessages = tablePhrases;

    void send(BuildContext sheetContext, String raw) {
      final message = raw.trim();
      if (message.isEmpty) return;
      SoundService.tap();
      Navigator.pop(sheetContext);
      state.sendReaction(message, isEmoji: false);
      _showQuickBubble(message);
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottom = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: _GameActionSheet(
            title: 'Chat',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final message in quickMessages)
                      GestureDetector(
                        onTap: () => send(sheetContext, message),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: const Color(0xAA250631),
                            border: Border.all(color: const Color(0x55FFD426)),
                          ),
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        maxLength: 42,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'Type message',
                          hintStyle:
                              TextStyle(color: Colors.white.withAlpha(140)),
                          filled: true,
                          fillColor: const Color(0x88250631),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Color(0x55FFD426)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: goldColor, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    GestureDetector(
                      onTap: () => send(sheetContext, controller.text),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [goldColor, amberColor],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: goldColor.withAlpha(90),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Color(0xFF3D1600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(controller.dispose);
  }

  void _showChatUnlockSheet(BuildContext context, AppState state) {
    final needsAge = state.age == 0;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _GameActionSheet(
          title: needsAge ? 'Chat 13+' : 'Chat Locked',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                needsAge
                    ? 'Set your age to unlock table chat. Players under 13 can still use emoji.'
                    : 'Table chat is available for players 13 and older. Emoji is still enabled.',
                style: TextStyle(
                  color: Colors.white.withAlpha(220),
                  height: 1.25,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              if (needsAge) ...[
                Row(
                  children: [
                    Expanded(
                      child: _SheetButton(
                        label: 'I am 13+',
                        color: boardGreen,
                        onTap: () {
                          SoundService.tap();
                          state.updateProfile(age: 13);
                          Navigator.pop(sheetContext);
                          Future.microtask(() {
                            if (mounted) _showChatPicker(context);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SheetButton(
                        label: 'Under 13',
                        color: boardBlue,
                        onTap: () {
                          SoundService.tap();
                          state.updateProfile(age: 12);
                          Navigator.pop(sheetContext);
                          _showQuickBubble('Emoji only account');
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                _SheetButton(
                  label: 'Use Emoji',
                  color: boardBlue,
                  onTap: () {
                    SoundService.tap();
                    Navigator.pop(sheetContext);
                    _showEmojiPicker(context);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showQuitDialog(BuildContext context, AppState state) {
    if (_quitDialogOpen) return;
    _quitDialogOpen = true;
    SoundService.warning();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D0A35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x55FFD426)),
        ),
        title: const Text(
          'Quit Match?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Leaving now will resign this match.',
          style: TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay', style: TextStyle(color: goldColor)),
          ),
          TextButton(
            onPressed: _quitting
                ? null
                : () async {
                    _quitting = true;
                    Navigator.pop(context);
                    state.resign();
                    await LevelPlayAdService.instance.showAfterConfirmedQuit();
                    if (!mounted) return;
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/home', (_) => false);
                  },
            child: const Text('Exit', style: TextStyle(color: boardRed)),
          ),
        ],
      ),
    ).whenComplete(() {
      if (mounted) _quitDialogOpen = false;
    });
  }
}

class _GameActionSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const _GameActionSheet({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.82),
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A0B58), Color(0xFF18041F)],
          ),
          border: Border.all(color: goldColor, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xCC000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: goldColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white70, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(child: SingleChildScrollView(child: child)),
          ],
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(color, Colors.white, 0.28)!, color],
          ),
          border: Border.all(color: goldColor, width: 1.4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x77000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Colors.black87, blurRadius: 3)],
          ),
        ),
      ),
    );
  }
}

class _QuickBubble extends StatelessWidget {
  final String text;
  final bool isEmoji;
  final Color color;

  const _QuickBubble({
    required this.text,
    required this.isEmoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        final scale = 0.70 + value * 0.30;
        return Opacity(
          opacity: value.clamp(0.0, 1.0).toDouble(),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: EdgeInsets.symmetric(
            horizontal: isEmoji ? 18 : 16,
            vertical: isEmoji ? 8 : 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isEmoji ? 24 : 18),
            gradient: const LinearGradient(
              colors: [Color(0xF02D0A35), Color(0xF0110618)],
            ),
            border: Border.all(color: color.withAlpha(230), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(100),
                blurRadius: 18,
              ),
              const BoxShadow(
                color: Color(0x99000000),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: isEmoji ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: isEmoji ? 38 : 15,
              height: 1.05,
              fontWeight: FontWeight.w900,
              shadows: const [Shadow(color: Colors.black87, blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
  }
}
// Game background

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        final menuSize = compact ? 36.0 : 42.0;
        return Padding(
          padding:
              EdgeInsets.fromLTRB(compact ? 6 : 10, 2, compact ? 6 : 10, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: onMenu,
                child: Container(
                  width: menuSize,
                  height: menuSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(compact ? 11 : 13),
                    color: MatchStyle.of(context).surface,
                    border:
                        Border.all(color: const Color(0x66FFD426), width: 1.4),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x88000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Icon(Icons.menu_rounded,
                      color: Colors.white, size: compact ? 21 : 24),
                ),
              ),
              SizedBox(width: compact ? 5 : 8),
              _GameLogo(compact: compact),
              SizedBox(width: compact ? 4 : 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      children: [
                        _CurrencyChip(
                          icon: Icons.monetization_on_rounded,
                          value: state.coins,
                          color: const Color(0xFFFFBA24),
                          compact: compact,
                        ),
                        SizedBox(width: compact ? 4 : 6),
                        _CurrencyChip(
                          icon: Icons.bolt_rounded,
                          value: state.energy,
                          color: const Color(0xFF38C8FF),
                          compact: compact,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GameLogo extends StatelessWidget {
  final bool compact;

  const _GameLogo({required this.compact});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 62 : 82,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 1,
            child: Text(
              'Ludo',
              style: TextStyle(
                color: goldColor,
                fontSize: compact ? 20 : 26,
                height: 0.92,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    color: Color(0xFF6B2600),
                    blurRadius: 0,
                    offset: Offset(0, 3),
                  ),
                  Shadow(color: Colors.black, blurRadius: 5),
                ],
              ),
            ),
          ),
          Positioned(
            left: 2,
            top: compact ? 21 : 25,
            child: Text(
              'Rush',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 20 : 25,
                height: 0.92,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    color: Color(0xFF213083),
                    blurRadius: 0,
                    offset: Offset(0, 3),
                  ),
                  Shadow(color: Colors.black, blurRadius: 5),
                ],
              ),
            ),
          ),
          Positioned(
            right: compact ? -3 : -5,
            top: compact ? 7 : 5,
            child: Transform.rotate(
              angle: -0.38,
              child: DiceWidget(
                value: 5,
                size: compact ? 20 : 25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;
  final bool compact;

  const _CurrencyChip({
    required this.icon,
    required this.value,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 30 : 34,
      constraints: BoxConstraints(minWidth: compact ? 56 : 72),
      padding: EdgeInsets.only(left: 3, right: compact ? 6 : 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xC5140020),
        border: Border.all(color: Colors.white.withAlpha(35), width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x77000000), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 24 : 28,
            height: compact ? 24 : 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.white.withAlpha(230), color],
              ),
              boxShadow: [
                BoxShadow(color: color.withAlpha(105), blurRadius: 9)
              ],
            ),
            child: Icon(icon, size: compact ? 15 : 18, color: Colors.white),
          ),
          SizedBox(width: compact ? 5 : 7),
          Text(
            _shortNumber(value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: Colors.black, blurRadius: 3)],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerHeroBand extends StatelessWidget {
  final AppState state;
  final GameSnapshot? snapshot;
  final int? mySeat;
  final AnimationController pulse;
  final bool compact;
  final bool snakesTable;
  final MatchMoment? moment;
  final int celebration;
  const _PlayerHeroBand(
      {required this.state,
      required this.snapshot,
      required this.mySeat,
      required this.pulse,
      required this.compact,
      required this.snakesTable,
      required this.moment,
      required this.celebration});
  @override
  Widget build(BuildContext context) {
    final palette = MatchStyle.of(context);
    final playing = snapshot?.status == 'playing';
    final myTurn = playing && snapshot?.currentTurnSeat == mySeat;
    final active =
        snapshot?.seats.where((s) => s.seat == snapshot?.currentTurnSeat);
    final turn = state.isSpectator
        ? 'Spectating live'
        : !playing
            ? 'Your table'
            : myTurn
                ? 'Your turn'
                : "${active != null && active.isNotEmpty ? state.publicSeatName(active.first) : 'Opponent'}'s turn";
    final ownMoment = moment?.seat == mySeat ? moment : null;
    return AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          final glow =
              MediaQuery.disableAnimationsOf(context) ? .5 : pulse.value;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(colors: palette.panel),
                border: Border.all(
                    color: myTurn ? palette.accent : Colors.white24,
                    width: myTurn ? 1.8 : 1),
                boxShadow: [
                  BoxShadow(
                      color: myTurn
                          ? palette.accent.withAlpha((25 + glow * 35).round())
                          : Colors.black26,
                      blurRadius: 18,
                      offset: const Offset(0, 5))
                ]),
            child: Row(children: [
              SizedBox.square(
                  dimension: compact ? 62 : 76,
                  child: ProfileAvatarView(
                      preset: state.avatarPreset,
                      imagePath: state.avatarImagePath,
                      celebration: celebration,
                      mood: ownMoment?.mood ?? AvatarMood.idle)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Expanded(
                          child: Text(
                              state.displayName.trim().isEmpty
                                  ? 'Player'
                                  : state.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compact ? 18 : 22,
                                  fontWeight: FontWeight.w800))),
                      if (state.privateInviteCode != null)
                        _InviteCodeChip(
                            code: state.privateInviteCode!, compact: true)
                    ]),
                    const SizedBox(height: 5),
                    Row(children: [
                      Expanded(
                        child: Semantics(
                            liveRegion: true,
                            child: Text(ownMoment?.label ?? turn,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: palette.accent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700))),
                      ),
                      if (playing && (snapshot?.turnDeadlineAt ?? 0) > 0) ...[
                        const SizedBox(width: 5),
                        _TurnTimerChip(snapshot: snapshot!),
                      ],
                    ]),
                    if (!compact)
                      Text('${state.rating} rating',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12)),
                  ])),
              if (myTurn)
                Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.play_circle_fill_rounded,
                        color: palette.accent, size: 28)),
            ]),
          );
        });
  }
}

class _TurnTimerChip extends StatelessWidget {
  final GameSnapshot snapshot;
  const _TurnTimerChip({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final remaining = math.max(
        0,
        ((snapshot.turnDeadlineAt - DateTime.now().millisecondsSinceEpoch) /
                1000)
            .ceil());
    final urgent = remaining <= 5;
    return Semantics(
      label: '$remaining seconds left in this turn',
      liveRegion: urgent,
      child: Container(
        key: const ValueKey('turn-timer'),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: (urgent ? boardRed : Colors.white).withAlpha(28),
          border: Border.all(color: urgent ? boardRed : Colors.white24),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.timer_outlined,
              size: 11,
              color: urgent ? const Color(0xFFFF8A80) : Colors.white70),
          const SizedBox(width: 3),
          Text('${remaining}s',
              style: TextStyle(
                  color: urgent ? const Color(0xFFFF8A80) : Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }
}

class _InviteCodeChip extends StatelessWidget {
  final String code;
  final bool compact;

  const _InviteCodeChip({
    required this.code,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 20 : 23,
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xAA140020),
        border: Border.all(color: goldColor.withAlpha(190), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.vpn_key_rounded,
              color: goldColor, size: compact ? 12 : 14),
          const SizedBox(width: 4),
          Text(
            'Code $code',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w900,
              shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerActionRow extends StatelessWidget {
  final AppState state;
  final GameSnapshot? snapshot;
  final int? mySeat;
  final GlobalKey<DiceWidgetState> diceKey;
  final bool canRoll;
  final int legalCount;
  final bool rolling;
  final bool piecesMoving;
  final MatchMoment? moment;
  final int celebration;
  final AnimationController turnPulse;
  final double height;
  final VoidCallback onEmoji;
  final VoidCallback onChat;

  const _PlayerActionRow({
    required this.state,
    required this.snapshot,
    required this.mySeat,
    required this.diceKey,
    required this.canRoll,
    required this.legalCount,
    required this.rolling,
    required this.piecesMoving,
    required this.moment,
    required this.celebration,
    required this.turnPulse,
    required this.height,
    required this.onEmoji,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final seat = mySeat ?? 0;
    final seatColor = AppColors.seatColor(seat);
    final waitingForPlayers = snapshot?.status == 'waiting';
    final isMyTurn = snapshot?.currentTurnSeat == mySeat;
    final hasDice = (snapshot?.diceValue ?? 0) > 0;
    final showMove = snapshot?.status == 'playing' &&
        hasDice &&
        legalCount > 0 &&
        isMyTurn &&
        !rolling &&
        !piecesMoving;
    final snakesTable = snapshot?.mode == AppState.snakesLaddersMode;
    // Snakes has one token, and a single legal Ludo move is unambiguous. When
    // several Ludo gotis can move, the player must tap the highlighted goti so
    // a central shortcut cannot silently choose a non-capturing move.
    final canQuickMove = showMove && (snakesTable || legalCount == 1);
    final enabled = canRoll || canQuickMove;
    final action =
        canQuickMove ? state.moveBestPiece : (canRoll ? state.rollDice : null);
    final actionLabel = state.isSpectator
        ? 'Watching live'
        : snapshot == null
            ? 'Connecting...'
            : waitingForPlayers
                ? 'Waiting for players'
                : piecesMoving
                    ? 'Moving...'
                    : rolling
                        ? 'Rolling'
                        : showMove
                            ? canQuickMove
                                ? snakesTable
                                    ? 'Move Token'
                                    : 'Move Goti'
                                : 'Choose Goti'
                            : canRoll
                                ? 'Tap to Roll'
                                : isMyTurn
                                    ? 'Choose Goti'
                                    : 'Wait Turn';
    final opponents =
        snapshot?.seats.where((s) => s.seat != mySeat).toList() ?? const [];

    final palette = MatchStyle.of(context);
    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Column(children: [
        if (opponents.isNotEmpty)
          SizedBox(
              height: 40,
              child: _OpponentDock(
                  seats: opponents,
                  state: state,
                  activeSeat: snapshot?.status == 'playing'
                      ? snapshot?.currentTurnSeat
                      : null,
                  moment: moment,
                  celebration: celebration,
                  compact: true)),
        const SizedBox(height: 7),
        Expanded(child: LayoutBuilder(builder: (context, box) {
          final diceSize = math.min(96.0, math.max(48.0, box.maxHeight - 39));
          return Row(children: [
            SizedBox(
                width: 48,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                          tooltip: 'Emoji',
                          onPressed: state.isSpectator ? null : onEmoji,
                          style: IconButton.styleFrom(
                              backgroundColor: palette.surface,
                              foregroundColor: palette.accent),
                          icon: const Icon(Icons.mood_rounded)),
                      const SizedBox(height: 4),
                      IconButton(
                          tooltip: 'Chat',
                          onPressed: state.isSpectator ? null : onChat,
                          style: IconButton.styleFrom(
                              backgroundColor: palette.surface,
                              foregroundColor: palette.accent),
                          icon: const Icon(Icons.chat_bubble_outline_rounded)),
                    ])),
            const SizedBox(width: 8),
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  _DiceActionButton(
                      diceKey: diceKey,
                      value: state.lastRollValue > 0
                          ? state.lastRollValue
                          : snapshot?.diceValue,
                      enabled: enabled,
                      moving: canQuickMove,
                      color: seatColor,
                      pulse: turnPulse,
                      size: diceSize,
                      skin: state.diceSkin,
                      onTap: action),
                  const SizedBox(height: 5),
                  SizedBox(
                      height: 32,
                      width: double.infinity,
                      child: Semantics(
                          button: true,
                          enabled: enabled,
                          child: GestureDetector(
                              onTap: action,
                              child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      gradient:
                                          LinearGradient(colors: palette.panel),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: palette.accent
                                              .withAlpha(enabled ? 200 : 70))),
                                  child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          child: Text(actionLabel,
                                              style: TextStyle(
                                                  color: enabled
                                                      ? Colors.white
                                                      : Colors.white60,
                                                  fontSize: 15,
                                                  fontWeight:
                                                      FontWeight.w800)))))))),
                ])),
            const SizedBox(width: 8),
            SizedBox(
                width: 82,
                child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: state.isSpectator
                        ? const Icon(Icons.visibility_rounded,
                            color: Colors.white70, size: 30)
                        : _AutoRollChip(
                            enabled: state.autoRollEnabled,
                            compact: true,
                            onChanged: state.setAutoRollEnabled))),
          ]);
        })),
      ]),
    );
  }
}

class _OpponentDock extends StatelessWidget {
  final List<SeatState> seats;
  final AppState state;
  final int? activeSeat;
  final MatchMoment? moment;
  final int celebration;
  final bool compact;

  const _OpponentDock({
    required this.seats,
    required this.state,
    required this.activeSeat,
    required this.moment,
    required this.celebration,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < seats.length; i++) ...[
          Expanded(
            child: _OpponentChip(
              seat: seats[i],
              state: state,
              active: seats[i].seat == activeSeat,
              mood: moment?.seat == seats[i].seat
                  ? moment!.mood
                  : AvatarMood.idle,
              celebration: celebration,
              compact: true,
              dense: compact,
            ),
          ),
          if (i != seats.length - 1) SizedBox(width: compact ? 5 : 7),
        ],
      ],
    );
  }
}

class _OpponentChip extends StatelessWidget {
  final SeatState seat;
  final AppState state;
  final bool active;
  final bool compact;
  final bool dense;
  final AvatarMood mood;
  final int celebration;

  const _OpponentChip({
    required this.seat,
    required this.state,
    required this.active,
    required this.compact,
    this.dense = false,
    this.mood = AvatarMood.idle,
    this.celebration = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.seatColor(seat.seat);
    final name = state.publicSeatName(seat);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: dense ? 36 : (compact ? 43 : 50),
      padding: EdgeInsets.fromLTRB(
        dense ? 4 : 5,
        dense ? 3 : (compact ? 4 : 5),
        dense ? 5 : 8,
        dense ? 3 : (compact ? 4 : 5),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            Color.lerp(color, Colors.black, 0.25)!.withAlpha(224),
            const Color(0xDD12051C),
          ],
        ),
        border: Border.all(
          color: active ? goldColor : Colors.white.withAlpha(72),
          width: active ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: active ? color.withAlpha(120) : const Color(0x88000000),
            blurRadius: active ? 13 : 7,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: dense ? 27 : (compact ? 31 : 37),
            height: dense ? 27 : (compact ? 31 : 37),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.white.withAlpha(230), color],
              ),
              border: Border.all(color: goldColor, width: 1.4),
            ),
            child: ProfileAvatarView(
                preset: 12 + seat.seat, mood: mood, celebration: celebration),
          ),
          SizedBox(width: dense ? 4 : 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: dense ? 10 : (compact ? 11 : 13),
                    height: 1,
                    fontWeight: FontWeight.w900,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                        !seat.connected
                            ? Icons.wifi_off_rounded
                            : active
                                ? Icons.play_arrow_rounded
                                : Icons.circle_outlined,
                        color: seat.connected ? goldColor : Colors.white54,
                        size: 14),
                    const SizedBox(width: 3),
                    Flexible(
                        child: Text(
                      !seat.connected
                          ? 'Reconnecting'
                          : active
                              ? 'Playing'
                              : 'Waiting',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: seat.connected ? goldColor : Colors.white54,
                        fontSize: dense ? 9 : (compact ? 10 : 12),
                        height: 1,
                        fontWeight: FontWeight.w900,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 3)
                        ],
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiceActionButton extends StatelessWidget {
  final GlobalKey<DiceWidgetState> diceKey;
  final int? value;
  final bool enabled;
  final bool moving;
  final Color color;
  final AnimationController pulse;
  final double size;
  final String skin;
  final VoidCallback? onTap;

  const _DiceActionButton({
    required this.diceKey,
    required this.value,
    required this.enabled,
    required this.moving,
    required this.color,
    required this.pulse,
    required this.skin,
    this.size = 66,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final glow = enabled
            ? (MediaQuery.disableAnimationsOf(context)
                ? .5
                : (0.45 + pulse.value * 0.55))
            : 0.0;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        MatchStyle.of(context).accent,
                        color.withAlpha(210),
                        const Color(0xFFFFF6AE),
                        MatchStyle.of(context).accent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: goldColor.withAlpha((120 + glow * 100).round()),
                        blurRadius: enabled ? size * 0.24 : size * 0.12,
                      ),
                      const BoxShadow(
                        color: Color(0xBB000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: size * 0.82,
                  height: size * 0.82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: MatchStyle.of(context).panel,
                    ),
                    border: Border.all(
                      color: enabled ? const Color(0xFFFFF0A0) : Colors.white,
                      width: size * 0.035,
                    ),
                  ),
                ),
                DiceWidget(
                    key: diceKey, value: value, size: size * 0.72, skin: skin),
                if (moving)
                  Positioned(
                    right: size * 0.14,
                    bottom: size * 0.12,
                    child: Container(
                      width: size * 0.23,
                      height: size * 0.23,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withAlpha(145),
                        border: Border.all(
                            color: Colors.white.withAlpha(200), width: 1),
                      ),
                      child: Icon(Icons.touch_app_rounded,
                          color: Colors.white, size: size * 0.15),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AutoRollChip extends StatelessWidget {
  final bool enabled;
  final bool compact;
  final ValueChanged<bool> onChanged;

  const _AutoRollChip({
    required this.enabled,
    required this.compact,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Auto roll',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!enabled),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: compact ? 94 : 108,
          height: compact ? 30 : 34,
          padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: enabled
                  ? const [Color(0xFF51EA6A), Color(0xFF168E36)]
                  : const [Color(0xFF54205D), Color(0xFF21062B)],
            ),
            border: Border.all(
              color: enabled ? const Color(0xFFFFFFAA) : goldColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (enabled ? boardGreen : Colors.black).withAlpha(95),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Auto',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 3),
                    ],
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: compact ? 33 : 38,
                height: compact ? 18 : 20,
                padding: const EdgeInsets.all(2),
                alignment:
                    enabled ? Alignment.centerRight : Alignment.centerLeft,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xAA140020),
                ),
                child: Container(
                  width: compact ? 14 : 16,
                  height: compact ? 14 : 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: enabled ? goldColor : Colors.white70,
                    boxShadow: const [
                      BoxShadow(color: Color(0x99000000), blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
