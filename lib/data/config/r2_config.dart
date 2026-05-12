import 'app_env.dart';

/// Cloudflare R2 storage configuration.
/// All values sourced from [AppEnv] / --dart-define flags.
class R2Config {
  R2Config._();

  /// Public base URL for objects served from Cloudflare R2 custom domain.
  static String get publicBaseUrl => AppEnv.r2PublicBaseUrl;

  /// Backend endpoint that returns a one-time signed upload URL and public URL.
  /// Expected response: {"uploadUrl":"...", "publicUrl":"..."}
  static String get signedUploadEndpoint => AppEnv.r2UploadEndpoint;

  /// Optional bearer token for the signed upload endpoint if required.
  static String get uploadApiToken => AppEnv.r2UploadToken;
}
