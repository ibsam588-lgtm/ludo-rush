import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dice_widget.dart';

void showLiveItemPreview(BuildContext context,
    {required String title,
    required Widget preview,
    required String description,
    required String actionLabel,
    VoidCallback? onAction}) {
  showDialog<void>(
      context: context,
      builder: (context) => Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(title,
                                  style:
                                      Theme.of(context).textTheme.titleLarge)),
                          IconButton(
                              tooltip: 'Close preview',
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close))
                        ]),
                        const Text('LIVE PREVIEW', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        AspectRatio(
                            aspectRatio: 1,
                            child: RepaintBoundary(child: preview)),
                        const SizedBox(height: 12),
                        Text(description, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                            onPressed: onAction == null
                                ? null
                                : () {
                                    Navigator.pop(context);
                                    onAction();
                                  },
                            child:
                                Text(actionLabel, textAlign: TextAlign.center)),
                      ])),
            ),
          ));
}

class LiveDicePreview extends StatefulWidget {
  final String skin;
  const LiveDicePreview({super.key, required this.skin});
  @override
  State<LiveDicePreview> createState() => _LiveDicePreviewState();
}

class _LiveDicePreviewState extends State<LiveDicePreview> {
  final _dice = GlobalKey<DiceWidgetState>();
  Timer? _timer;
  int _value = 1;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1700), (_) {
      if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
      _value = _value % 6 + 1;
      _dice.currentState?.startRoll(_value, () {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
      child: DiceWidget(key: _dice, value: 6, skin: widget.skin, size: 140));
}

class PreviewMotion extends StatefulWidget {
  final Widget child;
  const PreviewMotion({super.key, required this.child});
  @override
  State<PreviewMotion> createState() => _PreviewMotionState();
}

class _PreviewMotionState extends State<PreviewMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat();
  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _motion,
      child: widget.child,
      builder: (context, child) {
        final t = MediaQuery.disableAnimationsOf(context)
            ? 0.0
            : math.sin(_motion.value * math.pi * 2);
        return Transform.translate(
            offset: Offset(0, t * 6),
            child: Transform.rotate(angle: t * 0.04, child: child));
      });
}
