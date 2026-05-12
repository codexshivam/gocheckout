import 'package:flutter/foundation.dart';

class AuthTelemetryEvent {
  const AuthTelemetryEvent({
    required this.name,
    required this.at,
    this.metadata = const <String, String>{},
  });

  final String name;
  final DateTime at;
  final Map<String, String> metadata;
}

abstract class AuthObservabilityContract {
  void record(
    String name, {
    int samplePercent,
    String subject,
    Map<String, String> metadata,
  });

  List<AuthTelemetryEvent> get events;
}

class AuthObservabilityService implements AuthObservabilityContract {
  AuthObservabilityService({
    required this.oauthFailureThreshold,
    required this.oauthFailureWindow,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final int oauthFailureThreshold;
  final Duration oauthFailureWindow;
  final DateTime Function() _now;

  final List<AuthTelemetryEvent> _events = <AuthTelemetryEvent>[];
  final List<DateTime> _oauthFailures = <DateTime>[];

  @override
  List<AuthTelemetryEvent> get events => List<AuthTelemetryEvent>.unmodifiable(_events);

  @override
  void record(
    String name, {
    int samplePercent = 100,
    String subject = 'global',
    Map<String, String> metadata = const <String, String>{},
  }) {
    final int clampedSample = samplePercent.clamp(0, 100);
    if (!_isSampled(clampedSample, '$subject|$name')) {
      return;
    }

    final DateTime now = _now().toUtc();
    _events.add(AuthTelemetryEvent(name: name, at: now, metadata: metadata));
    debugPrint('AUTH_EVENT $name ${metadata.isEmpty ? '' : metadata}');

    if (name == 'auth.login.oauth_failure' || name == 'auth.signup.oauth_failure') {
      _oauthFailures.add(now);
      _trimOldFailures(now);
      if (_oauthFailures.length >= oauthFailureThreshold) {
        final AuthTelemetryEvent alert = AuthTelemetryEvent(
          name: 'auth.alert.oauth_failure_threshold',
          at: now,
          metadata: <String, String>{
            'failures': _oauthFailures.length.toString(),
            'windowSeconds': oauthFailureWindow.inSeconds.toString(),
          },
        );
        _events.add(alert);
        debugPrint('AUTH_ALERT oauth_failure_threshold failures=${_oauthFailures.length}');
      }
    }
  }

  bool _isSampled(int samplePercent, String token) {
    if (samplePercent >= 100) {
      return true;
    }
    if (samplePercent <= 0) {
      return false;
    }

    final int hash = token.hashCode & 0x7fffffff;
    final int bucket = hash % 100;
    return bucket < samplePercent;
  }

  void _trimOldFailures(DateTime now) {
    final DateTime cutoff = now.subtract(oauthFailureWindow);
    _oauthFailures.removeWhere((DateTime at) => at.isBefore(cutoff));
  }
}
