import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ludo_rush/services/prefs_service.dart';
import 'package:ludo_rush/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('ludo_rush/app');
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  for (final environment in ['Production', 'Sandbox']) {
    test('$environment uses only its own update destination', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getVersionInfo') {
              return {'versionName': '1.0.0', 'buildNumber': 1901};
            }
            if (call.method == 'storeAccountContext') {
              return {
                'environment': environment,
                'signedAppTransaction': 'signed-proof',
              };
            }
            return null;
          });
      final state = AppState(PrefsService());
      addTearDown(state.dispose);
      var lookups = 0;
      await http.runWithClient(
        () async {
          expect(await state.prepareStorePurchase(), 'purchasing-player');
          await state.checkForForcedUpdate();
        },
        () => MockClient((request) async {
          if (request.url.host == 'itunes.apple.com') {
            lookups++;
            return http.Response(
              jsonEncode({
                'results': [
                  {
                    'trackId': 6834993861,
                    'bundleId': 'com.corsairlabs.ludocheer',
                    'version': '1.1.0',
                  },
                ],
              }),
              200,
            );
          }
          if (request.url.path == '/api/v1/app/config') {
            return http.Response(
              jsonEncode({
                'minimumBuildNumber': 1901,
                'latestBuildNumber': 1901,
                'latestVersionName': '1.0.0',
                'forceUpdate': false,
                'updateUrl': environment == 'Sandbox'
                    ? 'https://apps.apple.com/app/testflight/id899247664'
                    : 'https://apps.apple.com/app/id6834993861',
              }),
              200,
            );
          }
          if (request.url.path == '/api/v1/auth/session') {
            return http.Response(
              jsonEncode({'playerId': 'purchasing-player'}),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'token': 'account-session',
              'player': {'id': 'purchasing-player', 'coins': 2200, 'age': 25},
            }),
            200,
          );
        }),
      );
      expect(state.updateCheckComplete, isTrue);
      expect(state.forceUpdateRequired, environment == 'Production');
      expect(state.forceUpdateByStoreVersion, environment == 'Production');
      expect(
        state.forceUpdateStoreName,
        environment == 'Production' ? 'App Store' : 'TestFlight',
      );
      expect(lookups, environment == 'Production' ? 1 : 0);
    });
  }
}
