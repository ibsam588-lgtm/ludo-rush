import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:ludo_rush/services/prefs_service.dart';
import 'package:ludo_rush/services/purchase_service.dart';
import 'package:ludo_rush/state/app_state.dart';

class CheckoutState extends AppState {
  CheckoutState() : super(PrefsService());
  Future<String?> account = Future.value(null);
  int deliveries = 0;
  @override
  Future<String?> prepareStorePurchase() => account;
  @override
  Future<String> verifyAppStorePurchase({
    required String productId,
    required String signedTransaction,
  }) async {
    deliveries++;
    return '';
  }
}

class CheckoutStore extends InAppPurchasePlatform {
  final events = StreamController<List<PurchaseDetails>>.broadcast();
  final checkouts = <PurchaseParam>[];
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => events.stream;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async => ProductDetailsResponse(
    productDetails: [
      ProductDetails(
        id: 'dice.ruby',
        title: 'Ruby Dice',
        description: 'Ruby Dice',
        price: r'$0.99',
        rawPrice: 0.99,
        currencyCode: 'USD',
      ),
    ],
    notFoundIDs: const [],
  );
  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    checkouts.add(purchaseParam);
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    throw StateError('StoreKit is temporarily busy');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'checkout waits for the authenticated account instead of a temporary ID',
    () async {
      final state = AppState(PrefsService())..playerId = 'local_startup';
      addTearDown(state.dispose);
      final signIn = Completer<http.Response>();
      final paths = <String>[];
      final pending = http.runWithClient(
        () => state.prepareStorePurchase(),
        () => MockClient((request) {
          paths.add(request.url.path);
          if (request.url.path.endsWith('/guest')) return signIn.future;
          expect(request.url.path, '/api/v1/auth/session');
          expect(request.headers['authorization'], 'Bearer ready-token');
          return Future.value(
            http.Response(jsonEncode({'playerId': 'player_remote'}), 200),
          );
        }),
      );
      var completed = false;
      unawaited(pending.then((_) => completed = true));
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      signIn.complete(
        http.Response(
          jsonEncode({
            'token': 'ready-token',
            'player': {
              'id': 'player_remote',
              'displayName': 'James',
              'rating': 1000,
              'coins': 500,
            },
          }),
          201,
        ),
      );
      expect(await pending, 'player_remote');
      expect(state.playerId, 'player_remote');
      expect(paths, ['/api/v1/auth/guest', '/api/v1/auth/session']);
    },
  );

  test('checkout is unavailable when guest authentication fails', () async {
    final state = AppState(PrefsService())..playerId = 'local_offline';
    addTearDown(state.dispose);
    final account = await http.runWithClient(
      () => state.prepareStorePurchase(),
      () => MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/guest');
        return http.Response('{}', 503);
      }),
    );
    expect(account, isNull);
  });

  for (final problem in [
    'different account',
    'expired session',
    'unreachable server',
  ]) {
    test('checkout refuses $problem before any store charge', () async {
      final state = AppState(PrefsService())
        ..playerId = 'player_remote'
        ..authToken = 'cached-token';
      addTearDown(state.dispose);
      final account = await http.runWithClient(
        () => state.prepareStorePurchase(),
        () => MockClient((request) async {
          expect(request.url.path, '/api/v1/auth/session');
          if (problem == 'unreachable server')
            throw http.ClientException('offline');
          if (problem == 'expired session') return http.Response('{}', 401);
          return http.Response(jsonEncode({'playerId': 'someone_else'}), 200);
        }),
      );
      expect(account, isNull);
    });
  }

  test(
    'checkout locks early, never buys for an unverified account, and binds Apple identity',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final store = CheckoutStore();
      InAppPurchasePlatform.instance = store;
      final state = CheckoutState();
      final service = PurchaseService.instance;
      await service.initialize(state);
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final identity = Completer<String?>();
      state.account = identity.future;
      final first = service.buy('dice.ruby');
      expect(service.activeProductId, 'dice.ruby');
      expect(await service.buy('dice.ruby'), contains('Finish the current'));
      expect(store.checkouts, isEmpty);
      identity.complete(null);
      expect(await first, contains('player account'));
      expect(store.checkouts, isEmpty);
      expect(service.activeProductId, isNull);

      state.account = Future.value('player_remote');
      expect(
        await service.buy('dice.ruby'),
        contains('Complete your purchase'),
      );
      expect(store.checkouts, hasLength(1));
      expect(
        store.checkouts.single.applicationUserName,
        'b6dc4652-fccb-5655-adfe-af4e7bea3b28',
      );
      final purchased = PurchaseDetails(
        purchaseID: 'transaction-1',
        productID: 'dice.ruby',
        transactionDate: '1',
        status: PurchaseStatus.purchased,
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: 'signed-apple-transaction',
          source: 'app_store',
        ),
      )..pendingCompletePurchase = true;
      store.events.add([purchased]);
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(state.deliveries, 1);
      expect(service.activeProductId, isNull);
      expect(service.statusMessage, contains('Items delivered'));
      expect(service.statusMessage, contains('confirmation is pending'));
      service.dispose();
      state.dispose();
      await store.events.close();
    },
  );
}
