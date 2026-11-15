import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:uuid/uuid.dart';

import '../state/app_state.dart';
import 'app_platform_service.dart';

class PurchaseService extends ChangeNotifier {
  PurchaseService._();

  static final PurchaseService instance = PurchaseService._();

  static const productIds = <String>{
    'dice.ruby',
    'dice.cosmic',
    'board.neon',
    'avatar.premium_cosmic_empress',
    'avatar.premium_gold_champion',
    'avatar.premium_neon_heroine',
    'avatar.premium_emerald_prince',
    'coins.stack_1200',
    'coins.chest_3500',
    'coins.vault_7500',
  };

  static const consumableProductIds = <String>{
    'coins.stack_1200',
    'coins.chest_3500',
    'coins.vault_7500',
  };

  final InAppPurchase _store = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  AppState? _appState;
  Map<String, ProductDetails> _products = const {};
  bool _initialized = false;
  bool _loading = true;
  bool _available = false;
  bool _restoring = false;
  String? _activeProductId;
  String _statusMessage = '';

  bool get available => _available;
  bool get loading => _loading;
  bool get restoring => _restoring;
  String? get activeProductId => _activeProductId;
  String get statusMessage => _statusMessage;

  Future<void> initialize(AppState appState) async {
    _appState = appState;
    if (_initialized) return;
    _initialized = true;
    _subscription = _store.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error) {
        _activeProductId = null;
        _statusMessage =
            '${AppPlatformService.storeName} checkout could not be reached.';
        notifyListeners();
      },
    );
    await refreshProducts();
  }

  Future<void> refreshProducts() async {
    _loading = true;
    notifyListeners();
    try {
      _available = await _store.isAvailable();
      if (!_available) {
        _products = const {};
        _statusMessage =
            '${AppPlatformService.storeName} purchases are unavailable on this device.';
        return;
      }
      final response = await _store.queryProductDetails(productIds);
      _products = {
        for (final product in response.productDetails) product.id: product,
      };
      if (response.error != null) {
        _statusMessage = response.error!.message;
      } else if (response.notFoundIDs.isNotEmpty) {
        _statusMessage =
            'Some shop items are still being activated in ${AppPlatformService.storeName}.';
      } else {
        _statusMessage = '';
      }
    } catch (_) {
      _available = false;
      _products = const {};
      _statusMessage =
          '${AppPlatformService.storeName} purchases could not be loaded.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String displayPrice(String productId, String fallback) =>
      _products[productId]?.price ?? fallback;

  Future<String> buy(String productId) async {
    if (_activeProductId != null || _restoring) {
      return 'Finish the current ${AppPlatformService.storeName} purchase first.';
    }
    // Acquire this before any await, including product refresh and sign-in.
    _activeProductId = productId;
    _statusMessage =
        'Preparing secure ${AppPlatformService.storeName} checkout…';
    notifyListeners();
    try {
      if (!_available) await refreshProducts();
      final product = _products[productId];
      if (product == null) {
        return _checkoutFailed(
          'This item is still being activated in ${AppPlatformService.storeName}.',
        );
      }
      final account = await _appState?.prepareStorePurchase();
      if (account == null) {
        return _checkoutFailed(
          'Your player account is still connecting. Please try again.',
        );
      }
      _statusMessage =
          'Opening secure ${AppPlatformService.storeName} checkout…';
      notifyListeners();
      final purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: _accountName(account),
      );
      final launched = consumableProductIds.contains(productId)
          ? await _store.buyConsumable(
              purchaseParam: purchaseParam,
              autoConsume: AppPlatformService.isIOS,
            )
          : await _store.buyNonConsumable(purchaseParam: purchaseParam);
      if (!launched) {
        return _checkoutFailed(
          '${AppPlatformService.storeName} checkout did not open.',
        );
      }
      return 'Complete your purchase in ${AppPlatformService.storeName}.';
    } catch (_) {
      return _checkoutFailed(
        '${AppPlatformService.storeName} checkout could not be opened.',
      );
    }
  }

  String _checkoutFailed(String message) {
    _activeProductId = null;
    _statusMessage = message;
    notifyListeners();
    return message;
  }

  Future<String> restorePurchases() async {
    if (!_available || _restoring) {
      return '${AppPlatformService.storeName} purchases are unavailable right now.';
    }
    _restoring = true;
    _statusMessage = 'Restoring ${AppPlatformService.storeName} purchases…';
    notifyListeners();
    try {
      await _store.restorePurchases(
        applicationUserName: _accountName(_appState?.playerId),
      );
      _statusMessage =
          'Restore request sent to ${AppPlatformService.storeName}.';
      return _statusMessage;
    } catch (_) {
      _statusMessage =
          '${AppPlatformService.storeName} purchases could not be restored.';
      return _statusMessage;
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _activeProductId = purchase.productID;
          _statusMessage =
              'Waiting for ${AppPlatformService.storeName} to finish the purchase…';
          notifyListeners();
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndDeliver(purchase);
          break;
        case PurchaseStatus.error:
          _activeProductId = null;
          _statusMessage = purchase.error?.message ?? 'Purchase failed.';
          notifyListeners();
          break;
        case PurchaseStatus.canceled:
          _activeProductId = null;
          _statusMessage = 'Purchase cancelled.';
          notifyListeners();
          break;
      }
    }
  }

  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    final state = _appState;
    if (state == null || !productIds.contains(purchase.productID)) return;
    final token = purchase.verificationData.serverVerificationData.trim();
    if (token.isEmpty) {
      _activeProductId = null;
      _statusMessage =
          '${AppPlatformService.storeName} returned an invalid purchase token.';
      notifyListeners();
      return;
    }

    _activeProductId = purchase.productID;
    _statusMessage = 'Verifying purchase securely…';
    notifyListeners();
    final error = AppPlatformService.isIOS
        ? await state.verifyAppStorePurchase(
            productId: purchase.productID,
            signedTransaction: token,
          )
        : await state.verifyGooglePlayPurchase(
            productId: purchase.productID,
            purchaseToken: token,
          );
    if (error.isNotEmpty) {
      _statusMessage = error;
      _activeProductId = null;
      notifyListeners();
      return;
    }

    // Apple transactions, including consumables, must be finished only after
    // the server has granted them. Google coin tokens are consumed server-side.
    if ((AppPlatformService.isIOS ||
            !consumableProductIds.contains(purchase.productID)) &&
        purchase.pendingCompletePurchase) {
      try {
        await _store.completePurchase(purchase);
      } catch (_) {
        // The server has already delivered this transaction idempotently.
        // StoreKit retains an unfinished transaction for the next app session.
        _activeProductId = null;
        _statusMessage =
            'Items delivered. ${AppPlatformService.storeName} confirmation is pending.';
        notifyListeners();
        return;
      }
    }
    _activeProductId = null;
    _statusMessage = consumableProductIds.contains(purchase.productID)
        ? 'Coins added to your balance.'
        : 'Purchase restored and ready to equip.';
    notifyListeners();
  }

  String? _accountName(String? playerId) {
    if (playerId == null || playerId.isEmpty) return null;
    return AppPlatformService.isIOS
        ? const Uuid().v5(Namespace.url.value, playerId)
        : playerId;
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
