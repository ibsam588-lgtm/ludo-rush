import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rush/services/purchase_service.dart';

void main() {
  test('Google Play product catalog is complete and internally consistent', () {
    expect(PurchaseService.productIds, hasLength(10));
    expect(PurchaseService.consumableProductIds, {
      'coins.stack_1200',
      'coins.chest_3500',
      'coins.vault_7500',
    });
    expect(
      PurchaseService.productIds.containsAll(
        PurchaseService.consumableProductIds,
      ),
      isTrue,
    );
    expect(
      PurchaseService.productIds.every(
        (productId) => RegExp(r'^[a-z0-9._]+$').hasMatch(productId),
      ),
      isTrue,
    );
  });
}
