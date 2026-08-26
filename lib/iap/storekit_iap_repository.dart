import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'iap_service.dart';

class StoreKitIapRepository implements IapRepository {
  StoreKitIapRepository({InAppPurchase? store})
    : _store = store ?? InAppPurchase.instance {
    _purchaseSubscription = _store.purchaseStream.listen(_onPurchaseUpdates);
  }

  final InAppPurchase _store;
  final Map<String, Completer<PurchaseResult>> _pending = {};
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Completer<List<PurchaseResult>>? _restoreCompleter;
  Timer? _restoreTimer;

  @override
  Future<List<StoreProduct>> products(List<String> ids) async {
    final response = await _store.queryProductDetails(ids.toSet());
    if (response.error != null) throw StateError(response.error!.message);
    return response.productDetails
        .map(
          (product) => StoreProduct(
            id: product.id,
            displayPrice: product.price,
            type: _isConsumable(product.id) ? 'consumable' : 'non-consumable',
          ),
        )
        .toList();
  }

  @override
  Future<PurchaseResult> purchase(String productId) async {
    final completer = Completer<PurchaseResult>();
    _pending[productId] = completer;
    final response = await _store.queryProductDetails({productId});
    if (response.error != null || response.productDetails.isEmpty) {
      _pending.remove(productId);
      return PurchaseResult(
        PurchaseState.error,
        errorMessage: response.error?.message ?? 'Product not found',
      );
    }
    final started = _isConsumable(productId)
        ? await _store.buyConsumable(
            purchaseParam: PurchaseParam(
              productDetails: response.productDetails.single,
            ),
          )
        : await _store.buyNonConsumable(
            purchaseParam: PurchaseParam(
              productDetails: response.productDetails.single,
            ),
          );
    if (!started) {
      _pending.remove(productId);
      return const PurchaseResult(
        PurchaseState.error,
        errorMessage: 'Purchase did not start',
      );
    }
    return completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        _pending.remove(productId);
        return const PurchaseResult(
          PurchaseState.error,
          errorMessage: 'Purchase timed out',
        );
      },
    );
  }

  @override
  Future<List<PurchaseResult>> restore() async {
    final completer = _restoreCompleter = Completer<List<PurchaseResult>>();
    _restoreTimer?.cancel();
    _restoreTimer = Timer(const Duration(seconds: 2), () {
      if (!completer.isCompleted) completer.complete(const []);
      _restoreCompleter = null;
    });
    try {
      await _store.restorePurchases();
    } catch (error) {
      _restoreTimer?.cancel();
      _restoreCompleter = null;
      return [PurchaseResult(PurchaseState.error, errorMessage: '$error')];
    }
    return completer.future;
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchases) {
    final restored = <PurchaseResult>[];
    for (final purchase in purchases) {
      final result = PurchaseResult(
        _stateFor(purchase.status),
        transactionId: purchase.purchaseID,
        errorMessage: purchase.error?.message,
      );
      if (purchase.status == PurchaseStatus.restored) restored.add(result);
      final completer = _pending.remove(purchase.productID);
      if (completer != null && !completer.isCompleted) {
        completer.complete(result);
      }
      if (purchase.pendingCompletePurchase) {
        unawaited(_store.completePurchase(purchase));
      }
    }
    final restoreCompleter = _restoreCompleter;
    if (restoreCompleter != null &&
        !restoreCompleter.isCompleted &&
        restored.isNotEmpty) {
      restoreCompleter.complete(restored);
      _restoreTimer?.cancel();
      _restoreCompleter = null;
    }
  }

  PurchaseState _stateFor(PurchaseStatus status) => switch (status) {
    PurchaseStatus.purchased => PurchaseState.purchased,
    PurchaseStatus.restored => PurchaseState.restored,
    PurchaseStatus.pending => PurchaseState.pending,
    PurchaseStatus.canceled => PurchaseState.canceled,
    PurchaseStatus.error => PurchaseState.error,
  };

  bool _isConsumable(String id) =>
      id == IapCatalog.smallGems ||
      id == IapCatalog.mediumGems ||
      id == IapCatalog.largeGems;

  Future<void> dispose() async {
    _restoreTimer?.cancel();
    await _purchaseSubscription?.cancel();
  }
}
