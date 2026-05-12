import 'package:appwrite/appwrite.dart';

import 'app_env.dart';

/// Central Appwrite SDK bootstrap and shared collection constants.
///
/// All IDs are sourced from [AppEnv] which reads --dart-define flags,
/// so no secrets are ever hardcoded in source.
class AppwriteConfig {
  AppwriteConfig._internal();

  static final AppwriteConfig instance = AppwriteConfig._internal();

  // ---------------------------------------------------------------------------
  // Connection
  // ---------------------------------------------------------------------------

  static String get endpoint => AppEnv.appwriteEndpoint;
  static String get projectId => AppEnv.appwriteProjectId;

  // ---------------------------------------------------------------------------
  // Database
  // ---------------------------------------------------------------------------

  static String get databaseId => AppEnv.appwriteDatabaseId;

  // ---------------------------------------------------------------------------
  // Collection IDs
  // ---------------------------------------------------------------------------

  static String get colUsers => AppEnv.colUsers;
  static String get colStores => AppEnv.colStores;
  static String get colInvites => AppEnv.colInvites;
  static String get colCoupons => AppEnv.colCoupons;
  static String get colOrders => AppEnv.colOrders;
  static String get colProducts => AppEnv.colProducts;
  static String get colCheckoutLinks => AppEnv.colCheckoutLinks;
  static String get colStoreStats => AppEnv.colStoreStats;
  static String get colPayments => AppEnv.colPayments;

  // ---------------------------------------------------------------------------
  // SDK instances (lazily initialized)
  // ---------------------------------------------------------------------------

  late final Client _client = Client()
      .setEndpoint(endpoint)
      .setProject(projectId);

  late final Account _account = Account(_client);
  late final Databases _databases = Databases(_client);
  late final Realtime _realtime = Realtime(_client);
  late final Storage _storage = Storage(_client);

  Client get client => _client;
  Account get account => _account;
  Databases get databases => _databases;
  Realtime get realtime => _realtime;
  Storage get storage => _storage;
}
