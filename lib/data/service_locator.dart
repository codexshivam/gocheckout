import 'package:flutter/foundation.dart';

import 'config/app_env.dart';
import 'config/appwrite_config.dart';
import 'repositories/analytics_repository.dart';
import 'repositories/checkout_links_repository.dart';
import 'repositories/coupons_repository.dart';
import 'repositories/dashboard_repository.dart';
import 'repositories/orders_repository.dart';
import 'repositories/products_repository.dart';
import 'repositories/settings_repository.dart';
import 'services/active_store_resolver.dart';
import 'services/auth_observability_service.dart';
import 'services/auth_service.dart';
import 'services/r2_upload_service.dart';

/// Central dependency provider for the Merchant Portal.
///
/// Initialise once at app startup via [ServiceLocator.instance.initialize].
/// All views and controllers access dependencies via [ServiceLocator.instance].
///
/// Switching between sample data and Appwrite is controlled by [AppEnv.useSampleData]
/// (set via --dart-define=USE_SAMPLE_DATA=false at build time).
///
/// Example:
/// ```dart
/// // In main.dart before runApp:
/// ServiceLocator.instance.initialize();
///
/// // In a view:
/// final repo = ServiceLocator.instance.productsRepository;
/// ```
class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator instance = ServiceLocator._();

  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Core infrastructure
  // ---------------------------------------------------------------------------

  late final AppwriteConfig appwriteConfig;
  late final AuthServiceContract authService;
  late final ActiveStoreResolver storeResolver;
  late final AuthObservabilityContract observability;
  late final R2UploadService uploadService;

  // ---------------------------------------------------------------------------
  // Repositories
  // ---------------------------------------------------------------------------

  late final ProductsRepository productsRepository;
  late final OrdersRepository ordersRepository;
  late final CheckoutLinksRepository checkoutLinksRepository;
  late final CouponsRepository couponsRepository;
  late final SettingsRepository settingsRepository;
  late final AnalyticsRepository analyticsRepository;
  late final DashboardRepository dashboardRepository;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initializes all dependencies.
  ///
  /// Must be called exactly once before [runApp].
  /// Calling this more than once is a no-op.
  void initialize() {
    if (_initialized) return;

    // Core
    appwriteConfig = AppwriteConfig.instance;
    authService = AuthService(config: appwriteConfig);
    storeResolver = ActiveStoreResolver(
      authService: authService,
      config: appwriteConfig,
    );
    observability = AuthObservabilityService(
      oauthFailureThreshold: 5,
      oauthFailureWindow: const Duration(minutes: 10),
    );
    uploadService = R2UploadService();

    // Repositories
    if (AppEnv.useSampleData) {
      _initSampleRepositories();
    } else {
      _initAppwriteRepositories();
    }

    _initialized = true;

    debugPrint(
      '[ServiceLocator] Initialized. '
      'Backend: ${AppEnv.useSampleData ? "Sample Data" : "Appwrite"}',
    );
  }

  void _initSampleRepositories() {
    productsRepository = SampleProductsRepository();
    ordersRepository = SampleOrdersRepository();
    checkoutLinksRepository = SampleCheckoutLinksRepository() as CheckoutLinksRepository;
    couponsRepository = SampleCouponsRepository();
    settingsRepository = SampleSettingsRepository();
    analyticsRepository = SampleAnalyticsRepository();
    dashboardRepository = SampleDashboardRepository();
  }

  void _initAppwriteRepositories() {
    productsRepository = AppwriteProductsRepository(
      storeResolver: storeResolver,
      config: appwriteConfig,
    );
    ordersRepository = AppwriteOrdersRepository(
      storeResolver: storeResolver,
      config: appwriteConfig,
    );
    checkoutLinksRepository = AppwriteCheckoutLinksRepository(
      storeResolver: storeResolver,
      productsRepository: productsRepository,
      config: appwriteConfig,
    ) as CheckoutLinksRepository;
    couponsRepository = AppwriteCouponsRepository(
      storeResolver: storeResolver,
      config: appwriteConfig,
    );
    settingsRepository = AppwriteSettingsRepository(
      storeResolver: storeResolver,
      authService: authService as AuthService,
      config: appwriteConfig,
    );
    analyticsRepository = AppwriteAnalyticsRepository(
      storeResolver: storeResolver,
      config: appwriteConfig,
    );
    dashboardRepository = AppwriteDashboardRepository(
      storeResolver: storeResolver,
      config: appwriteConfig,
    );
  }

  // ---------------------------------------------------------------------------
  // Session lifecycle
  // ---------------------------------------------------------------------------

  /// Clears caches on logout so the next login resolves fresh store context.
  void onLogout() {
    storeResolver.clearCache();
  }

  /// Returns true if the ServiceLocator has been initialized.
  bool get isInitialized => _initialized;
}
