import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/services/store_service.dart';

class StoreStateController extends ChangeNotifier {
  StoreStateController({StoreService? storeService})
      : _storeService = storeService ?? StoreService();

  final StoreService _storeService;

  bool _isLoading = false;
  bool _isSubscriptionActive = false;
  String? _storeId;
  String? _errorMessage;
  StreamSubscription<dynamic>? _paymentSubscription;

  bool get isLoading => _isLoading;
  bool get isSubscriptionActive => _isSubscriptionActive;
  String? get storeId => _storeId;
  String? get errorMessage => _errorMessage;

  Future<String?> createStore({
    required String businessName,
    required String ownerUid,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String createdStoreId = await _storeService.createStore(
        businessName,
        ownerUid,
      );
      _storeId = createdStoreId;
      _isSubscriptionActive = false;
      return createdStoreId;
    } catch (error) {
      _errorMessage = error.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void listenToPaymentStatus(String storeId) {
    _paymentSubscription?.cancel();
    _storeId = storeId;
    _paymentSubscription = _storeService.listenToPaymentStatus(storeId, (bool isActive) {
      _isSubscriptionActive = isActive;
      notifyListeners();
    });
  }

  Future<void> clearSessionState() async {
    final StreamSubscription<dynamic>? subscription = _paymentSubscription;
    _paymentSubscription = null;
    if (subscription != null) {
      await subscription.cancel();
    }

    _isSubscriptionActive = false;
    _storeId = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _paymentSubscription?.cancel();
    super.dispose();
  }
}
