import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/ludo_strings.dart';
import 'state/app_state.dart';
import 'services/levelplay_ad_service.dart';
import 'services/prefs_service.dart';
import 'services/purchase_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/matchmaking_screen.dart';
import 'screens/game_screen.dart';
import 'screens/results_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/history_screen.dart';
import 'widgets/forced_update_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LudoStrings.instance.watchDeviceLocale();
  // Android 15+ draws behind system bars. Keep the surfaces transparent so
  // SafeArea can protect interactive content on phones, tablets and foldables.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  final prefs = PrefsService();
  await prefs.init();

  final appState = AppState(prefs);
  unawaited(
    appState.init().then((_) async {
      await Future.wait([
        LevelPlayAdService.instance.initialize(userId: appState.playerId),
        PurchaseService.instance.initialize(appState),
      ]);
    }),
  );

  runApp(
    ChangeNotifierProvider.value(value: appState, child: const LudoRushApp()),
  );
  unawaited(LudoStrings.instance.load());
}

class LudoRushApp extends StatelessWidget {
  const LudoRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => MaterialApp(
        title: 'Ludo Rush',
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
          Locale('bn'),
          Locale('bg'),
          Locale('ca'),
          Locale('zh', 'CN'),
          Locale('hr'),
          Locale('cs'),
          Locale('da'),
          Locale('nl'),
          Locale('et'),
          Locale('fi'),
          Locale('fr'),
          Locale('de'),
          Locale('el'),
          Locale('gu'),
          Locale('he'),
          Locale('hi'),
          Locale('hu'),
          Locale('is'),
          Locale('id'),
          Locale('it'),
          Locale('ja'),
          Locale('kn'),
          Locale('ko'),
          Locale('lv'),
          Locale('lt'),
          Locale('ml'),
          Locale('mr'),
          Locale('no'),
          Locale('fa'),
          Locale('pl'),
          Locale('pt'),
          Locale('pa'),
          Locale('ro'),
          Locale('ru'),
          Locale('sk'),
          Locale('sl'),
          Locale('es'),
          Locale('sw'),
          Locale('sv'),
          Locale('ta'),
          Locale('te'),
          Locale('th'),
          Locale('tr'),
          Locale('uk'),
          Locale('ur'),
          Locale('vi'),
          Locale('zu'),
        ],
        debugShowCheckedModeBanner: false,
        navigatorKey: state.navigatorKey,
        scaffoldMessengerKey: state.scaffoldMessengerKey,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return LudoStringsScope(
            notifier: LudoStrings.instance,
            child: MediaQuery(
              data: media.copyWith(
                disableAnimations:
                    media.disableAnimations || state.reducedMotionEnabled,
                highContrast: media.highContrast || state.highContrastEnabled,
                textScaler: state.largeTextEnabled
                    ? const TextScaler.linear(1.12)
                    : media.textScaler,
              ),
              child: ForcedUpdateGate(child: child ?? const SizedBox.shrink()),
            ),
          );
        },
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/home': (_) => const HomeScreen(),
          '/': (_) => const HomeScreen(),
          '/matchmaking': (_) => const MatchmakingScreen(),
          '/game': (_) => const GameScreen(),
          '/results': (_) => const ResultsScreen(),
          '/shop': (_) => const ShopScreen(),
          '/history': (_) => const HistoryScreen(),
        },
      ),
    );
  }
}
