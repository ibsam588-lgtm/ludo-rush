import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/levelplay_ad_config.dart';
import '../state/app_state.dart';
import '../models/game_snapshot.dart';
import '../services/app_platform_service.dart';
import '../services/levelplay_ad_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/levelplay_banner.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/match_style.dart';
import '../models/match_moment.dart';
import '../models/match_rewards.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  RESULTS SCREEN — Celebratory match end screen
// ═══════════════════════════════════════════════════════════════════════════════

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _confettiCtrl;
  late final AnimationController _entryCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _shimmerCtrl;

  late final Animation<double> _entryScale;
  late final Animation<double> _entryFade;
  bool _rewardInFlight = false;
  bool _rewardClaimed = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _entryScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut),
    );
    _entryFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _entryCtrl,
          curve: const Interval(0, 0.4, curve: Curves.easeOut)),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _entryCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(LevelPlayAdService.instance.showAfterCompletedRound());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      for (final controller in [
        _confettiCtrl,
        _glowCtrl,
        _shimmerCtrl,
        _entryCtrl
      ]) {
        controller.stop();
        controller.value = 1;
      }
    } else if (_reduceMotion) {
      _glowCtrl.repeat(reverse: true);
      _shimmerCtrl.repeat(reverse: true);
    }
    _reduceMotion = reduced;
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _entryCtrl.dispose();
    _glowCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final snapshot = state.lastSnapshot;
    final myId = state.playerId;
    final replayMode = snapshot?.mode ?? state.pendingMatchMode;
    final replayOffline = state.currentMatchIsBot;

    bool won = false;
    String winnerName = 'Unknown';
    int? winnerSeat;
    final palette = MatchPalette.forTheme(
        replayMode == AppState.snakesLaddersMode
            ? state.snakesBoardTheme
            : state.ludoBoardTheme);
    if (snapshot != null) {
      won = myId != null && myId == snapshot.winnerPlayerId;
      for (final s in snapshot.seats) {
        if (s.playerId == snapshot.winnerPlayerId) {
          winnerName = state.publicSeatName(s);
          winnerSeat = s.seat;
          break;
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const SafeArea(
        top: false,
        child: LevelPlayBannerAd(placementName: 'ResultsBanner'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred dark backdrop
          MatchBackdrop(palette: palette),

          // Confetti (winner only)
          if (won && !_reduceMotion)
            AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, __) => CustomPaint(
                painter: _ConfettiPainter(_confettiCtrl.value),
              ),
            ),

          // Floating glow orbs
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ResultGlowPainter(_glowCtrl.value, won),
            ),
          ),

          // Modal card
          Center(
            child: FadeTransition(
              opacity: _entryFade,
              child: ScaleTransition(
                scale: _entryScale,
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.background.withAlpha(245),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: won
                            ? const Color(0xAAFFD426)
                            : const Color(0x55FFFFFF),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: won
                              ? const Color(0x44FFD426)
                              : const Color(0x22FFFFFF),
                          blurRadius: 32,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Trophy / result icon
                        _WinnerPortrait(
                            preset: won
                                ? state.avatarPreset
                                : 12 + (winnerSeat ?? 0),
                            imagePath: won ? state.avatarImagePath : null,
                            name: won ? 'You' : winnerName),
                        const SizedBox(height: 16),

                        // Result headline
                        _ResultHeadline(
                            won: won, winnerName: winnerName, state: state),
                        const SizedBox(height: 18),

                        // Rewards row
                        _RewardsRow(state: state),
                        const SizedBox(height: 10),
                        _RewardedBonusButton(
                          inFlight: _rewardInFlight,
                          claimed: _rewardClaimed,
                          onPressed: () => _claimLevelCompleteReward(state),
                        ),
                        const SizedBox(height: 14),

                        // Player list
                        if (snapshot != null)
                          _PlayerList(
                              snapshot: snapshot, myId: myId, state: state),

                        const SizedBox(height: 18),

                        // Action buttons
                        _ActionBtn(
                          label: won ? 'Play Again' : 'Try Again',
                          colors: [
                            const Color(0xFF43A047),
                            const Color(0xFF1B5E20)
                          ],
                          onTap: () {
                            Navigator.of(context).popUntil((r) => r.isFirst);
                            if (replayOffline) {
                              state.startOfflineMatch(replayMode);
                            } else {
                              state.startQuickMatch(replayMode);
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        _ActionBtn(
                          label: 'Back to Lobby',
                          colors: [
                            const Color(0xFF0288D1),
                            const Color(0xFF01579B)
                          ],
                          onTap: () {
                            Navigator.of(context).popUntil((r) => r.isFirst);
                          },
                        ),
                        const SizedBox(height: 10),
                        _ActionBtn(
                          label: 'Share Result',
                          colors: [
                            const Color(0xFF8E24AA),
                            const Color(0xFF4A148C)
                          ],
                          onTap: () async {
                            SoundService.tap();
                            final text = won
                                ? 'I won a Ludo Rush match with a ${state.rating} rating! Play Ludo Rush: https://play.google.com/store/apps/details?id=com.ludorush.game'
                                : '$winnerName won our Ludo Rush match. Play Ludo Rush: https://play.google.com/store/apps/details?id=com.ludorush.game';
                            final shared =
                                await AppPlatformService.shareText(text);
                            if (!context.mounted || shared) return;
                            ScaffoldMessenger.of(context)
                              ..clearSnackBars()
                              ..showSnackBar(
                                const SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(
                                    'Result copied. Paste it into any app to share.',
                                  ),
                                ),
                              );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _claimLevelCompleteReward(AppState state) async {
    if (_rewardInFlight || _rewardClaimed) return;
    setState(() => _rewardInFlight = true);
    final earned = await LevelPlayAdService.instance.showRewarded(
      placementName: 'LevelCompleteBonus',
    );
    if (!mounted) return;

    if (earned) {
      state.grantRewardedLevelComplete(
        points: LevelPlayAdConfig.levelCompleteRewardPoints,
        energyAmount: LevelPlayAdConfig.levelCompleteRewardEnergy,
      );
      _rewardClaimed = true;
    }
    setState(() => _rewardInFlight = false);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            earned
                ? '+${LevelPlayAdConfig.levelCompleteRewardPoints} points and +${LevelPlayAdConfig.levelCompleteRewardEnergy} energy added.'
                : 'Reward video is loading. Try again shortly.',
          ),
        ),
      );
  }
}

class _RewardedBonusButton extends StatelessWidget {
  final bool inFlight;
  final bool claimed;
  final VoidCallback onPressed;

  const _RewardedBonusButton({
    required this.inFlight,
    required this.claimed,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = claimed
        ? 'Bonus claimed'
        : inFlight
            ? 'Loading video...'
            : 'Watch video: +${LevelPlayAdConfig.levelCompleteRewardPoints} points +${LevelPlayAdConfig.levelCompleteRewardEnergy} energy';
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: claimed || inFlight ? null : onPressed,
        icon: Icon(claimed ? Icons.check_rounded : Icons.play_circle_fill),
        label: Text(label, textAlign: TextAlign.center),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6A1B9A),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.white12,
          disabledForegroundColor: Colors.white54,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

// ── Trophy badge ─────────────────────────────────────────────────────────────

class _WinnerPortrait extends StatelessWidget {
  final int preset;
  final String? imagePath;
  final String name;
  const _WinnerPortrait(
      {required this.preset, required this.imagePath, required this.name});
  @override
  Widget build(BuildContext context) => Semantics(
      label: '$name, match winner',
      child: SizedBox(
          width: 128,
          height: 134,
          child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                    width: 108,
                    height: 108,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFFEBB5), Color(0xFFB07832)]),
                        boxShadow: [
                          BoxShadow(
                              color: goldColor.withAlpha(60),
                              blurRadius: 26,
                              spreadRadius: 2),
                          const BoxShadow(
                              color: Colors.black38,
                              blurRadius: 14,
                              offset: Offset(0, 8))
                        ]),
                    child: ProfileAvatarView(
                        preset: preset,
                        imagePath: imagePath,
                        celebration: 1,
                        mood: AvatarMood.winner)),
                const Positioned(
                    top: -5, child: Text('👑', style: TextStyle(fontSize: 36))),
              ])));
}

