import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/game_snapshot.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ludo_board.dart';
import '../widgets/snakes_ladders_board.dart';
import '../widgets/dice_widget.dart';

const _gameBackdropAsset = 'assets/images/rush/rush_game_backdrop_v3.png';
const _gameMascotAsset = 'assets/images/rush/rush_game_mascot_v3.png';
const _reactionSixAsset = 'assets/images/rush/rush_game_reaction_six_v3.png';
const _reactionCrownAsset =
    'assets/images/rush/rush_game_reaction_crown_v3.png';

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
  bool _quitDialogOpen = false;
  Timer? _quickBubbleTimer;
  String? _quickBubbleText;
  bool _quickBubbleIsEmoji = false;

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
    _quickBubbleTimer?.cancel();
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
          final rollSequence = state.lastRollSequence;
          final rollValue = state.lastRollValue;
          if (rollSequence != _prevRollSequence && rollValue > 0) {
            _prevRollSequence = rollSequence;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_rolling) {
                _rolling = true;
                _diceKey.currentState?.startRoll(rollValue, () {
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
        final snakesTable = snapshot?.mode == AppState.snakesLaddersMode;

        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (!didPop) _showQuitDialog(context, state);
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF1A0520),
            body: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    _gameBackdropAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF120018).withAlpha(130),
                          const Color(0x00120018),
                          const Color(0xEE16001E),
                        ],
                        stops: const [0, 0.48, 1],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _bgCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _GameBgPainter(_bgCtrl.value, seatColor),
                    ),
                  ),
                ),
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
                      final maxBoardFromHeight = math.max(
                        240.0,
                        constraints.maxHeight -
                            topBarHeight -
                            heroHeight -
                            actionHeight -
                            boardGap * 4 -
                            6.0,
                      );
                      final boardAspect = snakesTable ? 1.13 : 1.0;
                      final boardWidth = math.min(
                        constraints.maxWidth - 14,
                        maxBoardFromHeight / boardAspect,
                      );
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
                            ),
                          ),
                          SizedBox(height: boardGap),
                          SizedBox(
                            width: boardWidth,
                            height: boardHeight,
                            child: snakesTable
                                ? SnakesLaddersBoard(
                                    snapshot: snapshot,
                                    mySeat: mySeat,
                                    boardTheme: state.snakesBoardTheme,
                                    onPieceTap: (id) => state.movePiece(id),
                                  )
                                : LudoBoard(
                                    snapshot: snapshot,
                                    mySeat: mySeat,
                                    onPieceTap: (id) => state.movePiece(id),
                                    showWaitingOverlay: false,
                                  ),
                          ),
                          const Spacer(),
                          _PlayerActionRow(
                            state: state,
                            snapshot: snapshot,
                            mySeat: mySeat,
                            diceKey: _diceKey,
                            canRoll: canRoll,
                            legalCount: legalCount,
                            rolling: _rolling,
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
        );
      },
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
    final emojis = <String>[
      String.fromCharCode(0x1F600),
      String.fromCharCode(0x1F602),
      String.fromCharCode(0x1F62E),
      String.fromCharCode(0x1F44D),
      String.fromCharCode(0x1F525),
      String.fromCharCode(0x1F3B2),
      String.fromCharCode(0x1F451),
      String.fromCharCode(0x1F44F),
    ];
    showModalBottomSheet<void>(
      context: context,
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
    const quickMessages = [
      'Good luck!',
      'Nice move!',
      'Well played!',
      'Close one!',
      'Roll again!',
      'I need a six!',
      'Your turn!',
      'Good game!',
    ];

    void send(BuildContext sheetContext, String raw) {
      final message = raw.trim();
      if (message.isEmpty) return;
      SoundService.tap();
      Navigator.pop(sheetContext);
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
            onPressed: () {
              Navigator.pop(context);
              state.resign();
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
            child,
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
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 160),
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

class _GameBgPainter extends CustomPainter {
  final double t;
  final Color seatColor;
  _GameBgPainter(this.t, this.seatColor);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;

    p.shader = ui.Gradient.radial(
      Offset(size.width * 0.5, size.height),
      size.width * 0.6,
      [seatColor.withAlpha(54), Colors.transparent],
    );
    canvas.drawRect(Offset.zero & size, p);
    p.shader = null;

    final ax = size.width * (0.5 + 0.3 * math.sin(t * math.pi * 2));
    final ay = size.height * 0.15;
    p.shader = ui.Gradient.radial(
      Offset(ax, ay),
      size.width * 0.4,
      [const Color(0x26FF9A00), Colors.transparent],
    );
    canvas.drawRect(Offset.zero & size, p);
    p.shader = null;

    for (int i = 0; i < 36; i++) {
      final sx = ((i * 137 + 41) % 1000) / 1000.0 * size.width;
      final sy = ((i * 211 + 17) % 1000) / 1000.0 * size.height;
      final flicker = 0.5 + 0.5 * math.sin(t * math.pi * 2 + i);
      p.color = Colors.white.withAlpha((18 + flicker * 34).round());
      canvas.drawCircle(Offset(sx, sy), 0.75 + flicker * 1.15, p);
    }
  }

  @override
  bool shouldRepaint(_GameBgPainter old) => old.t != t;
}

// Game top bar

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
                    color: const Color(0xAA250534),
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
              const Spacer(),
              _CurrencyChip(
                icon: Icons.monetization_on_rounded,
                value: state.coins,
                color: const Color(0xFFFFBA24),
                compact: compact,
              ),
              SizedBox(width: compact ? 4 : 6),
              _CurrencyChip(
                icon: Icons.diamond_rounded,
                value: 30,
                color: const Color(0xFF27E99C),
                compact: compact,
              ),
              SizedBox(width: compact ? 4 : 6),
              _CurrencyChip(
                icon: Icons.bolt_rounded,
                value: 12,
                color: const Color(0xFF38C8FF),
                plus: true,
                compact: compact,
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
            top: compact ? -3 : -7,
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
            top: compact ? 15 : 17,
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
              child: DiceWidget(value: 5, size: compact ? 20 : 25),
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
  final bool plus;
  final bool compact;

  const _CurrencyChip({
    required this.icon,
    required this.value,
    required this.color,
    this.plus = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 30 : 34,
      constraints: BoxConstraints(minWidth: compact ? 56 : 72),
      padding: EdgeInsets.only(left: 3, right: plus ? 3 : (compact ? 6 : 10)),
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
          if (plus) ...[
            SizedBox(width: compact ? 3 : 5),
            Icon(Icons.add_circle, color: goldColor, size: compact ? 16 : 19),
          ],
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

  const _PlayerHeroBand({
    required this.state,
    required this.snapshot,
    required this.mySeat,
    required this.pulse,
    required this.compact,
    required this.snakesTable,
  });

  @override
  Widget build(BuildContext context) {
    final seat = mySeat ?? 0;
    final activeSeat = snapshot?.currentTurnSeat;
    final myTurn = activeSeat == mySeat;
    final color = AppColors.seatColor(seat);
    final displayName =
        state.displayName.trim().isEmpty || state.displayName == 'Ludo Player'
            ? 'Ibsam'
            : state.displayName;
    final sixActive = state.lastRollValue == 6;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: pulse,
              builder: (_, __) {
                final glow = myTurn ? (0.55 + pulse.value * 0.45) : 0.35;
                return Container(
                  height: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    compact ? 8 : 10,
                    compact ? 8 : 10,
                    compact ? 8 : 12,
                    compact ? 7 : 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xEE8B146F), Color(0xD62A063B)],
                    ),
                    border: Border.all(color: goldColor, width: 2.2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha((80 * glow).round()),
                        blurRadius: 22,
                      ),
                      const BoxShadow(
                        color: Color(0x99000000),
                        blurRadius: 16,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _MascotAvatar(
                        color: color,
                        size: compact ? 66 : 78,
                        badge: myTurn ? '1st' : '12',
                      ),
                      SizedBox(width: compact ? 8 : 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: compact ? 20 : 23,
                                      fontWeight: FontWeight.w900,
                                      shadows: const [
                                        Shadow(
                                            color: Colors.black, blurRadius: 4)
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _CountryPill(code: state.countryCode),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.emoji_events_rounded,
                                    color: goldColor, size: 20),
                                const SizedBox(width: 5),
                                Text(
                                  _shortNumber(state.rating),
                                  style: TextStyle(
                                    color: goldColor,
                                    fontSize: compact ? 16 : 18,
                                    fontWeight: FontWeight.w900,
                                    shadows: const [
                                      Shadow(color: Colors.black, blurRadius: 4)
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: compact ? 28 : 32,
                                  height: compact ? 28 : 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF4AA3FF),
                                        Color(0xFF2246A6)
                                      ],
                                    ),
                                    border: Border.all(
                                        color: goldColor, width: 1.5),
                                  ),
                                  child: const Icon(Icons.shield_rounded,
                                      color: goldColor, size: 18),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: compact ? 116 : 134,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ReactionBadge(
                  asset: _reactionSixAsset,
                  title: snakesTable ? 'Ladder' : 'Six!',
                  subtitle: snakesTable ? 'Climb Boost' : 'Rush Boost',
                  active: sixActive,
                  compact: compact,
                ),
                _ReactionBadge(
                  asset: _reactionCrownAsset,
                  title: snakesTable ? 'Snake' : 'Leader',
                  subtitle: snakesTable ? 'Shield' : 'Glow',
                  active: myTurn,
                  compact: compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MascotAvatar extends StatelessWidget {
  final Color color;
  final double size;
  final String badge;

  const _MascotAvatar({
    required this.color,
    required this.size,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white, color, const Color(0xFF5F0318)],
                  stops: const [0.0, 0.58, 1.0],
                ),
                border: Border.all(color: goldColor, width: 4),
                boxShadow: [
                  BoxShadow(color: color.withAlpha(160), blurRadius: 18),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: ClipOval(
              child: Align(
                alignment: const Alignment(0, -0.74),
                widthFactor: 1,
                heightFactor: 1,
                child: Image.asset(
                  _gameMascotAsset,
                  width: size * 1.55,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          ),
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              width: size * 0.42,
              height: size * 0.42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF3B4E),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 5)
                ],
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.17,
                  fontWeight: FontWeight.w900,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryPill extends StatelessWidget {
  final String code;

  const _CountryPill({required this.code});

  @override
  Widget build(BuildContext context) {
    final clean = code.trim().isEmpty ? 'US' : code.trim().toUpperCase();
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 8, 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0x880D0920),
        border: Border.all(color: goldColor, width: 1.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 13,
            height: 9,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.white, width: 0.7),
              gradient: const LinearGradient(
                colors: [Color(0xFF2544B8), Color(0xFFE13B42)],
              ),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            clean,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionBadge extends StatelessWidget {
  final String asset;
  final String title;
  final String subtitle;
  final bool active;
  final bool compact;

  const _ReactionBadge({
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1 : 0.86,
      duration: const Duration(milliseconds: 180),
      child: Container(
        height: compact ? 40 : 48,
        padding: const EdgeInsets.fromLTRB(4, 3, 6, 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xCC3A073E), Color(0xAA12051F)],
          ),
          border: Border.all(
            color: active ? goldColor : Colors.white.withAlpha(58),
            width: active ? 1.7 : 1,
          ),
          boxShadow: active
              ? const [
                  BoxShadow(color: Color(0x88FFD426), blurRadius: 13),
                ]
              : null,
        ),
        child: Row(
          children: [
            Image.asset(asset, width: compact ? 36 : 42, fit: BoxFit.contain),
            const SizedBox(width: 3),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 13 : 16,
                      height: 0.9,
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 3)
                      ],
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: goldColor,
                      fontSize: compact ? 9 : 11,
                      height: 1.0,
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 3)
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Player action row

class _PlayerActionRow extends StatelessWidget {
  final AppState state;
  final GameSnapshot? snapshot;
  final int? mySeat;
  final GlobalKey<DiceWidgetState> diceKey;
  final bool canRoll;
  final int legalCount;
  final bool rolling;
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
    required this.turnPulse,
    required this.height,
    required this.onEmoji,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final seat = mySeat ?? 0;
    final seatColor = AppColors.seatColor(seat);
    final isMyTurn = snapshot?.currentTurnSeat == mySeat;
    final hasDice = (snapshot?.diceValue ?? 0) > 0;
    final showMove = hasDice && legalCount > 0 && isMyTurn && !rolling;
    final enabled = canRoll || showMove;
    final action =
        showMove ? state.moveBestPiece : (canRoll ? state.rollDice : null);
    final actionLabel = rolling
        ? 'Rolling'
        : showMove
            ? 'Tap to Move'
            : canRoll
                ? 'Tap to Roll'
                : isMyTurn
                    ? 'Choose Goti'
                    : 'Wait Turn';
    final opponents =
        snapshot?.seats.where((s) => s.seat != mySeat).toList() ?? const [];
    final rightOpponent = opponents.isNotEmpty ? opponents.first : null;
    final lowerOpponents = opponents.length > 1
        ? opponents.sublist(1, math.min(opponents.length, 3))
        : const <SeatState>[];

    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 184;
          final diceSize = compact ? 92.0 : 116.0;
          final mascotWidth = compact ? 118.0 : 154.0;
          final diceTop = compact ? 9.0 : 7.0;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -8,
                bottom: compact ? 22 : 8,
                width: mascotWidth,
                child: IgnorePointer(
                  child: Image.asset(
                    _gameMascotAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              if (lowerOpponents.isNotEmpty)
                Positioned(
                  left: compact ? 5 : 10,
                  bottom: compact ? 20 : 22,
                  width: compact ? 136 : 158,
                  child: _OpponentRoster(
                    seats: lowerOpponents,
                    state: state,
                    activeSeat: snapshot?.currentTurnSeat,
                    compact: compact,
                  ),
                ),
              Positioned(
                top: diceTop,
                left: (constraints.maxWidth - diceSize) / 2,
                child: _DiceActionButton(
                  diceKey: diceKey,
                  enabled: enabled,
                  moving: showMove,
                  color: showMove ? boardGreen : seatColor,
                  pulse: turnPulse,
                  size: diceSize,
                  onTap: action,
                ),
              ),
              Positioned(
                top: diceTop + diceSize + (compact ? 4 : 8),
                left: (constraints.maxWidth - (compact ? 132 : 154)) / 2,
                width: compact ? 132 : 154,
                height: compact ? 34 : 40,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: action,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF61205E), Color(0xFF28072E)],
                      ),
                      border: Border.all(color: goldColor, width: 1.8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xAA000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      actionLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 15 : 18,
                        fontWeight: FontWeight.w900,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 4)
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (rightOpponent != null)
                Positioned(
                  right: compact ? 4 : 10,
                  top: compact ? 24 : 42,
                  width: compact ? 126 : 152,
                  child: _OpponentChip(
                    seat: rightOpponent,
                    state: state,
                    active: rightOpponent.seat == snapshot?.currentTurnSeat,
                    compact: compact,
                  ),
                ),
              Positioned(
                right: compact ? 8 : 14,
                bottom: compact ? 22 : 24,
                child: Row(
                  children: [
                    _ActionPill(
                      label: 'Emoji',
                      icon: Icons.mood_rounded,
                      onTap: onEmoji,
                    ),
                    const SizedBox(width: 12),
                    _ActionPill(
                      label: 'Chat',
                      icon: Icons.chat_bubble_rounded,
                      onTap: onChat,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OpponentRoster extends StatelessWidget {
  final List<SeatState> seats;
  final AppState state;
  final int? activeSeat;
  final bool compact;

  const _OpponentRoster({
    required this.seats,
    required this.state,
    required this.activeSeat,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final seat in seats)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: _OpponentChip(
              seat: seat,
              state: state,
              active: seat.seat == activeSeat,
              compact: compact,
            ),
          ),
      ],
    );
  }
}

class _OpponentChip extends StatelessWidget {
  final SeatState seat;
  final AppState state;
  final bool active;
  final bool compact;

  const _OpponentChip({
    required this.seat,
    required this.state,
    required this.active,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.seatColor(seat.seat);
    final name = state.publicSeatName(seat);
    final score = 620 + seat.seat * 170;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: compact ? 43 : 50,
      padding: EdgeInsets.fromLTRB(5, compact ? 4 : 5, 8, compact ? 4 : 5),
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
            width: compact ? 31 : 37,
            height: compact ? 31 : 37,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.white.withAlpha(230), color],
              ),
              border: Border.all(color: goldColor, width: 1.4),
            ),
            child: Icon(Icons.person_pin_circle_rounded,
                color: Colors.white, size: compact ? 20 : 24),
          ),
          const SizedBox(width: 6),
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
                    fontSize: compact ? 11 : 13,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        color: goldColor, size: 14),
                    const SizedBox(width: 3),
                    Text(
                      score.toString(),
                      style: TextStyle(
                        color: goldColor,
                        fontSize: compact ? 10 : 12,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 3)
                        ],
                      ),
                    ),
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
  final bool enabled;
  final bool moving;
  final Color color;
  final AnimationController pulse;
  final double size;
  final VoidCallback? onTap;

  const _DiceActionButton({
    required this.diceKey,
    required this.enabled,
    required this.moving,
    required this.color,
    required this.pulse,
    this.size = 66,
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
                        goldColor,
                        color.withAlpha(210),
                        const Color(0xFFFFF6AE),
                        goldColor,
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
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFF2D3B), Color(0xFF530029)],
                    ),
                    border: Border.all(
                      color: enabled ? const Color(0xFFFFF0A0) : Colors.white,
                      width: size * 0.035,
                    ),
                  ),
                ),
                DiceWidget(key: diceKey, size: size * 0.72),
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
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: () {
          SoundService.tap();
          onTap();
        },
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFEE8C), Color(0xFFFF9D00)],
            ),
            border: Border.all(color: const Color(0xFFFFF3B0), width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0xAA000000), blurRadius: 9),
              BoxShadow(color: Color(0x77FFD426), blurRadius: 14),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF38104A), size: 30),
        ),
      ),
    );
  }
}
