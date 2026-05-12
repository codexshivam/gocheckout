// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';

import '../config/appwrite_config.dart';
import '../models/schema/merchant_models.dart';
import '../models/schema/order_models.dart';
import '../sample/sample_schema_analytics.dart';
import '../sample/sample_schema_merchants.dart';
import '../sample/sample_schema_orders.dart';
import '../services/active_store_resolver.dart';

abstract class DashboardRepository {
  Future<Merchant> fetchMerchant();
  Future<List<double>> fetchSalesPoints();
  Future<List<OrderDocument>> fetchRecentOrders({int limit = 5});
}

class SampleDashboardRepository implements DashboardRepository {
  @override
  Future<Merchant> fetchMerchant() async => sampleMerchant;

  @override
  Future<List<double>> fetchSalesPoints() async => sampleMerchantSalesPoints;

  @override
  Future<List<OrderDocument>> fetchRecentOrders({int limit = 5}) async {
    return sampleSchemaOrders.take(limit).toList();
  }
}

class AppwriteDashboardRepository implements DashboardRepository {
  AppwriteDashboardRepository({
    required ActiveStoreResolver storeResolver,
    AppwriteConfig? config,
    Databases? databases,
  })  : _storeResolver = storeResolver,
        _config = config ?? AppwriteConfig.instance,
        _databasesOverride = databases;

  final ActiveStoreResolver _storeResolver;
  final AppwriteConfig _config;
  final Databases? _databasesOverride;

  Databases get _databases => _databasesOverride ?? _config.databases;

  @override
  Future<Merchant> fetchMerchant() async {
    try {
      final String storeId = await _storeResolver.resolve();
      final Document storeDoc = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colStores,
        documentId: storeId,
      );
      final Map<String, dynamic> data = storeDoc.data;
      return Merchant.fromMap(
        storeDoc.$id,
        <String, dynamic>{
          'businessName': data['businessName'] ?? '',
          'businessAddress': data['businessAddress'] ?? '',
          'contactInfo': data['contactInfo'] ?? <String, dynamic>{},
          'storeLogoUrl': data['storeLogoUrl'] ?? '',
          'verificationStatus': data['verificationStatus'] ?? 'pending',
          'stats': data['stats'] ?? <String, dynamic>{},
        },
      );
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in fetchMerchant: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in fetchMerchant: $error');
      rethrow;
    }
  }

  @override
  Future<List<double>> fetchSalesPoints() async {
    try {
      final String storeId = await _storeResolver.resolve();
      final DocumentList statsResult = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colStoreStats,
        queries: <String>[
          Query.equal('storeId', storeId),
          Query.limit(1),
        ],
      );

      if (statsResult.documents.isEmpty) {
        return List<double>.filled(8, 0.0);
      }

      final Map<String, dynamic> statsData = statsResult.documents.first.data;
      final List<dynamic> history =
          (statsData['monthlyHistory'] as List<dynamic>?) ?? <dynamic>[];

      return history
          .take(8)
          .map((dynamic item) {
            if (item is Map<String, dynamic>) {
              return (item['revenue'] as num?)?.toDouble() ?? 0.0;
            }
            return 0.0;
          })
          .toList();
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in fetchSalesPoints: ${error.message}');
      // Return empty list instead of crashing dashboard
      return List<double>.filled(8, 0.0);
    } catch (error) {
      debugPrint('Unexpected error in fetchSalesPoints: $error');
      return List<double>.filled(8, 0.0);
    }
  }

  @override
  Future<List<OrderDocument>> fetchRecentOrders({int limit = 5}) async {
    try {
      final String storeId = await _storeResolver.resolve();
      final DocumentList docs = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colOrders,
        queries: <String>[
          Query.equal('storeId', storeId),
          Query.equal('isDeleted', false),
          Query.orderDesc(r'$createdAt'),
          Query.limit(limit),
        ],
      );
      return docs.documents
          .map((doc) => OrderDocument.fromMap(doc.$id, doc.data))
          .toList(growable: false);
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in fetchRecentOrders: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in fetchRecentOrders: $error');
      rethrow;
    }
  }
}

