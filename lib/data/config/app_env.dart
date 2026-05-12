/// Centralized environment configuration via --dart-define flags.
///
/// Usage in development (sample data, no Appwrite needed):
///   flutter run
///
/// Usage in production (real Appwrite backend):
///   flutter run \
///     --dart-define=USE_SAMPLE_DATA=false \
///     --dart-define=APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1 \
///     --dart-define=APPWRITE_PROJECT_ID=your_project_id \
///     --dart-define=APPWRITE_DATABASE_ID=your_database_id \
///     --dart-define=R2_UPLOAD_ENDPOINT=https://your-backend.com/api/r2/signed-upload \
///     --dart-define=R2_UPLOAD_TOKEN=your_token
///
/// All collection IDs can be overridden the same way:
///   --dart-define=COL_USERS=users
class AppEnv {
  const AppEnv._();

  // ---------------------------------------------------------------------------
  // Feature switches
  // ---------------------------------------------------------------------------

  /// When true, all repositories use in-memory sample data.
  /// Set to false only when real Appwrite credentials are provided.
  static const bool useSampleData = bool.fromEnvironment(
    'USE_SAMPLE_DATA',
    defaultValue: true,
  );

  // ---------------------------------------------------------------------------
  // Appwrite connection
  // ---------------------------------------------------------------------------

  static const String appwriteEndpoint = String.fromEnvironment(
    'APPWRITE_ENDPOINT',
    defaultValue: 'https://cloud.appwrite.io/v1',
  );

  static const String appwriteProjectId = String.fromEnvironment(
    'APPWRITE_PROJECT_ID',
    defaultValue: '',
  );

  static const String appwriteDatabaseId = String.fromEnvironment(
    'APPWRITE_DATABASE_ID',
    defaultValue: '',
  );

  // ---------------------------------------------------------------------------
  // Appwrite Collection IDs
  // ---------------------------------------------------------------------------

  static const String colUsers = String.fromEnvironment(
    'COL_USERS',
    defaultValue: 'users',
  );

  static const String colStores = String.fromEnvironment(
    'COL_STORES',
    defaultValue: 'stores',
  );

  static const String colInvites = String.fromEnvironment(
    'COL_INVITES',
    defaultValue: 'invites',
  );

  static const String colCoupons = String.fromEnvironment(
    'COL_COUPONS',
    defaultValue: 'coupons',
  );

  static const String colOrders = String.fromEnvironment(
    'COL_ORDERS',
    defaultValue: 'orders',
  );

  static const String colProducts = String.fromEnvironment(
    'COL_PRODUCTS',
    defaultValue: 'products',
  );

  static const String colCheckoutLinks = String.fromEnvironment(
    'COL_CHECKOUT_LINKS',
    defaultValue: 'checkout_links',
  );

  static const String colStoreStats = String.fromEnvironment(
    'COL_STORE_STATS',
    defaultValue: 'store_stats',
  );

  static const String colPayments = String.fromEnvironment(
    'COL_PAYMENTS',
    defaultValue: 'payments',
  );

  // ---------------------------------------------------------------------------
  // Cloudflare R2
  // ---------------------------------------------------------------------------

  static const String r2PublicBaseUrl = String.fromEnvironment(
    'R2_PUBLIC_BASE_URL',
    defaultValue: 'https://pub-merchantportal-assets.r2.dev',
  );

  static const String r2UploadEndpoint = String.fromEnvironment(
    'R2_UPLOAD_ENDPOINT',
    defaultValue: '',
  );

  static const String r2UploadToken = String.fromEnvironment(
    'R2_UPLOAD_TOKEN',
    defaultValue: '',
  );

  // ---------------------------------------------------------------------------
  // Auth rollout (mirrors AuthRolloutConfig defaults)
  // ---------------------------------------------------------------------------

  static const bool authEnableOAuthHardening = bool.fromEnvironment(
    'AUTH_ENABLE_OAUTH_HARDENING',
    defaultValue: true,
  );

  static const bool authEnableSessionIntegrity = bool.fromEnvironment(
    'AUTH_ENABLE_SESSION_INTEGRITY',
    defaultValue: true,
  );

  static const bool authEnableTelemetry = bool.fromEnvironment(
    'AUTH_ENABLE_TELEMETRY',
    defaultValue: true,
  );

  static const int authTelemetrySamplePercent = int.fromEnvironment(
    'AUTH_TELEMETRY_SAMPLE_PERCENT',
    defaultValue: 100,
  );
}
