import 'dart:math' as math;
import 'package:flutter/material.dart';

class SixCelebration extends StatefulWidget {
  final int sequence;
  const SixCelebration({super.key, required this.sequence});
  @override
  State<SixCelebration> createState() => _SixCelebrationState();
}

class _SixCelebrationState extends State<SixCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));
  @override
  void didUpdateWidget(SixCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sequence > oldWidget.sequence) _burst.forward(from: 0);
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
          child: AnimatedBuilder(
        animation: _burst,
        builder: (context, _) {
          if (!_burst.isAnimating) return const SizedBox.shrink();
          final reduced = MediaQuery.disableAnimationsOf(context);
          final t = _burst.value;
          return Center(
              child: Opacity(
            opacity: t > .75 ? (1 - t) * 4 : 1,
            child: SizedBox(
                width: 240,
                height: 200,
                child: Stack(alignment: Alignment.center, children: [
                  if (!reduced)
                    for (var i = 0; i < 10; i++)
                      Transform.translate(
                          offset: Offset(math.cos(i * math.pi / 5) * 100 * t,
                              math.sin(i * math.pi / 5) * 80 * t),
                          child: Text(i.isEven ? '✨' : '🎉',
                              style: const TextStyle(fontSize: 24))),
                  Transform.scale(
                      scale: reduced
                          ? 1
                          : 0.7 +
                              math.sin(math.min(t * 2, 1) * math.pi / 2) * .3,
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                              color: const Color(0xEF35124D),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: const Color(0xFFFFD86A), width: 2)),
                          child: const Text('🎲 SIX!',
                              style: TextStyle(
                                  color: Color(0xFFFFD86A),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900)))),
                ])),
          ));
        },
      ));
}
