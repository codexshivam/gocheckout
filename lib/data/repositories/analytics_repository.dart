// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';

import '../config/appwrite_config.dart';
import '../models/schema/order_models.dart';
import '../models/schema/store_stats_models.dart';
import '../sample/sample_schema_orders.dart';
import '../sample/sample_store_stats.dart';
import '../services/active_store_resolver.dart';

abstract class AnalyticsRepository {
  Future<StoreStatsDocument> fetchStoreStats({required String storeId});
  Future<List<OrderDocument>> fetchRecentOrders({int limit = 8});
}

class SampleAnalyticsRepository implements AnalyticsRepository {
  @override
  Future<StoreStatsDocument> fetchStoreStats({required String storeId}) async {
    return StoreStatsDocument.fromMap(storeId, sampleStoreStats);
  }

  @override
  Future<List<OrderDocument>> fetchRecentOrders({int limit = 8}) async {
    return sampleSchemaOrders.take(limit).toList();
  }
}

class AppwriteAnalyticsRepository implements AnalyticsRepository {
  AppwriteAnalyticsRepository({
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

  /// [storeId] param is accepted for interface compatibility but the resolved
  /// active store ID is always used for security — callers cannot spoof it.
  @override
  Future<StoreStatsDocument> fetchStoreStats({required String storeId}) async {
    try {
      final String resolvedStoreId = await _storeResolver.resolve();
      final DocumentList result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colStoreStats,
        queries: <String>[
          Query.equal('storeId', resolvedStoreId),
          Query.limit(1),
        ],
      );

      if (result.documents.isEmpty) {
        return StoreStatsDocument.fromMap(resolvedStoreId, const <String, dynamic>{});
      }

      final Document doc = result.documents.first;
      return StoreStatsDocument.fromMap(resolvedStoreId, doc.data);
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in fetchStoreStats: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in fetchStoreStats: $error');
      rethrow;
    }
  }

  @override
  Future<List<OrderDocument>> fetchRecentOrders({int limit = 8}) async {
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