class _ResultHeadline extends StatelessWidget {
  final bool won;
  final String winnerName;
  final AppState state;
  const _ResultHeadline(
      {required this.won, required this.winnerName, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: won
                  ? [const Color(0xFFFF6B35), const Color(0xFFE53935)]
                  : [const Color(0xFF455A64), const Color(0xFF263238)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            won ? 'VICTORY!' : 'BETTER LUCK NEXT TIME',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          won
              ? '${state.displayName} wins the match!'
              : '$winnerName won the match',
          style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Rewards row ──────────────────────────────────────────────────────────────

class _RewardsRow extends StatelessWidget {
  final AppState state;
  const _RewardsRow({required this.state});
  @override
  Widget build(BuildContext context) {
    final reward = state.lastMatchRewards ??
        (state.currentMatchIsBot || state.localMatchActive
            ? const MatchRewards(coins: 0, rating: 0, practice: true)
            : null);
    String delta(int value) => value > 0 ? '+$value' : '$value';
    return Container(
      key: const ValueKey('match-reward-receipt'),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: goldColor.withAlpha(60))),
      child: Column(children: [
        const Text('MATCH REWARDS',
            style: TextStyle(
                color: Colors.white70, fontSize: 11, letterSpacing: 1.8)),
        const SizedBox(height: 12),
        if (reward == null)
          const Text('Rewards pending', style: TextStyle(color: Colors.white70))
        else ...[
          Row(children: [
            _RewardItem(
                icon: Icons.monetization_on_rounded,
                label: 'COINS',
                value: delta(reward.coins),
                color: goldColor),
            _Divider(),
            _RewardItem(
                icon: Icons.emoji_events_rounded,
                label: 'RATING',
                value: delta(reward.rating),
                color: reward.rating < 0 ? boardRed : boardGreen),
          ]),
          if (reward.practice)
            const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Practice match · no coins or rating changes',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 12))),
        ],
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: Colors.white12);
}

class _RewardItem extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _RewardItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: color.withAlpha(120), blurRadius: 6)],
              )),
          Text(label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              )),
        ],
      ),
    );
  }
}

