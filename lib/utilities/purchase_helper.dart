// lib/utilities/purchase_helper.dart

import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper to manage "Remove Ads" in-app purchase.
class PurchaseHelper {
  static const String _kRemoveAdsId = 'remove_ads';
  static final InAppPurchase _iap = InAppPurchase.instance;
  static bool _available = false;
  static bool adsRemoved = false;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Initialize IAP and listen for purchase updates.
  static Future<void> init() async {
    _available = await _iap.isAvailable();
    final prefs = await SharedPreferences.getInstance();
    adsRemoved = prefs.getBool(_kRemoveAdsId) ?? false;

    if (!_available) return;

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(_onPurchaseUpdated);
  }

  /// Dispose stream subscription
  static void dispose() {
    _subscription?.cancel();
  }

  /// Query product details for "remove_ads"
  static Future<ProductDetails?> fetchRemoveAdsProduct() async {
    if (!_available) return null;
    final response = await _iap.queryProductDetails({_kRemoveAdsId});
    if (response.notFoundIDs.isNotEmpty || response.error != null) {
      return null;
    }
    return response.productDetails.first;
  }

  /// Initiate purchase flow
  static Future<void> buyRemoveAds(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Handle purchase updates
  static Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID == _kRemoveAdsId && purchase.status == PurchaseStatus.purchased) {
        await _deliverPurchase(purchase);
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  /// Grant entitlement and persist
  static Future<void> _deliverPurchase(PurchaseDetails purchase) async {
    adsRemoved = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRemoveAdsId, true);
  }

  /// Check if ads should be shown
  static bool shouldShowAds() => !adsRemoved;
}
