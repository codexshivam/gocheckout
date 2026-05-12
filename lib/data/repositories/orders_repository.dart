// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';

import '../config/appwrite_config.dart';
import '../models/schema/order_models.dart';
import '../sample/sample_schema_orders.dart';
import '../services/active_store_resolver.dart';

abstract class OrdersRepository {
  Future<List<OrderDocument>> fetchOrders();
  Future<OrderDocument> saveOrder(OrderDocument order);
  Future<void> deleteOrder(String orderId);
}

class SampleOrdersRepository implements OrdersRepository {
  final List<OrderDocument> _orders = List<OrderDocument>.from(sampleSchemaOrders);

  @override
  Future<List<OrderDocument>> fetchOrders() async {
    return List<OrderDocument>.from(_orders);
  }

  @override
  Future<OrderDocument> saveOrder(OrderDocument order) async {
    final int index = _orders.indexWhere((o) => o.id == order.id);
    if (index >= 0) {
      _orders[index] = order;
    } else {
      _orders.insert(0, order);
    }
    return order;
  }

  @override
  Future<void> deleteOrder(String orderId) async {
    _orders.removeWhere((o) => o.id == orderId);
  }
}

class AppwriteOrdersRepository implements OrdersRepository {
  AppwriteOrdersRepository({
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
  Future<List<OrderDocument>> fetchOrders() async {
    try {
      final String storeId = await _storeResolver.resolve();
      final DocumentList docs = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colOrders,
        queries: <String>[
          Query.equal('storeId', storeId),
          Query.equal('isDeleted', false),
          Query.orderDesc(r'$createdAt'),
          Query.limit(100),
        ],
      );
      return docs.documents
          .map((doc) => OrderDocument.fromMap(doc.$id, doc.data))
          .toList(growable: false);
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in fetchOrders: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in fetchOrders: $error');
      rethrow;
    }
  }

  @override
  Future<OrderDocument> saveOrder(OrderDocument order) async {
    try {
      final String storeId = await _storeResolver.resolve();
      final String? userEmail = await _storeResolver.resolveUserEmail();
      final DateTime now = DateTime.now().toUtc();

      final Map<String, dynamic> payload = <String, dynamic>{
        ...order.toMap(),
        'storeId': storeId,
        'merchantId': storeId,
        'updatedAt': now.toIso8601String(),
        'updatedBy': userEmail,
      };

      final bool isNew = order.id.startsWith('ord_');
      if (isNew) {
        final Document created = await _databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.colOrders,
          documentId: ID.unique(),
          data: <String, dynamic>{
            ...payload,
            'isDeleted': false,
            'createdAt': now.toIso8601String(),
          },
        );
        return OrderDocument.fromMap(created.$id, created.data);
      }

      final Document updated = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colOrders,
        documentId: order.id,
        data: payload,
      );
      return OrderDocument.fromMap(updated.$id, updated.data);
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in saveOrder: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in saveOrder: $error');
      rethrow;
    }
  }

  @override
  Future<void> deleteOrder(String orderId) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colOrders,
        documentId: orderId,
        data: <String, dynamic>{
          'isDeleted': true,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in deleteOrder: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in deleteOrder: $error');
      rethrow;
    }
  }
}

