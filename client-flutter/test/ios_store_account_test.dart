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
    test(
      '$environment checkout recovers the original account in its own economy',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              expect(call.method, 'storeAccountContext');
              return {
                'environment': environment,
                'signedAppTransaction': 'apple-signed-account-proof',
              };
            });
        final state = AppState(PrefsService());
        addTearDown(state.dispose);
        final hosts = <String>[];
        var recoveries = 0;
        final account = await http.runWithClient(
          () => state.prepareStorePurchase(),
          () => MockClient((request) async {
            hosts.add(request.url.host);
            if (request.url.path == '/api/v1/auth/guest') {
              return http.Response(
                jsonEncode({
                  'token': 'new-guest-session',
                  'player': {'id': 'new-guest', 'coins': 500},
                }),
                201,
              );
            }
            if (request.url.path == '/api/v1/auth/app-store') {
              recoveries++;
              expect(
                jsonDecode(request.body)['signedAppTransaction'],
                'apple-signed-account-proof',
              );
              return http.Response(
                jsonEncode({
                  'token': 'recovered-session',
                  'player': {
                    'id': 'purchasing-player',
                    'coins': 4300,
                    'age': 25,
                  },
                }),
                200,
              );
            }
            if (request.url.path == '/api/v1/auth/session') {
              expect(
                request.headers['authorization'],
                'Bearer recovered-session',
              );
              return http.Response(
                jsonEncode({'playerId': 'purchasing-player'}),
                200,
              );
            }
            return http.Response('{}', 200);
          }),
        );
        expect(account, 'purchasing-player');
        expect(state.authToken, 'recovered-session');
        expect(recoveries, greaterThanOrEqualTo(1));
        expect(hosts.toSet(), {
          environment == 'Sandbox'
              ? 'ludo-cheer-ios-beta.ibsam588.workers.dev'
              : 'ludo-rush-backend.ibsam588.workers.dev',
        });
      },
    );
  }

  test('checkout stops when the App Store cannot verify its account', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => throw PlatformException(code: 'unverified'),
        );
    final state = AppState(PrefsService());
    addTearDown(state.dispose);
    var requests = 0;
    final account = await http.runWithClient(
      () => state.prepareStorePurchase(),
      () => MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );
    expect(account, isNull);
    expect(requests, 0);
  });
}
