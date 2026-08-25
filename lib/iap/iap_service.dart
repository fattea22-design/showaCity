import '../domain/game_save.dart';

enum PurchaseState { purchased, restored, pending, canceled, error }

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.displayPrice,
    required this.type,
  });
  final String id;
  final String displayPrice;
  final String type;
}

class PurchaseResult {
  const PurchaseResult(this.state, {this.transactionId, this.errorMessage});
  final PurchaseState state;
  final String? transactionId;
  final String? errorMessage;
}

abstract interface class IapRepository {
  Future<List<StoreProduct>> products(List<String> ids);
  Future<PurchaseResult> purchase(String productId);
  Future<List<PurchaseResult>> restore();
}

class IapCatalog {
  static const smallGems = 'com.hashi.showa_city.gems.small';
  static const mediumGems = 'com.hashi.showa_city.gems.medium';
  static const largeGems = 'com.hashi.showa_city.gems.large';
  static const permanentBoost = 'com.hashi.showa_city.permanent.boost';
  static const retroLandmark = 'com.hashi.showa_city.retro.landmark';
  static const all = [
    smallGems,
    mediumGems,
    largeGems,
    permanentBoost,
    retroLandmark,
  ];
}

class IapService {
  IapService(this.repository, {GameSave this._save = const GameSave()});
  final IapRepository repository;
  GameSave _save;
  GameSave get save => _save;

  Future<List<StoreProduct>> loadProducts() =>
      repository.products(IapCatalog.all);

  Future<PurchaseResult> buy(String productId) async {
    final result = await repository.purchase(productId);
    return _apply(result, productId);
  }

  Future<List<PurchaseResult>> restore() async {
    final results = await repository.restore();
    for (final result in results) {
      if (result.state == PurchaseState.restored &&
          result.transactionId != null) {
        _apply(result, _productForTransaction(result.transactionId!));
      }
    }
    return results;
  }

  PurchaseResult _apply(PurchaseResult result, String productId) {
    if (result.state != PurchaseState.purchased &&
        result.state != PurchaseState.restored) {
      return result;
    }
    final transactionId = result.transactionId;
    if (transactionId == null ||
        _save.processedTransactions.contains(transactionId)) {
      return result;
    }
    final consumable =
        productId == IapCatalog.smallGems ||
        productId == IapCatalog.mediumGems ||
        productId == IapCatalog.largeGems;
    final gems = _save.gems + (consumable ? _gemsFor(productId) : 0);
    final entitlements = {..._save.entitlements, if (!consumable) productId};
    _save = GameSave(
      coins: _save.coins,
      gems: gems,
      buildings: _save.buildings,
      areas: _save.areas,
      era: _save.era,
      missions: _save.missions,
      achievements: _save.achievements,
      historyPoints: _save.historyPoints,
      lastActiveAt: _save.lastActiveAt,
      processedTransactions: [..._save.processedTransactions, transactionId],
      entitlements: entitlements.toList(),
    );
    return result;
  }

  int _gemsFor(String id) => id == IapCatalog.smallGems
      ? 100
      : id == IapCatalog.mediumGems
      ? 550
      : 1200;
  String _productForTransaction(String transactionId) =>
      transactionId.split('|').first;
}

class MockIapRepository implements IapRepository {
  MockIapRepository({
    this.nextPurchase = const PurchaseResult(PurchaseState.canceled),
  });
  final PurchaseResult nextPurchase;
  @override
  Future<List<StoreProduct>> products(List<String> ids) async => ids
      .map(
        (id) => StoreProduct(
          id: id,
          displayPrice: 'Store price',
          type: id.contains('.gems.') ? 'consumable' : 'non-consumable',
        ),
      )
      .toList();
  @override
  Future<PurchaseResult> purchase(String productId) async => nextPurchase;
  @override
  Future<List<PurchaseResult>> restore() async => const [];
}
