import 'package:flutter/foundation.dart';

import '../../data/models/app_error_envelope.dart';
import '../../data/services/onboarding_service.dart';

class OnboardingStateController extends ChangeNotifier {
  OnboardingStateController({OnboardingService? onboardingService})
      : _onboardingService = onboardingService ?? OnboardingService();

  final OnboardingService _onboardingService;

  bool _isLoading = false;
  String? _errorMessage;
  AppErrorEnvelope? _lastError;
  OnboardingRouteState? _lastRoute;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AppErrorEnvelope? get lastError => _lastError;
  OnboardingRouteState? get lastRoute => _lastRoute;

  Future<OnboardingRouteState?> evaluateUserPath({
    required String uid,
    required String email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _lastError = null;
    notifyListeners();

    try {
      final OnboardingRouteState route = await _onboardingService.evaluateUserPath(
        uid,
        email,
      );
      _lastRoute = route;
      return route;
    } catch (error) {
      _lastError = AppErrorEnvelope.from(
        error,
        source: 'onboarding.evaluateUserPath',
        fallbackMessage: 'Unable to evaluate onboarding state. Please retry.',
      );
      _errorMessage = _lastError!.message;
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
