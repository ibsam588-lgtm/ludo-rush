import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/profile_catalog.dart';

class ProfileAvatarView extends StatefulWidget {
  final int preset;
  final bool animate;
  final int celebration;
  final String? imagePath;
  const ProfileAvatarView(
      {super.key,
      required this.preset,
      this.animate = false,
      this.celebration = 0,
      this.imagePath});
  @override
  State<ProfileAvatarView> createState() => _ProfileAvatarViewState();
}

class _ProfileAvatarViewState extends State<ProfileAvatarView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));
  @override
  void initState() {
    super.initState();
    if (widget.animate) _motion.repeat();
  }

  @override
  void didUpdateWidget(ProfileAvatarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      widget.animate ? _motion.repeat() : _motion.reset();
    }
    if (!widget.animate && widget.celebration > oldWidget.celebration)
      _motion.forward(from: 0);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatar = avatarForPreset(widget.preset);
    final path = widget.imagePath;
    Widget portrait;
    if (path != null && File(path).existsSync()) {
      portrait = Image.file(File(path), fit: BoxFit.cover);
    } else if (avatar.emoji != null) {
      final color = Colors.primaries[widget.preset % Colors.primaries.length];
      portrait = Container(
          decoration: BoxDecoration(
              gradient:
                  RadialGradient(colors: [color.shade200, color.shade800])),
          padding: const EdgeInsets.all(10),
          child: FittedBox(child: Text(avatar.emoji!)));
    } else {
      portrait = LayoutBuilder(builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        return ClipRect(
            child: OverflowBox(
                alignment: Alignment.topLeft,
                maxWidth: size * 2,
                maxHeight: size * 2,
                child: Transform.translate(
                    offset: Offset(-(avatar.atlasIndex % 2) * size,
                        -(avatar.atlasIndex ~/ 2) * size),
                    child: Image.asset(avatar.asset,
                        width: size * 2, height: size * 2, fit: BoxFit.fill))));
      });
    }
    return Semantics(
        label: '${avatar.label} avatar',
        child: AnimatedBuilder(
            animation: _motion,
            child: ClipOval(child: portrait),
            builder: (context, child) {
              final t =
                  MediaQuery.disableAnimationsOf(context) ? 0.0 : _motion.value;
              return Transform.rotate(
                  angle: math.sin(t * math.pi * 4) * 0.10,
                  child: Transform.scale(
                      scale: 1 + math.sin(t * math.pi) * 0.08, child: child));
            }));
  }
}
