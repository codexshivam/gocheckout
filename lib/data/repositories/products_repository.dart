// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';

import '../config/appwrite_config.dart';
import '../models/schema/product_models.dart';
import '../sample/sample_schema_products.dart';
import '../services/active_store_resolver.dart';

abstract class ProductsRepository {
  Future<List<Product>> fetchProducts();
  Future<Product> saveProduct(Product product);
  Future<void> deleteProduct(String productId);
}

class SampleProductsRepository implements ProductsRepository {
  final List<Product> _products = List<Product>.from(sampleSchemaProducts);

  @override
  Future<List<Product>> fetchProducts() async {
    return List<Product>.from(_products);
  }

  @override
  Future<Product> saveProduct(Product product) async {
    final int index = _products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _products[index] = product;
    } else {
      _products.insert(0, product);
    }
    return product;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    _products.removeWhere((p) => p.id == productId);
  }
}

class AppwriteProductsRepository implements ProductsRepository {
  AppwriteProductsRepository({
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
  Future<List<Product>> fetchProducts() async {
    try {
      final String storeId = await _storeResolver.resolve();
      final DocumentList docs = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colProducts,
        queries: <String>[
          Query.equal('storeId', storeId),
          Query.equal('isDeleted', false),
          Query.orderDesc(r'$createdAt'),
        ],
      );
      return docs.documents
          .map((doc) => Product.fromMap(doc.$id, doc.data))
          .toList(growable: false);
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in fetchProducts: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in fetchProducts: $error');
      rethrow;
    }
  }

  @override
  Future<Product> saveProduct(Product product) async {
    try {
      final String storeId = await _storeResolver.resolve();
      final bool isNew = product.id.startsWith('prod_');

      final Map<String, dynamic> payload = <String, dynamic>{
        ...product.toMap(),
        'storeId': storeId,
        'merchantId': storeId,
        'isDeleted': false,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

      if (isNew) {
        final Document created = await _databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.colProducts,
          documentId: ID.unique(),
          data: payload,
        );
        return Product.fromMap(created.$id, created.data);
      }

      final Document updated = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colProducts,
        documentId: product.id,
        data: payload,
      );
      return Product.fromMap(updated.$id, updated.data);
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in saveProduct: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in saveProduct: $error');
      rethrow;
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colProducts,
        documentId: productId,
        data: <String, dynamic>{
          'isDeleted': true,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in deleteProduct: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in deleteProduct: $error');
      rethrow;
    }
  }
}

