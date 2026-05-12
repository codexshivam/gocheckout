import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/r2_config.dart';

class R2UploadException implements Exception {
  const R2UploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class R2UploadService {
  R2UploadService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> uploadFile({
    required Uint8List bytes,
    required String objectPath,
    required String contentType,
    Duration timeout = const Duration(seconds: 25),
    int maxRetries = 2,
    ValueChanged<int>? onAttempt,
  }) async {
    int attempt = 0;
    while (attempt <= maxRetries) {
      try {
        onAttempt?.call(attempt + 1);

        final Uri signedUri = Uri.parse(R2Config.signedUploadEndpoint);
        await _ensureEndpointReachable(signedUri, timeout);

        final Map<String, String> headers = <String, String>{
          'Content-Type': 'application/json',
        };

        if (R2Config.uploadApiToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer ${R2Config.uploadApiToken}';
        }

        final http.Response signedResponse = await _client
            .post(
              signedUri,
              headers: headers,
              body: jsonEncode(<String, dynamic>{
                'objectPath': objectPath,
                'contentType': contentType,
              }),
            )
            .timeout(timeout);

        if (signedResponse.statusCode < 200 || signedResponse.statusCode >= 300) {
          throw R2UploadException(
            'Signed URL request failed (${signedResponse.statusCode}).',
          );
        }

        final Map<String, dynamic> signedPayload =
            jsonDecode(signedResponse.body) as Map<String, dynamic>;
        final String? uploadUrl = signedPayload['uploadUrl'] as String?;
        final String? publicUrl = signedPayload['publicUrl'] as String?;

        if (uploadUrl == null || uploadUrl.isEmpty) {
          throw const R2UploadException(
            'Signed upload endpoint did not return uploadUrl.',
          );
        }
        if (publicUrl == null || publicUrl.isEmpty) {
          throw const R2UploadException(
            'Signed upload endpoint did not return publicUrl.',
          );
        }

        final http.Response uploadResponse = await _client
            .put(
              Uri.parse(uploadUrl),
              headers: <String, String>{
                'Content-Type': contentType,
              },
              body: bytes,
            )
            .timeout(timeout);

        if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
          throw R2UploadException(
            'R2 file upload failed (${uploadResponse.statusCode}).',
          );
        }

        return publicUrl;
      } catch (error) {
        final bool lastAttempt = attempt >= maxRetries;
        debugPrint('R2 upload attempt ${attempt + 1} failed: $error');

        if (lastAttempt) {
          if (error is R2UploadException) {
            rethrow;
          }
          if (error is http.ClientException) {
            throw R2UploadException('Network error while uploading to R2.');
          }
          if (error is TimeoutException) {
            throw R2UploadException(
              'Upload timed out. Please check your connection and try again.',
            );
          }
          throw R2UploadException('Unexpected upload error. Please try again.');
        }

        attempt += 1;
      }
    }

    throw const R2UploadException('Unable to upload file at this time.');
  }

  Future<void> _ensureEndpointReachable(Uri endpoint, Duration timeout) async {
    try {
      await _client.head(endpoint).timeout(timeout);
    } catch (_) {
      throw const R2UploadException(
        'No internet connection detected. Please reconnect and try again.',
      );
    }
  }
}
