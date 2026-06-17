import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ludo_board.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (!didPop) _cancel(context, state);
          },
          child: Scaffold(
            backgroundColor: bgDeep,
            body: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => CustomPaint(
                      painter: _MatchmakingBgPainter(_pulse.value),
                    ),
                  ),
                ),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final narrow = box.maxWidth < 370;
                      final boardSize = math
                          .min(box.maxWidth - 20, box.maxHeight * 0.72)
                          .clamp(260.0, box.maxWidth - 20)
                          .toDouble();
                      final topGap = narrow ? 12.0 : 18.0;
                      final panelWidth =
                          math.min(box.maxWidth - 44, boardSize * 0.72);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _MatchmakingTopBar(
                            state: state,
                            onCancel: () => _cancel(context, state),
                          ),
                          SizedBox(height: topGap),
                          SizedBox(
                            width: boardSize,
                            height: boardSize,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned.fill(
                                  child: LudoBoard(
                                    snapshot: null,
                                    mySeat: null,
                                    onPieceTap: (_) {},
                                    showWaitingOverlay: false,
                                  ),
                                ),
                                Positioned(
                                  bottom: boardSize * 0.39,
                                  child: _WaitingPanel(
                                    width: panelWidth,
                                    pulse: _pulse,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          _MatchmakingStatus(state: state, pulse: _pulse),
                          const Spacer(),
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

  void _cancel(BuildContext context, AppState state) {
    state.cancelMatchmaking();
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }
}

class _MatchmakingTopBar extends StatelessWidget {
  final AppState state;
  final VoidCallback onCancel;

  const _MatchmakingTopBar({
    required this.state,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: const BoxDecoration(
        color: Color(0x5520002D),
        border: Border(bottom: BorderSide(color: Color(0x22FFD426))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onCancel,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.menu_rounded,
                  color: Colors.white70, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              state.statusText.isNotEmpty
                  ? state.statusText
                  : 'Searching for match...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: goldColor,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    color: Colors.black87,
                    blurRadius: 3,
                    offset: Offset(1, 2),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingPanel extends StatelessWidget {
  final double width;
  final Animation<double> pulse;

  const _WaitingPanel({required this.width, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final glow = (85 + pulse.value * 75).round();
        return Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xF0182C3E), Color(0xF00B2A2B)],
            ),
            border: Border.all(color: goldColor.withAlpha(230), width: 2),
            boxShadow: [
              BoxShadow(
                color: goldColor.withAlpha(glow),
                blurRadius: 16,
                spreadRadius: 1,
              ),
              const BoxShadow(
                color: Color(0x99000000),
                blurRadius: 12,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Waiting for match',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: goldColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                      color: Colors.black87,
                      blurRadius: 3,
                      offset: Offset(1, 3),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Setting up your game...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFFFD7FF).withAlpha(220),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MatchmakingStatus extends StatelessWidget {
  final AppState state;
  final Animation<double> pulse;

  const _MatchmakingStatus({required this.state, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final mode =
        state.pendingMatchMode.contains('4p') ? '4 Player' : '2 Player';
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        return Container(
          width: math.min(MediaQuery.sizeOf(context).width - 44, 430),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: const Color(0xAA2A0735),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x55FFD426)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.lerp(goldColor, Colors.white, pulse.value * 0.22)!,
                  ),
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${state.matchmakingRegion.toUpperCase()} table',
                      style: const TextStyle(
                        color: Color(0xCCFFECA8),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _PulsingDots(pulse: pulse),
            ],
          ),
        );
      },
    );
  }
}

class _PulsingDots extends StatelessWidget {
  final Animation<double> pulse;

  const _PulsingDots({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final phase = (pulse.value + i * 0.22) % 1.0;
        final alpha = (90 + math.sin(phase * math.pi) * 150).round();
        return Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: goldColor.withAlpha(alpha),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _MatchmakingBgPainter extends CustomPainter {
  final double t;

  const _MatchmakingBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    final rect = Offset.zero & size;
    p.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF21002E), Color(0xFF310038), Color(0xFF13001E)],
    ).createShader(rect);
    canvas.drawRect(rect, p);
    p.shader = null;

    for (int i = 0; i < 42; i++) {
      final x = ((i * 61.0) + t * 38) % size.width;
      final y = ((i * 97.0) + t * 24) % size.height;
      final r = 1.0 + (i % 3) * 0.55;
      p.color = Color.fromARGB(34 + (i % 4) * 12, 255, 212, 38);
      canvas.drawCircle(Offset(x, y), r, p);
    }

    p.shader = RadialGradient(
      colors: const [Color(0x55FF2BC2), Color(0x0013001E)],
      radius: 0.62 + t * 0.08,
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.50, size.height * 0.16),
      radius: size.width * 0.76,
    ));
    canvas.drawRect(rect, p);
    p.shader = null;
  }

  @override
  bool shouldRepaint(_MatchmakingBgPainter oldDelegate) => oldDelegate.t != t;
}
