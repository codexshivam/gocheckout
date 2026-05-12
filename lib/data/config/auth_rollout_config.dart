class AuthRolloutConfig {
  const AuthRolloutConfig({
    this.enableOAuthHardening = true,
    this.enableSessionIntegrity = true,
    this.enableAuthTelemetry = true,
    this.telemetrySamplePercent = 100,
    this.oauthFailureAlertThreshold = 3,
    this.oauthFailureAlertWindowSeconds = 600,
  });

  final bool enableOAuthHardening;
  final bool enableSessionIntegrity;
  final bool enableAuthTelemetry;

  // Percentage in [0, 100] used to sample telemetry emission volume.
  final int telemetrySamplePercent;

  // Alert threshold for oauth failures inside sliding window.
  final int oauthFailureAlertThreshold;
  final int oauthFailureAlertWindowSeconds;

  Duration get oauthFailureAlertWindow =>
      Duration(seconds: oauthFailureAlertWindowSeconds);

  factory AuthRolloutConfig.fromEnvironment() {
    return AuthRolloutConfig(
      enableOAuthHardening: const bool.fromEnvironment(
        'AUTH_ENABLE_OAUTH_HARDENING',
        defaultValue: true,
      ),
      enableSessionIntegrity: const bool.fromEnvironment(
        'AUTH_ENABLE_SESSION_INTEGRITY',
        defaultValue: true,
      ),
      enableAuthTelemetry: const bool.fromEnvironment(
        'AUTH_ENABLE_TELEMETRY',
        defaultValue: true,
      ),
      telemetrySamplePercent: _clampPercent(
        const int.fromEnvironment('AUTH_TELEMETRY_SAMPLE_PERCENT', defaultValue: 100),
      ),
      oauthFailureAlertThreshold: _minOne(
        const int.fromEnvironment('AUTH_OAUTH_FAILURE_ALERT_THRESHOLD', defaultValue: 3),
      ),
      oauthFailureAlertWindowSeconds: _minOne(
        const int.fromEnvironment('AUTH_OAUTH_FAILURE_ALERT_WINDOW_SECONDS', defaultValue: 600),
      ),
    );
  }

  static int _clampPercent(int value) {
    if (value < 0) {
      return 0;
    }
    if (value > 100) {
      return 100;
    }
    return value;
  }

  static int _minOne(int value) {
    return value <= 0 ? 1 : value;
  }
}