// ── Player list ──────────────────────────────────────────────────────────────

class _PlayerList extends StatelessWidget {
  final GameSnapshot snapshot;
  final String? myId;
  final AppState state;

  const _PlayerList({
    required this.snapshot,
    required this.myId,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final seats = [...snapshot.seats]..sort((a, b) {
        if (a.playerId == snapshot.winnerPlayerId) return -1;
        if (b.playerId == snapshot.winnerPlayerId) return 1;
        return a.seat.compareTo(b.seat);
      });
    return Column(
      children: seats.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;
        final isWinner = s.playerId == snapshot.winnerPlayerId;
        final isMe = s.playerId == myId;
        final color = AppColors.seatColor(s.seat);
        final publicName = state.publicSeatName(s);

        return Container(
          margin:
              EdgeInsets.only(bottom: i < snapshot.seats.length - 1 ? 6 : 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color:
                isWinner ? goldColor.withAlpha(20) : Colors.white.withAlpha(6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isWinner ? goldColor.withAlpha(80) : Colors.white12,
              width: isWinner ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Seat dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: color.withAlpha(120), blurRadius: 4)
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Name
              Expanded(
                child: Text(
                  isMe ? 'You' : publicName,
                  style: TextStyle(
                    color: isWinner ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),

              // Badge
              if (isWinner)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: goldColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: goldColor.withAlpha(100)),
                  ),
                  child: const Text('Winner',
                      style: TextStyle(
                        color: goldColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      )),
                )
              else
                const Text('-',
                    style: TextStyle(color: Colors.white24, fontSize: 13)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Action button ────────────────────────────────────────────────────────────

class _ActionBtn extends StatefulWidget {
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label, required this.colors, required this.onTap});

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        SoundService.tap();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.colors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: widget.colors.first.withAlpha(80),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(widget.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
                shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
              )),
        ),
      ),
    );
  }
}

// ── Confetti painter ─────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter(this.t);

  static const _colors = [
    goldColor,
    boardRed,
    boardGreen,
    boardBlue,
    boardYellow,
    Color(0xFFE040FB),
    Color(0xFF00E5FF),
    Colors.white,
    Colors.pink,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    final p = Paint();
    for (int i = 0; i < 80; i++) {
      final baseX = ((i * 137 + 11) % 1000) / 1000.0 * size.width;
      final y = (t * 1.45 - (i % 10) * .035) * (size.height + 30) - 15;
      final x = baseX + math.sin(t * 5 + i * 0.4) * 22;

      p.color = _colors[i % _colors.length].withAlpha(
          ((180 + (i % 3) * 25) * ((1 - t) * 4).clamp(0, 1)).round());

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 4 + i * 0.6);

      // Alternate shapes
      if (i % 3 == 0) {
        // Square
        canvas.drawRect(Rect.fromLTWH(-4, -4, 8, 5), p);
      } else if (i % 3 == 1) {
        // Circle
        canvas.drawCircle(Offset.zero, 4, p);
      } else {
        // Diamond
        final path = Path()
          ..moveTo(0, -5)
          ..lineTo(4, 0)
          ..lineTo(0, 5)
          ..lineTo(-4, 0)
          ..close();
        canvas.drawPath(path, p);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

// ── Result background glow ───────────────────────────────────────────────────

class _ResultGlowPainter extends CustomPainter {
  final double t;
  final bool won;
  _ResultGlowPainter(this.t, this.won);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    final pulse = 0.5 + 0.5 * math.sin(t * math.pi * 2);

    // Top glow
    p.shader = ui.Gradient.radial(
      Offset(size.width * 0.5, 0),
      size.width * 0.6,
      [
        (won ? goldColor : Colors.white).withAlpha((pulse * 25).round()),
        Colors.transparent,
      ],
    );
    canvas.drawRect(Offset.zero & size, p);

    // Bottom glow
    p.shader = ui.Gradient.radial(
      Offset(size.width * 0.5, size.height),
      size.width * 0.5,
      [
        (won ? const Color(0xFFFF6B35) : Colors.blue)
            .withAlpha((pulse * 20).round()),
        Colors.transparent,
      ],
    );
    canvas.drawRect(Offset.zero & size, p);
    p.shader = null;
  }

  @override
  bool shouldRepaint(_ResultGlowPainter old) => old.t != t;
}
