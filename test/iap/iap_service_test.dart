import 'package:flutter_test/flutter_test.dart';
import 'package:showa_city/domain/game_save.dart';
import 'package:showa_city/iap/iap_service.dart';

void main() {
  test('catalog exposes only consumable and non-consumable products', () {
    expect(IapCatalog.all, hasLength(5));
    expect(IapCatalog.all.any((id) => id.contains('subscription')), isFalse);
  });

  test('successful consumable purchase grants gems once', () async {
    final repository = MockIapRepository(
      nextPurchase: const PurchaseResult(
        PurchaseState.purchased,
        transactionId: 'tx-1',
      ),
    );
    final service = IapService(repository);
    await service.buy(IapCatalog.smallGems);
    await service.buy(IapCatalog.smallGems);
    expect(service.save.gems, 100);
    expect(service.save.processedTransactions, ['tx-1']);
  });

  test(
    'non-consumable purchase grants entitlement without duplicate effect',
    () async {
      final repository = MockIapRepository(
        nextPurchase: const PurchaseResult(
          PurchaseState.purchased,
          transactionId: 'tx-2',
        ),
      );
      final service = IapService(repository, save: const GameSave(gems: 10));
      await service.buy(IapCatalog.permanentBoost);
      await service.buy(IapCatalog.permanentBoost);
      expect(service.save.gems, 10);
      expect(service.save.entitlements, [IapCatalog.permanentBoost]);
    },
  );

  test('pending, cancel, and error do not mutate wallet', () async {
    for (final state in PurchaseState.values.skip(2)) {
      final service = IapService(
        MockIapRepository(
          nextPurchase: PurchaseResult(state, transactionId: 'tx'),
        ),
      );
      await service.buy(IapCatalog.largeGems);
      expect(service.save.gems, 0);
    }
  });

  test(
    'restore returns restored events without regranting consumables',
    () async {
      final repository = MockIapRepository(
        restoreResults: const [
          PurchaseResult(PurchaseState.restored, transactionId: 'tx-old'),
        ],
      );
      final service = IapService(
        repository,
        save: const GameSave(gems: 100, processedTransactions: ['tx-old']),
      );
      final results = await service.restore();
      expect(results.single.state, PurchaseState.restored);
      expect(service.save.gems, 100);
    },
  );
}
