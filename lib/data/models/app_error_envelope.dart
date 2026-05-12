import 'dart:async';

import 'package:appwrite/appwrite.dart';

enum AppErrorCode {
  unauthorized,
  timeout,
  network,
  validation,
  conflict,
  notFound,
  server,
  unknown,
}

class AppErrorEnvelope {
  const AppErrorEnvelope({
    required this.code,
    required this.message,
    required this.retryable,
    this.source,
    this.debugDetails,
  });

  final AppErrorCode code;
  final String message;
  final bool retryable;
  final String? source;
  final String? debugDetails;

  factory AppErrorEnvelope.from(
    Object error, {
    required String source,
    required String fallbackMessage,
  }) {
    if (error is TimeoutException) {
      return AppErrorEnvelope(
        code: AppErrorCode.timeout,
        message: 'Request timed out. Please check your network and try again.',
        retryable: true,
        source: source,
        debugDetails: error.message,
      );
    }

    if (error is AppwriteException) {
      final int? code = error.code;
      if (code == 401 || code == 403) {
        return AppErrorEnvelope(
          code: AppErrorCode.unauthorized,
          message: error.message ?? 'You are not authorized for this action.',
          retryable: false,
          source: source,
          debugDetails: error.response,
        );
      }
      if (code == 404) {
        return AppErrorEnvelope(
          code: AppErrorCode.notFound,
          message: error.message ?? 'Requested resource was not found.',
          retryable: false,
          source: source,
          debugDetails: error.response,
        );
      }
      if (code == 409) {
        return AppErrorEnvelope(
          code: AppErrorCode.conflict,
          message: error.message ?? 'Conflicting data was detected. Refresh and retry.',
          retryable: true,
          source: source,
          debugDetails: error.response,
        );
      }
      if (code == 400 || code == 422) {
        return AppErrorEnvelope(
          code: AppErrorCode.validation,
          message: error.message ?? 'Invalid input. Please review and try again.',
          retryable: false,
          source: source,
          debugDetails: error.response,
        );
      }
      if (code == null || code >= 500) {
        return AppErrorEnvelope(
          code: AppErrorCode.server,
          message: error.message ?? fallbackMessage,
          retryable: true,
          source: source,
          debugDetails: error.response,
        );
      }

      return AppErrorEnvelope(
        code: AppErrorCode.unknown,
        message: error.message ?? fallbackMessage,
        retryable: false,
        source: source,
        debugDetails: error.response,
      );
    }

    return AppErrorEnvelope(
      code: AppErrorCode.unknown,
      message: fallbackMessage,
      retryable: false,
      source: source,
      debugDetails: error.toString(),
    );
  }
}
