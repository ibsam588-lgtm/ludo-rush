import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300))
      ..repeat(reverse: true);
    _shimmer =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final p = _RushPalette.fromDark(state.isDarkMode);
        return Scaffold(
          backgroundColor: p.bg,
          body: Stack(
            children: [
              Positioned.fill(
                child: _GeneratedLobbyBackground(palette: p),
              ),
              Positioned.fill(
                child: SafeArea(
                  child: Column(
                    children: [
                      _TopHud(state: state, palette: p, shimmer: _shimmer),
                      _RewardStrip(palette: p),
                      Expanded(
                        child: Stack(
                          children: [
                            _LobbyStage(
                                state: state, palette: p, pulse: _pulse),
                          ],
                        ),
                      ),
                      _BottomNav(palette: p, activeIndex: 2),
                    ],
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

class _RushPalette {
  final bool dark;
  final Color bg;
  final Color bg2;
  final Color panel;
  final Color panel2;
  final Color stroke;
  final Color text;
  final Color muted;
  final Color gold;
  final Color shadow;

  const _RushPalette({
    required this.dark,
    required this.bg,
    required this.bg2,
    required this.panel,
    required this.panel2,
    required this.stroke,
    required this.text,
    required this.muted,
    required this.gold,
    required this.shadow,
  });

  factory _RushPalette.fromDark(bool dark) {
    if (dark) {
      return const _RushPalette(
        dark: true,
        bg: Color(0xFF1A0324),
        bg2: Color(0xFF8A176D),
        panel: Color(0xE12A0734),
        panel2: Color(0xFF5B145B),
        stroke: Color(0xFFFFD426),
        text: Colors.white,
        muted: Color(0xFFD7C3E0),
        gold: goldColor,
        shadow: Color(0x99000000),
      );
    }
    return const _RushPalette(
      dark: false,
      bg: Color(0xFFFFE7F7),
      bg2: Color(0xFFFFB5D9),
      panel: Color(0xF7FFFFFF),
      panel2: Color(0xFFFFD7F0),
      stroke: Color(0xFFE38A00),
      text: Color(0xFF2B1232),
      muted: Color(0xFF6E446D),
      gold: Color(0xFFFFB300),
      shadow: Color(0x33000000),
    );
  }
}

class _GeneratedLobbyBackground extends StatelessWidget {
  final _RushPalette palette;

  const _GeneratedLobbyBackground({required this.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final safe = MediaQuery.paddingOf(context);
        final width = box.maxWidth;
        final height = box.maxHeight;
        final aspect = box.maxHeight / math.max(1, box.maxWidth);
        final topChrome = safe.top + (width < 370 ? 154.0 : 166.0);
        final bottomChrome = safe.bottom + 94.0;
        final stageReserve = width < 370
            ? (aspect > 1.9 ? 218.0 : 204.0)
            : (aspect > 2.05 ? 270.0 : 246.0);
        final stageTop = topChrome;
        final stageBottom =
            math.max(stageTop, height - bottomChrome - stageReserve);
        final stageHeight = math.max(0.0, stageBottom - stageTop);
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/home_ludo_backdrop.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.high,
            ),
            Positioned.fill(
              child: ColoredBox(
                color: palette.dark
                    ? const Color(0xAA080015)
                    : const Color(0x55FFFFFF),
              ),
            ),
            Positioned(
              top: stageTop,
              left: 0,
              right: 0,
              height: stageHeight,
              child: IgnorePointer(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/home_ludo_board_window.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: palette.dark
                              ? const [
                                  Color(0x33050019),
                                  Color(0x00050019),
                                  Color(0x11050019),
                                  Color(0x66050019),
                                ]
                              : const [
                                  Color(0x22FFFFFF),
                                  Color(0x00FFFFFF),
                                  Color(0x22FFFFFF),
                                  Color(0x66FFE8F7),
                                ],
                          stops: const [0, 0.28, 0.72, 1],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: palette.dark
                      ? const [
                          Color(0x66050019),
                          Color(0x11050019),
                          Color(0x00050019),
                          Color(0x77050019),
                        ]
                      : const [
                          Color(0x33FFFFFF),
                          Color(0x11FFFFFF),
                          Color(0x00FFFFFF),
                          Color(0x55FFFFFF),
                        ],
                  stops: const [0, 0.28, 0.58, 1],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0.92),
                  radius: 0.95,
                  colors: palette.dark
                      ? const [Color(0x00FF2BC2), Color(0x99100022)]
                      : const [Color(0x00FFFFFF), Color(0x99FFE0F4)],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopHud extends StatelessWidget {
  final AppState state;
  final _RushPalette palette;
  final AnimationController shimmer;

  const _TopHud({
    required this.state,
    required this.palette,
    required this.shimmer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: palette.dark
              ? const [Color(0xFF78145E), Color(0xFF301145)]
              : const [Color(0xFFFFFFFF), Color(0xFFFFD4F0)],
        ),
        border: Border.all(color: palette.stroke, width: 2),
        boxShadow: [
          BoxShadow(
              color: palette.shadow, blurRadius: 14, offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                SoundService.tap();
                _showProfileEditor(context, state, palette);
              },
              child: Row(
                children: [
                  _AvatarBadge(
                      name: state.displayName,
                      level: (state.rating ~/ 90 + 1).clamp(1, 99),
                      preset: state.avatarPreset,
                      imagePath: state.avatarImagePath),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _cleanName(state.displayName),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: palette.text,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  shadows: palette.dark
                                      ? const [
                                          Shadow(
                                              color: Colors.black54,
                                              blurRadius: 4)
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            _CountryMiniBadge(
                                code: state.countryCode, palette: palette),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.emoji_events_rounded,
                                color: palette.gold, size: 15),
                            const SizedBox(width: 4),
                            Text(
                              '${state.rating}',
                              style: TextStyle(
                                  color: palette.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            flex: 5,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CurrencyPill(
                        icon: Icons.bolt_rounded,
                        value: '${state.wins}',
                        color: const Color(0xFF9EA5B5),
                        palette: palette),
                    const SizedBox(width: 3),
                    _CurrencyPill(
                        icon: Icons.monetization_on_rounded,
                        value: _fmt(state.coins),
                        color: amberColor,
                        palette: palette),
                    const SizedBox(width: 3),
                    _CurrencyPill(
                        icon: Icons.diamond_rounded,
                        value: '30',
                        color: const Color(0xFF21D972),
                        palette: palette),
                    const SizedBox(width: 3),
                    _ThemeToggle(state: state, palette: palette),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
  static String _cleanName(String s) =>
      s.trim().isEmpty || s == 'Ludo Player' ? 'Ibsam' : s.trim();
}

class _AvatarBadge extends StatelessWidget {
  final String name;
  final int level;
  final int preset;
  final String? imagePath;

  const _AvatarBadge({
    required this.name,
    required this.level,
    required this.preset,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'I' : name.trim()[0].toUpperCase();
    final path = imagePath;
    final hasImage = path != null && File(path).existsSync();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(
                colors: [goldColor, amberColor, boardRed, goldColor]),
            border: Border.all(color: const Color(0xFFFFF3A8), width: 2),
            boxShadow: const [
              BoxShadow(
                  color: Color(0xAA000000), blurRadius: 8, offset: Offset(0, 3))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: ClipOval(
              child: hasImage
                  ? Image.file(File(path), fit: BoxFit.cover)
                  : CustomPaint(painter: _AvatarPainter(initial, preset)),
            ),
          ),
        ),
        Positioned(
          right: -4,
          bottom: -3,
          child: Container(
            width: 25,
            height: 25,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE39A00),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text('$level',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }
}

class _CountryMiniBadge extends StatelessWidget {
  final String code;
  final _RushPalette palette;

  const _CountryMiniBadge({required this.code, required this.palette});

  @override
  Widget build(BuildContext context) {
    final country = _countryFor(code);
    return Container(
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: palette.dark ? const Color(0x66100020) : Colors.white70,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.stroke.withAlpha(180), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MiniFlag(country: country, width: 12, height: 8),
          const SizedBox(width: 3),
          Text(
            country.code,
            style: TextStyle(
              color: palette.text,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountrySpec {
  final String code;
  final String name;
  final List<Color> colors;

  const _CountrySpec(this.code, this.name, this.colors);
}

const _countries = [
  _CountrySpec('US', 'United States',
      [Color(0xFFB22234), Colors.white, Color(0xFF3C3B6E)]),
  _CountrySpec(
      'IN', 'India', [Color(0xFFFF9933), Colors.white, Color(0xFF138808)]),
  _CountrySpec(
      'PK', 'Pakistan', [Color(0xFF01411C), Colors.white, Color(0xFF01411C)]),
  _CountrySpec('GB', 'United Kingdom',
      [Color(0xFF012169), Colors.white, Color(0xFFC8102E)]),
  _CountrySpec(
      'CA', 'Canada', [Color(0xFFFF0000), Colors.white, Color(0xFFFF0000)]),
  _CountrySpec('AE', 'United Arab Emirates',
      [Color(0xFF00732F), Colors.white, Color(0xFF000000)]),
  _CountrySpec('SA', 'Saudi Arabia',
      [Color(0xFF006C35), Colors.white, Color(0xFF006C35)]),
  _CountrySpec(
      'AU', 'Australia', [Color(0xFF00008B), Colors.white, Color(0xFFE4002B)]),
  _CountrySpec('BD', 'Bangladesh',
      [Color(0xFF006A4E), Color(0xFFF42A41), Color(0xFF006A4E)]),
  _CountrySpec('DE', 'Germany',
      [Color(0xFF000000), Color(0xFFDD0000), Color(0xFFFFCE00)]),
];

_CountrySpec _countryFor(String code) {
  final normalized = code.trim().toUpperCase();
  return _countries.firstWhere(
    (c) => c.code == normalized,
    orElse: () => _countries.first,
  );
}

class _MiniFlag extends StatelessWidget {
  final _CountrySpec country;
  final double width;
  final double height;

  const _MiniFlag({
    required this.country,
    this.width = 26,
    this.height = 17,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height * 0.18),
      child: SizedBox(
        width: width,
        height: height,
        child: Row(
          children: [
            for (final color in country.colors)
              Expanded(child: Container(color: color)),
          ],
        ),
      ),
    );
  }
}

Future<void> _showProfileEditor(
    BuildContext context, AppState state, _RushPalette palette) async {
  final nameController =
      TextEditingController(text: _TopHud._cleanName(state.displayName));
  var selectedCountry = state.countryCode;
  var selectedAvatar = state.avatarPreset;
  var selectedImagePath = state.avatarImagePath;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final selected = _countryFor(selectedCountry);
          final bottom = MediaQuery.of(context).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 10, bottom + 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: palette.dark
                      ? const [Color(0xFF4A0B58), Color(0xFF18041F)]
                      : const [Color(0xFFFFFFFF), Color(0xFFFFD7F2)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(color: palette.stroke, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x99000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ProfileAvatarPreview(
                          name: nameController.text,
                          preset: selectedAvatar,
                          imagePath: selectedImagePath,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit profile',
                                style: TextStyle(
                                  color: palette.text,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  _MiniFlag(country: selected),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      '${selected.name} (${selected.code})',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: palette.muted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameController,
                      maxLength: 18,
                      onChanged: (_) => setSheetState(() {}),
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w900,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: 'Player name',
                        labelStyle: TextStyle(color: palette.muted),
                        filled: true,
                        fillColor: palette.dark
                            ? const Color(0x66250A31)
                            : const Color(0xFFFFF4FC),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: palette.stroke.withAlpha(130)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: palette.stroke, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SheetLabel('Country', palette: palette),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final country in _countries)
                          _CountryChoice(
                            country: country,
                            selected: country.code == selectedCountry,
                            palette: palette,
                            onTap: () => setSheetState(
                                () => selectedCountry = country.code),
                          ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _SheetLabel('Avatar', palette: palette),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 58,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 8,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) => GestureDetector(
                          onTap: () => setSheetState(() {
                            selectedAvatar = i;
                            selectedImagePath = null;
                          }),
                          child: Container(
                            width: 54,
                            height: 54,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedAvatar == i &&
                                        selectedImagePath == null
                                    ? palette.stroke
                                    : Colors.white24,
                                width: selectedAvatar == i &&
                                        selectedImagePath == null
                                    ? 3
                                    : 1,
                              ),
                            ),
                            child: CustomPaint(
                              painter: _AvatarPainter(
                                  nameController.text.trim().isEmpty
                                      ? 'I'
                                      : nameController.text
                                          .trim()[0]
                                          .toUpperCase(),
                                  i),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ProfileButton(
                            label: 'Upload avatar',
                            icon: Icons.photo_library_rounded,
                            palette: palette,
                            filled: false,
                            onTap: () async {
                              final picked = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 86,
                                maxWidth: 512,
                                maxHeight: 512,
                              );
                              if (picked != null) {
                                setSheetState(
                                    () => selectedImagePath = picked.path);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ProfileButton(
                            label: 'Save',
                            icon: Icons.check_rounded,
                            palette: palette,
                            filled: true,
                            onTap: () {
                              state.updateProfile(
                                name: nameController.text,
                                country: selectedCountry,
                                avatar: selectedAvatar,
                                imagePath: selectedImagePath,
                                clearImage: selectedImagePath == null,
                              );
                              Navigator.pop(sheetContext);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
  nameController.dispose();
}

class _ProfileAvatarPreview extends StatelessWidget {
  final String name;
  final int preset;
  final String? imagePath;

  const _ProfileAvatarPreview({
    required this.name,
    required this.preset,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'I' : name.trim()[0].toUpperCase();
    final path = imagePath;
    final hasImage = path != null && File(path).existsSync();
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
            colors: [goldColor, amberColor, boardBlue, boardRed, goldColor]),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 12)],
      ),
      child: ClipOval(
        child: hasImage
            ? Image.file(File(path), fit: BoxFit.cover)
            : CustomPaint(painter: _AvatarPainter(initial, preset)),
      ),
    );
  }
}

class _CountryChoice extends StatelessWidget {
  final _CountrySpec country;
  final bool selected;
  final _RushPalette palette;
  final VoidCallback onTap;

  const _CountryChoice({
    required this.country,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 105,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: selected
              ? palette.stroke.withAlpha(palette.dark ? 50 : 85)
              : (palette.dark ? const Color(0x55200A2D) : Colors.white70),
          border: Border.all(
              color: selected ? palette.stroke : Colors.white24,
              width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            _MiniFlag(country: country),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                country.code,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  final _RushPalette palette;

  const _SheetLabel(this.text, {required this.palette});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: palette.text,
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final _RushPalette palette;
  final bool filled;
  final VoidCallback onTap;

  const _ProfileButton({
    required this.label,
    required this.icon,
    required this.palette,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: filled
              ? const LinearGradient(
                  colors: [Color(0xFFFFD426), Color(0xFFFF8F00)])
              : null,
          color: filled
              ? null
              : (palette.dark ? const Color(0x66250A31) : Colors.white),
          border: Border.all(color: palette.stroke, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: filled ? const Color(0xFF3D1600) : palette.text,
                size: 18),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: filled ? const Color(0xFF3D1600) : palette.text,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  final _RushPalette palette;

  const _CurrencyPill({
    required this.icon,
    required this.value,
    required this.color,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      constraints: const BoxConstraints(minWidth: 48),
      padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
      decoration: BoxDecoration(
        color: palette.dark ? const Color(0xAA21072C) : Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
            color: palette.dark ? Colors.white24 : const Color(0x22000000)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [Color.lerp(color, Colors.white, 0.35)!, color]),
              boxShadow: [BoxShadow(color: color.withAlpha(90), blurRadius: 6)],
            ),
            child: Icon(icon, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  color: palette.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final AppState state;
  final _RushPalette palette;

  const _ThemeToggle({required this.state, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: state.isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
      child: GestureDetector(
        onTap: state.toggleDarkMode,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: state.isDarkMode
                  ? const [Color(0xFF2D126A), Color(0xFF09021A)]
                  : const [Color(0xFFFFF4A3), Color(0xFFFFAF21)],
            ),
            border: Border.all(color: palette.stroke, width: 1.5),
            boxShadow: [BoxShadow(color: palette.shadow, blurRadius: 7)],
          ),
          child: Icon(
            state.isDarkMode
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _RewardStrip extends StatelessWidget {
  final _RushPalette palette;

  const _RewardStrip({required this.palette});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          const SizedBox(width: 10),
          _SideRewardButton(palette: palette),
          const SizedBox(width: 10),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _RewardTile(
                    palette: palette,
                    level: 'Level 4',
                    icon: Icons.shield_rounded),
                _RewardTile(
                    palette: palette,
                    level: 'Level 5',
                    icon: Icons.workspace_premium_rounded),
                _RewardTile(
                    palette: palette,
                    level: 'Locked',
                    icon: Icons.groups_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideRewardButton extends StatelessWidget {
  final _RushPalette palette;

  const _SideRewardButton({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.stroke, width: 1.5),
        boxShadow: [BoxShadow(color: palette.shadow, blurRadius: 8)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_arrow_rounded, color: palette.gold, size: 24),
          Text('Free',
              style: TextStyle(
                  color: palette.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  final _RushPalette palette;
  final String level;
  final IconData icon;

  const _RewardTile({
    required this.palette,
    required this.level,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      margin: const EdgeInsets.only(right: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
            colors: palette.dark
                ? const [Color(0xFF9A3B8B), Color(0xFF49144E)]
                : const [Color(0xFFFFF0FD), Color(0xFFFFC1E6)]),
        border: Border.all(
            color: palette.dark
                ? const Color(0x77FFD426)
                : const Color(0x66D66D00)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: palette.gold, size: 24),
          const SizedBox(height: 7),
          Text(
            level,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.text,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LobbyStage extends StatelessWidget {
  final AppState state;
  final _RushPalette palette;
  final AnimationController pulse;

  const _LobbyStage({
    required this.state,
    required this.palette,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 370;
        final compact = box.maxHeight < 500;
        final rowGap = compact ? 8.0 : 12.0;
        final bottomGap = compact ? 5.0 : 8.0;
        final baseBigHeight = (box.maxWidth * (narrow ? 0.31 : 0.34))
            .clamp(104.0, 138.0)
            .toDouble();
        final baseSmallHeight = (box.maxWidth * (narrow ? 0.22 : 0.24))
            .clamp(76.0, 98.0)
            .toDouble();
        final needed = baseBigHeight + rowGap + baseSmallHeight + bottomGap;
        final scale =
            math.min(1.0, math.max(0.82, (box.maxHeight - 8) / needed));
        final bigHeight = baseBigHeight * scale;
        final smallHeight = baseSmallHeight * scale;
        final sidePadding = narrow ? 10.0 : 14.0;
        final largeGap = narrow ? 8.0 : 12.0;
        final smallGap = narrow ? 6.0 : 8.0;
        return Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 0),
                child: Column(
                  children: [
                    const Spacer(),
                    SizedBox(
                      height: bigHeight,
                      child: Row(
                        children: [
                          Expanded(
                            child: _ModeTile(
                              palette: palette,
                              pulse: pulse,
                              large: true,
                              label: '2 Player',
                              headline: '2',
                              subtitle: 'Classic duel',
                              start: const Color(0xFFFFC22D),
                              end: const Color(0xFFE47B00),
                              art: _ModeArt.duel,
                              onTap: () => state.startQuickMatch('classic_2p'),
                            ),
                          ),
                          SizedBox(width: largeGap),
                          Expanded(
                            child: _ModeTile(
                              palette: palette,
                              pulse: pulse,
                              large: true,
                              label: '4 Player',
                              headline: '4',
                              subtitle: 'Full table',
                              start: const Color(0xFF8E72FF),
                              end: const Color(0xFF5531BB),
                              art: _ModeArt.four,
                              onTap: () => state.startQuickMatch('classic_4p'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: rowGap),
                    SizedBox(
                      height: smallHeight,
                      child: Row(
                        children: [
                          Expanded(
                            child: _ModeTile(
                              palette: palette,
                              pulse: pulse,
                              label: 'Private',
                              headline: '',
                              subtitle: 'Invite',
                              start: const Color(0xFF8A5CFF),
                              end: const Color(0xFF5130AC),
                              art: _ModeArt.private,
                              onTap: () => _soon(context, 'Private rooms'),
                            ),
                          ),
                          SizedBox(width: smallGap),
                          Expanded(
                            child: _ModeTile(
                              palette: palette,
                              pulse: pulse,
                              label: 'Team Up',
                              headline: '',
                              subtitle: 'Online',
                              start: const Color(0xFFE948B6),
                              end: const Color(0xFF8D1B8E),
                              art: _ModeArt.team,
                              onTap: () => state.startQuickMatch('classic_4p'),
                            ),
                          ),
                          SizedBox(width: smallGap),
                          Expanded(
                            child: _ModeTile(
                              palette: palette,
                              pulse: pulse,
                              label: 'Quick Match',
                              headline: '',
                              subtitle: 'Online',
                              start: const Color(0xFF53C4FF),
                              end: const Color(0xFF1658C9),
                              art: _ModeArt.quick,
                              onTap: () => state.startQuickMatch('classic_2p'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: bottomGap),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void _soon(BuildContext context, String name) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xEE22082E),
            duration: const Duration(milliseconds: 1400),
            content: Text(
                '$name will be enabled after backend room invites are live.')),
      );
  }
}

enum _ModeArt { duel, four, private, team, quick }

class _ModeTile extends StatefulWidget {
  final _RushPalette palette;
  final AnimationController pulse;
  final bool large;
  final String label;
  final String headline;
  final String subtitle;
  final Color start;
  final Color end;
  final _ModeArt art;
  final VoidCallback onTap;

  const _ModeTile({
    required this.palette,
    required this.pulse,
    required this.label,
    required this.headline,
    required this.subtitle,
    required this.start,
    required this.end,
    required this.art,
    required this.onTap,
    this.large = false,
  });

  @override
  State<_ModeTile> createState() => _ModeTileState();
}

class _ModeTileState extends State<_ModeTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 100),
        lowerBound: 0,
        upperBound: 1);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapCancel: _press.reverse,
      onTapUp: (_) {
        _press.reverse();
        SoundService.tap();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_press, widget.pulse]),
        builder: (context, _) {
          final scale = 1 - _press.value * 0.045;
          final glow = 0.45 + widget.pulse.value * 0.55;
          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.large ? 18 : 14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [widget.start, widget.end],
                ),
                border: Border.all(
                    color: widget.palette.stroke,
                    width: widget.large ? 2.4 : 1.6),
                boxShadow: [
                  BoxShadow(
                      color: widget.start.withAlpha((85 * glow).round()),
                      blurRadius: widget.large ? 18 : 12,
                      offset: const Offset(0, 5)),
                  const BoxShadow(
                      color: Color(0x77000000),
                      blurRadius: 5,
                      offset: Offset(0, 3)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.large ? 16 : 12),
                child: Stack(
                  children: [
                    Positioned.fill(
                        child: CustomPaint(
                            painter: _ModePatternPainter(widget.palette.dark))),
                    Positioned(
                      left: widget.large ? 6 : 0,
                      top: widget.large ? 6 : 6,
                      width: widget.large ? 104 : 62,
                      height: widget.large ? 96 : 56,
                      child: CustomPaint(painter: _ModeArtPainter(widget.art)),
                    ),
                    if (widget.headline.isNotEmpty)
                      Positioned(
                        right: widget.large ? 15 : 10,
                        top: widget.large ? 8 : 11,
                        child: Text(
                          widget.headline,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.large ? 70 : 25,
                            fontWeight: FontWeight.w900,
                            height: 0.9,
                            shadows: const [
                              Shadow(
                                  color: Color(0xCC4A0038),
                                  blurRadius: 0,
                                  offset: Offset(2, 3)),
                              Shadow(
                                  color: Color(0x99000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 4)),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      left: widget.large ? 20 : 62,
                      right: widget.large ? 82 : 8,
                      bottom: widget.large ? 13 : 12,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: widget.large
                                ? FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: _ModeLabelText(
                                      widget.label,
                                      large: true,
                                    ),
                                  )
                                : _ModeLabelText(widget.label),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: Colors.white.withAlpha(210),
                              fontSize: widget.large ? 12 : 11,
                              fontWeight: FontWeight.w800,
                              shadows: const [
                                Shadow(color: Colors.black54, blurRadius: 3)
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ModeLabelText extends StatelessWidget {
  final String text;
  final bool large;

  const _ModeLabelText(this.text, {this.large = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: large ? 1 : 2,
      overflow: large ? TextOverflow.visible : TextOverflow.ellipsis,
      textAlign: TextAlign.left,
      style: TextStyle(
        color: Colors.white,
        fontSize: large ? 22 : 14,
        height: 0.96,
        fontWeight: FontWeight.w900,
        shadows: const [
          Shadow(
            color: Colors.black87,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final _RushPalette palette;
  final int activeIndex;

  const _BottomNav({required this.palette, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavSpec(Icons.shopping_cart_rounded, 'Shop'),
      _NavSpec(Icons.groups_rounded, 'Friends'),
      _NavSpec(Icons.home_rounded, 'Home'),
      _NavSpec(Icons.shield_rounded, 'Clubs'),
      _NavSpec(Icons.inventory_2_rounded, 'Chest'),
    ];
    return Container(
      height: 86,
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: palette.dark
            ? const Color(0xE31D0738)
            : Colors.white.withAlpha(238),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: palette.dark
                ? const Color(0x664F35F0)
                : const Color(0x44E38A00),
            width: 1.5),
        boxShadow: [
          BoxShadow(
              color: palette.shadow,
              blurRadius: 12,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = i == activeIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                SoundService.tap();
                if (i == 0) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  Navigator.pushNamed(context, '/shop');
                } else if (i != 2) {
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xEE22082E),
                      duration: const Duration(milliseconds: 1200),
                      content: Text('${items[i].label} is coming soon.'),
                    ));
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: active
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                            colors: [Color(0xFF9B22F4), Color(0xFF3B087C)]),
                        border: Border.all(color: palette.stroke, width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: palette.gold.withAlpha(95), blurRadius: 12)
                        ],
                      )
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(items[i].icon,
                        color:
                            active ? palette.gold : palette.text.withAlpha(225),
                        size: active ? 31 : 25),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        items[i].label.toUpperCase(),
                        style: TextStyle(
                          color: active
                              ? palette.gold
                              : palette.text.withAlpha(210),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavSpec {
  final IconData icon;
  final String label;
  const _NavSpec(this.icon, this.label);
}

class _ModePatternPainter extends CustomPainter {
  final bool dark;

  _ModePatternPainter(this.dark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withAlpha(dark ? 20 : 45);
    for (double x = -size.height; x < size.width + size.height; x += 22) {
      canvas.drawLine(
          Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
    paint
      ..style = PaintingStyle.fill
      ..color = Colors.white.withAlpha(dark ? 18 : 45);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.16),
        size.width * 0.22, paint);
  }

  @override
  bool shouldRepaint(_ModePatternPainter oldDelegate) =>
      oldDelegate.dark != dark;
}

class _ModeArtPainter extends CustomPainter {
  final _ModeArt art;

  _ModeArtPainter(this.art);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final board = Rect.fromLTWH(size.width * 0.12, size.height * 0.34,
        size.width * 0.66, size.height * 0.52);
    if (art != _ModeArt.private) {
      _drawMiniBoard(canvas, board, p);
    }

    if (art == _ModeArt.duel || art == _ModeArt.team) {
      _drawPawn(canvas, Offset(size.width * 0.31, size.height * 0.56),
          size.shortestSide * 0.20, boardRed, p);
      _drawPawn(canvas, Offset(size.width * 0.58, size.height * 0.56),
          size.shortestSide * 0.20, boardBlue, p);
      if (art == _ModeArt.team) {
        _drawPawn(canvas, Offset(size.width * 0.45, size.height * 0.40),
            size.shortestSide * 0.16, boardYellow, p);
      }
    } else if (art == _ModeArt.four) {
      _drawPawn(canvas, Offset(size.width * 0.30, size.height * 0.45),
          size.shortestSide * 0.16, boardRed, p);
      _drawPawn(canvas, Offset(size.width * 0.57, size.height * 0.45),
          size.shortestSide * 0.16, boardBlue, p);
      _drawPawn(canvas, Offset(size.width * 0.38, size.height * 0.66),
          size.shortestSide * 0.16, boardYellow, p);
      _drawPawn(canvas, Offset(size.width * 0.65, size.height * 0.66),
          size.shortestSide * 0.16, boardGreen, p);
      _drawDice(canvas, Offset(size.width * 0.78, size.height * 0.43),
          size.shortestSide * 0.20, 5, p);
    } else if (art == _ModeArt.private) {
      _drawLock(canvas, Offset(size.width * 0.47, size.height * 0.52),
          size.shortestSide * 0.58, p);
    } else if (art == _ModeArt.quick) {
      _drawPawn(canvas, Offset(size.width * 0.34, size.height * 0.58),
          size.shortestSide * 0.18, boardGreen, p);
      _drawPawn(canvas, Offset(size.width * 0.56, size.height * 0.58),
          size.shortestSide * 0.18, boardBlue, p);
      _drawDice(canvas, Offset(size.width * 0.76, size.height * 0.42),
          size.shortestSide * 0.22, 6, p);
    }
    if (art == _ModeArt.duel) {
      _drawDice(canvas, Offset(size.width * 0.74, size.height * 0.42),
          size.shortestSide * 0.22, 3, p);
    }
  }

  void _drawMiniBoard(Canvas canvas, Rect r, Paint p) {
    p.color = const Color(0xFFFFF4C8);
    canvas.drawRRect(RRect.fromRectXY(r, 7, 7), p);
    p.color = boardRed;
    canvas.drawRect(Rect.fromLTRB(r.left, r.top, r.center.dx, r.center.dy), p);
    p.color = boardYellow;
    canvas.drawRect(Rect.fromLTRB(r.center.dx, r.top, r.right, r.center.dy), p);
    p.color = boardBlue;
    canvas.drawRect(
        Rect.fromLTRB(r.left, r.center.dy, r.center.dx, r.bottom), p);
    p.color = boardGreen;
    canvas.drawRect(
        Rect.fromLTRB(r.center.dx, r.center.dy, r.right, r.bottom), p);
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withAlpha(220);
    canvas.drawRRect(RRect.fromRectXY(r, 7, 7), p);
    p.style = PaintingStyle.fill;
  }

  void _drawPawn(Canvas canvas, Offset c, double s, Color color, Paint p) {
    p.color = Colors.black.withAlpha(100);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(c.dx, c.dy + s * 0.65),
            width: s * 1.3,
            height: s * 0.42),
        p);
    p.shader = ui.Gradient.linear(
        Offset(c.dx - s, c.dy - s),
        Offset(c.dx + s, c.dy + s),
        [Color.lerp(color, Colors.white, 0.24)!, color]);
    canvas.drawCircle(Offset(c.dx, c.dy - s * 0.22), s * 0.48, p);
    canvas.drawRRect(
        RRect.fromRectXY(
            Rect.fromCenter(
                center: Offset(c.dx, c.dy + s * 0.28),
                width: s * 0.68,
                height: s * 0.72),
            s * 0.22,
            s * 0.22),
        p);
    p.shader = null;
    p.color = Colors.white.withAlpha(130);
    canvas.drawCircle(Offset(c.dx - s * 0.17, c.dy - s * 0.38), s * 0.13, p);
  }

  void _drawDice(Canvas canvas, Offset c, double s, int value, Paint p) {
    final r = Rect.fromCenter(center: c, width: s, height: s);
    p.color = Colors.black.withAlpha(105);
    canvas.drawRRect(RRect.fromRectXY(r.shift(const Offset(4, 5)), 8, 8), p);
    p.color = Colors.white;
    canvas.drawRRect(RRect.fromRectXY(r, 8, 8), p);
    p.color = const Color(0xFF241221);
    final dots = <Offset>[
      if (value == 1 || value == 3 || value == 5) c,
      if (value >= 2) Offset(r.left + s * 0.28, r.top + s * 0.28),
      if (value >= 2) Offset(r.right - s * 0.28, r.bottom - s * 0.28),
      if (value >= 4) Offset(r.right - s * 0.28, r.top + s * 0.28),
      if (value >= 4) Offset(r.left + s * 0.28, r.bottom - s * 0.28),
      if (value == 6) Offset(r.left + s * 0.28, c.dy),
      if (value == 6) Offset(r.right - s * 0.28, c.dy),
    ];
    for (final d in dots) {
      canvas.drawCircle(d, s * 0.065, p);
    }
  }

  void _drawLock(Canvas canvas, Offset c, double s, Paint p) {
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.12
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFE36E);
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(c.dx, c.dy - s * 0.10),
            width: s * 0.66,
            height: s * 0.64),
        math.pi,
        math.pi,
        false,
        p);
    p
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.butt;
    p.shader =
        const LinearGradient(colors: [Color(0xFFFFF08D), Color(0xFFE48A00)])
            .createShader(Rect.fromCenter(
                center: Offset(c.dx, c.dy + s * 0.12),
                width: s * 0.74,
                height: s * 0.58));
    canvas.drawRRect(
        RRect.fromRectXY(
            Rect.fromCenter(
                center: Offset(c.dx, c.dy + s * 0.15),
                width: s * 0.74,
                height: s * 0.58),
            s * 0.11,
            s * 0.11),
        p);
    p.shader = null;
    p.color = const Color(0xFF5A2600);
    canvas.drawCircle(Offset(c.dx, c.dy + s * 0.08), s * 0.07, p);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(c.dx, c.dy + s * 0.20),
            width: s * 0.06,
            height: s * 0.19),
        p);
  }

  @override
  bool shouldRepaint(_ModeArtPainter oldDelegate) => oldDelegate.art != art;
}

class _AvatarPainter extends CustomPainter {
  final String initial;
  final int preset;

  _AvatarPainter(this.initial, this.preset);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final c = Offset(size.width / 2, size.height / 2);
    final bg = [
      const Color(0xFF27145C),
      const Color(0xFF0A5D83),
      const Color(0xFF7A1554),
      const Color(0xFF185B2C),
      const Color(0xFF7A3C05),
      const Color(0xFF3B247D),
      const Color(0xFF0C5C55),
      const Color(0xFF8E1C28),
    ][preset.clamp(0, 7)];
    final skin = [
      const Color(0xFFFFBE7D),
      const Color(0xFFFFD19A),
      const Color(0xFFB8744F),
      const Color(0xFFE79A63),
      const Color(0xFFF5C28D),
      const Color(0xFF8B5A3C),
      const Color(0xFFFFCFA8),
      const Color(0xFFD28A64),
    ][preset.clamp(0, 7)];
    final hair = [
      const Color(0xFF321506),
      const Color(0xFF111111),
      const Color(0xFFFFD426),
      const Color(0xFF5B2600),
      const Color(0xFF1D1D1D),
      const Color(0xFF4D2217),
      const Color(0xFFEB4B84),
      const Color(0xFF0D2C74),
    ][preset.clamp(0, 7)];

    p.color = bg;
    canvas.drawCircle(c, size.shortestSide * 0.50, p);
    p.color = skin;
    canvas.drawCircle(
        Offset(c.dx, c.dy + size.height * 0.05), size.shortestSide * 0.30, p);

    p.color = hair;
    if (preset % 3 == 0) {
      for (int i = 0; i < 7; i++) {
        canvas.drawCircle(
            Offset(c.dx - 17 + i * 6, c.dy - 13 - (i % 2) * 2), 7, p);
      }
    } else if (preset % 3 == 1) {
      canvas.drawRRect(
        RRect.fromRectXY(
          Rect.fromCenter(
              center: Offset(c.dx, c.dy - 13),
              width: size.width * 0.58,
              height: size.height * 0.24),
          12,
          12,
        ),
        p,
      );
    } else {
      final cap = Path()
        ..moveTo(c.dx - size.width * 0.30, c.dy - size.height * 0.10)
        ..quadraticBezierTo(c.dx, c.dy - size.height * 0.40,
            c.dx + size.width * 0.32, c.dy - size.height * 0.08)
        ..quadraticBezierTo(c.dx, c.dy - size.height * 0.20,
            c.dx - size.width * 0.30, c.dy - size.height * 0.10)
        ..close();
      canvas.drawPath(cap, p);
    }

    p.color = Colors.white.withAlpha(230);
    canvas.drawCircle(Offset(c.dx - size.width * 0.11, c.dy + 1),
        size.shortestSide * 0.045, p);
    canvas.drawCircle(Offset(c.dx + size.width * 0.11, c.dy + 1),
        size.shortestSide * 0.045, p);

    final tp = TextPainter(
      text: TextSpan(
          text: initial,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2 + 5));
  }

  @override
  bool shouldRepaint(_AvatarPainter oldDelegate) =>
      oldDelegate.initial != initial || oldDelegate.preset != preset;
}
