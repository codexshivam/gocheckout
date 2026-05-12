// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';

import '../config/appwrite_config.dart';

class StoreMigrationService {
  StoreMigrationService({
    AppwriteConfig? config,
    Databases? databases,
  })  : _config = config ?? AppwriteConfig.instance,
        _databasesOverride = databases;

  final AppwriteConfig _config;
  final Databases? _databasesOverride;

  Databases get _databases => _databasesOverride ?? _config.databases;

  Future<void> ensureStoreDocumentShape(String storeId) async {
    try {
      final Document storeDoc = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colStores,
        documentId: storeId,
      );

      final Map<String, dynamic> data = Map<String, dynamic>.from(storeDoc.data);
      bool changed = false;

      void ensureValue(String key, dynamic value) {
        if (!data.containsKey(key) || data[key] == null) {
          data[key] = value;
          changed = true;
        }
      }

      ensureValue('businessName', '');
      ensureValue('businessAddress', '');
      ensureValue('contactInfo', <String, dynamic>{
        'email': '',
        'phone': '',
        'whatsapp': '',
      });
      ensureValue('storeLogoUrl', '');
      ensureValue('verificationStatus', 'pending');
      ensureValue('stats', <String, dynamic>{
        'totalSales': 0,
        'totalOrders': 0,
        'rtoCount': 0,
      });
      ensureValue('verificationDocs', <String, dynamic>{
        'citizenshipUrl': '',
        'businessRegUrl': '',
        'panUrl': '',
      });
      ensureValue('paymentSettings', <String, dynamic>{
        'esewa': <String, dynamic>{'isActive': false},
        'khalti': <String, dynamic>{'isActive': false},
        'bankTransfer': <String, dynamic>{'isActive': false},
      });
      ensureValue('team', <dynamic>[]);
      ensureValue('subscription', <String, dynamic>{'status': 'pending_payment'});

      if (!changed) {
        return;
      }

      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colStores,
        documentId: storeId,
        data: data,
      );
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in ensureStoreDocumentShape: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in ensureStoreDocumentShape: $error');
      rethrow;
    }
  }
}
