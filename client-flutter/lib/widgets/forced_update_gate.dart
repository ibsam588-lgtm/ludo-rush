import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class ForcedUpdateGate extends StatefulWidget {
  final Widget child;

  const ForcedUpdateGate({super.key, required this.child});

  @override
  State<ForcedUpdateGate> createState() => _ForcedUpdateGateState();
}

class _ForcedUpdateGateState extends State<ForcedUpdateGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppState>().checkForForcedUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final mustBlock =
            state.forceUpdateRequired || !state.updateCheckComplete;
        if (!mustBlock) {
          return widget.child;
        }
        final verifying = !state.forceUpdateRequired;
        return PopScope(
          canPop: false,
          child: Material(
            color: bgDeep,
            child: Stack(
              children: [
                const Positioned.fill(child: _ForcedUpdateBackdrop()),
                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF751071),
                                Color(0xFF33073F),
                                Color(0xFF12031B),
                              ],
                            ),
                            border: Border.all(color: goldColor, width: 2.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xDD000000),
                                blurRadius: 28,
                                offset: Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _UpdateIcon(verifying: verifying),
                                const SizedBox(height: 18),
                                Text(
                                  verifying
                                      ? (state.updateCheckFailed
                                          ? 'Connection Required'
                                          : 'Checking Update')
                                      : 'Update Required',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: goldColor,
                                    fontSize: 31,
                                    height: 0.95,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black87,
                                        blurRadius: 6,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  verifying
                                      ? (state.updateCheckFailed
                                          ? 'Ludo Rush must verify your app version before you can play. Connect to the internet and try again.'
                                          : 'Verifying that you are on the latest Play Store build.')
                                      : state.forceUpdateMessage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(230),
                                    fontSize: 16,
                                    height: 1.25,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                if (!verifying) _VersionLine(state: state),
                                if (!verifying) const SizedBox(height: 22),
                                if (!verifying)
                                  _UpdateButton(
                                    label: 'Update on Play Store',
                                    icon: Icons.system_update_alt_rounded,
                                    color: greenBtn,
                                    onTap: state.openForcedUpdateStore,
                                  ),
                                if (!verifying) const SizedBox(height: 12),
                                if (verifying && state.updateCheckInProgress)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 18),
                                    child: CircularProgressIndicator(
                                      color: goldColor,
                                      strokeWidth: 4,
                                    ),
                                  ),
                                _UpdateButton(
                                  label: state.updateCheckInProgress
                                      ? 'Checking...'
                                      : (verifying
                                          ? 'Try Again'
                                          : 'Check Again'),
                                  icon: Icons.refresh_rounded,
                                  color: boardPurple,
                                  onTap: state.updateCheckInProgress
                                      ? null
                                      : () => state.checkForForcedUpdate(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
}

class _VersionLine extends StatelessWidget {
  final AppState state;

  const _VersionLine({required this.state});

  @override
  Widget build(BuildContext context) {
    final installed = state.installedVersionName.isEmpty
        ? 'Installed build ${state.installedBuildNumber}'
        : 'Installed ${state.installedVersionName}+${state.installedBuildNumber}';
    final required = state.latestAvailableVersionName.isEmpty
        ? 'Required build ${state.minimumRequiredBuildNumber}'
        : 'Required ${state.latestAvailableVersionName}+${state.minimumRequiredBuildNumber}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0x77230631),
        border: Border.all(color: const Color(0x55FFD426)),
      ),
      child: Text(
        '$installed\n$required',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withAlpha(215),
          fontSize: 13,
          height: 1.25,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _UpdateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _UpdateButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.65 : 1,
        child: Container(
          height: 54,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(color, Colors.white, 0.25)!,
                color,
                Color.lerp(color, Colors.black, 0.12)!,
              ],
            ),
            border: Border.all(color: goldColor, width: 1.6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000000),
                blurRadius: 9,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 23),
              const SizedBox(width: 9),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 3)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpdateIcon extends StatelessWidget {
  final bool verifying;

  const _UpdateIcon({required this.verifying});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFFFF6A8), Color(0xFFFFB300), Color(0xFFFF5F00)],
        ),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0xBBFFD426), blurRadius: 22),
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        verifying ? Icons.verified_rounded : Icons.system_update_rounded,
        color: const Color(0xFF3A073E),
        size: 52,
      ),
    );
  }
}

class _ForcedUpdateBackdrop extends StatelessWidget {
  const _ForcedUpdateBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF180020),
            Color(0xFF350044),
            Color(0xFF07000E),
          ],
        ),
      ),
      child: CustomPaint(painter: _ForcedUpdatePatternPainter()),
    );
  }
}

class _ForcedUpdatePatternPainter extends CustomPainter {
  const _ForcedUpdatePatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    p.color = const Color(0x20FFD426);
    for (var i = 0; i < 10; i++) {
      final x = size.width * ((i * 37) % 100) / 100;
      final y = size.height * ((i * 61) % 100) / 100;
      canvas.drawCircle(Offset(x, y), 2 + (i % 4) * 1.2, p);
    }

    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x18FFD426);
    for (var i = 0; i < 6; i++) {
      final y = size.height * (0.16 + i * 0.14);
      canvas.drawLine(Offset(-20, y), Offset(size.width + 20, y + 60), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
