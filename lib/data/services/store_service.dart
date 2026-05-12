// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';

import '../config/appwrite_config.dart';
import '../models/schema/appwrite_store_doc.dart';

class StoreService {
  StoreService({
    AppwriteConfig? config,
    Databases? databases,
    Realtime? realtime,
  })  : _config = config ?? AppwriteConfig.instance,
        _databasesOverride = databases,
        _realtimeOverride = realtime;

  final AppwriteConfig _config;
  final Databases? _databasesOverride;
  final Realtime? _realtimeOverride;

  Databases get _databases => _databasesOverride ?? _config.databases;
  Realtime get _realtime => _realtimeOverride ?? _config.realtime;

  Future<String> createStore(String businessName, String ownerUid) async {
    try {
      final String storeId = ID.unique();
      final AppwriteStoreDoc storePayload = AppwriteStoreDoc.pendingPayment(
        documentId: storeId,
        businessName: businessName,
        ownerUid: ownerUid,
      );

      final Document storeDoc = await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colStores,
        documentId: storeId,
        data: storePayload.toMap(),
      );

      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colUsers,
        documentId: ownerUid,
        data: <String, dynamic>{'activeStoreId': storeDoc.$id},
      );

      return storeDoc.$id;
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in createStore: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in createStore: $error');
      rethrow;
    }
  }

  StreamSubscription<RealtimeMessage> listenToPaymentStatus(
    String storeId,
    void Function(bool isActive) onUpdate,
  ) {
    final String channel =
        'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.colStores}.documents.$storeId';

    final RealtimeSubscription subscription = _realtime.subscribe(<String>[channel]);

    return subscription.stream.listen(
      (RealtimeMessage message) {
        final bool hasUpdateEvent = message.events.any(
          (String event) => event.contains('.documents.') && event.endsWith('.update'),
        );

        if (!hasUpdateEvent) {
          return;
        }

        final dynamic payload = message.payload;
        if (payload is! Map<String, dynamic>) {
          return;
        }

        final AppwriteStoreDoc storeDoc = AppwriteStoreDoc.fromMap(
          documentId: payload[r'$id'] as String? ?? storeId,
          data: payload,
        );

        if (storeDoc.subscription.status.isEmpty) {
          return;
        }

        if (storeDoc.subscription.isActive) {
          onUpdate(true);
        }
      },
      onError: (Object error) {
        if (error is AppwriteException) {
          debugPrint(
            'AppwriteException in listenToPaymentStatus stream: ${error.message}',
          );
          return;
        }
        debugPrint('Unexpected stream error in listenToPaymentStatus: $error');
      },
    );
  }
}
