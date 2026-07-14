import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'services/prefs_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/matchmaking_screen.dart';
import 'screens/game_screen.dart';
import 'screens/results_screen.dart';
import 'screens/shop_screen.dart';
import 'widgets/forced_update_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = PrefsService();
  await prefs.init();

  final appState = AppState(prefs);
  unawaited(appState.init());

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const LudoRushApp(),
    ),
  );
}

class LudoRushApp extends StatelessWidget {
  const LudoRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => MaterialApp(
        title: 'Ludo Rush',
        debugShowCheckedModeBanner: false,
        navigatorKey: state.navigatorKey,
        scaffoldMessengerKey: state.scaffoldMessengerKey,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        builder: (context, child) => ForcedUpdateGate(
          child: child ?? const SizedBox.shrink(),
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/home': (_) => const HomeScreen(),
          '/': (_) => const HomeScreen(),
          '/matchmaking': (_) => const MatchmakingScreen(),
          '/game': (_) => const GameScreen(),
          '/results': (_) => const ResultsScreen(),
          '/shop': (_) => const ShopScreen(),
        },
      ),
    );
  }
}
