// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';

import '../config/appwrite_config.dart';
import '../models/schema/checkout_link_models.dart';
import '../models/schema/product_models.dart';
import '../sample/sample_schema_checkout_links.dart';
import '../sample/sample_schema_products.dart';
import '../services/active_store_resolver.dart';
import 'products_repository.dart';

abstract class CheckoutLinksRepository {
  Future<List<Product>> fetchProducts();
  Future<List<CheckoutLink>> fetchHistory();
  Future<CheckoutLink> saveLink(CheckoutLink link);
  Future<void> deleteLink(String linkId);
  Future<CheckoutLink> generateLink({
    required String storeId,
    required List<CheckoutLinkItem> items,
    required String extraChargeName,
    required String extraChargeAmount,
    required String discount,
    required int currentHistoryCount,
    required DateTime createdAt,
  });
}

class SampleCheckoutLinksRepository implements CheckoutLinksRepository {
  final List<CheckoutLink> _links = List<CheckoutLink>.from(
    sampleSchemaCheckoutLinks,
  );

  @override
  Future<List<Product>> fetchProducts() async => sampleSchemaProducts;

  @override
  Future<List<CheckoutLink>> fetchHistory() async {
    return List<CheckoutLink>.from(_links);
  }

  @override
  Future<CheckoutLink> saveLink(CheckoutLink link) async {
    final int index = _links.indexWhere((item) => item.linkId == link.linkId);
    if (index >= 0) {
      _links[index] = link;
    } else {
      _links.insert(0, link);
    }
    return link;
  }

  @override
  Future<void> deleteLink(String linkId) async {
    _links.removeWhere((item) => item.linkId == linkId);
  }

  @override
  Future<CheckoutLink> generateLink({
    required String storeId,
    required List<CheckoutLinkItem> items,
    required String extraChargeName,
    required String extraChargeAmount,
    required String discount,
    required int currentHistoryCount,
    required DateTime createdAt,
  }) async {
    final int next = currentHistoryCount + 1;
    final String linkId = next.toString().padLeft(5, '0');
    final num subtotal = items.fold<num>(
      0,
      (sum, item) => sum + (item.quantity * item.unitPrice),
    );
    final num extraCharge = num.tryParse(extraChargeAmount) ?? 0;
    final num discountAmount = num.tryParse(discount) ?? 0;

    final CheckoutLink link = CheckoutLink(
      linkId: linkId,
      merchantId: storeId,
      items: items,
      financials: CheckoutFinancials(
        subtotal: subtotal,
        shippingFee: extraCharge,
        discountAmount: discountAmount,
        totalAmount: subtotal + extraCharge - discountAmount,
        extraCharges: extraCharge > 0
            ? <CheckoutExtraCharge>[
                CheckoutExtraCharge(
                  name: extraChargeName.trim().isEmpty
                      ? 'Extra Charge'
                      : extraChargeName.trim(),
                  amount: extraCharge,
                ),
              ]
            : const <CheckoutExtraCharge>[],
        discount: discountAmount > 0
            ? CheckoutDiscount(
                type: CheckoutDiscountType.fixed,
                amountDeducted: discountAmount,
              )
            : null,
      ),
      status: CheckoutLinkStatus.active,
      createdAt: createdAt,
    );

    await saveLink(link);
    return link;
  }
}

class AppwriteCheckoutLinksRepository implements CheckoutLinksRepository {
  AppwriteCheckoutLinksRepository({
    required ActiveStoreResolver storeResolver,
    required ProductsRepository productsRepository,
    AppwriteConfig? config,
    Databases? databases,
  })  : _storeResolver = storeResolver,
        _productsRepository = productsRepository,
        _config = config ?? AppwriteConfig.instance,
        _databasesOverride = databases;

  final ActiveStoreResolver _storeResolver;
  final ProductsRepository _productsRepository;
  final AppwriteConfig _config;
  final Databases? _databasesOverride;

  Databases get _databases => _databasesOverride ?? _config.databases;

  @override
  Future<List<Product>> fetchProducts() => _productsRepository.fetchProducts();

  @override
  Future<List<CheckoutLink>> fetchHistory() async {
    try {
      final String storeId = await _storeResolver.resolve();
      final DocumentList docs = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colCheckoutLinks,
        queries: <String>[
          Query.equal('storeId', storeId),
          Query.equal('isDeleted', false),
          Query.orderDesc(r'$createdAt'),
          Query.limit(100),
        ],
      );
      return docs.documents
          .map((doc) => CheckoutLink.fromMap(doc.$id, doc.data))
          .toList(growable: false);
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in fetchHistory: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in fetchHistory: $error');
      rethrow;
    }
  }

  @override
  Future<CheckoutLink> saveLink(CheckoutLink link) async {
    try {
      final String storeId = await _storeResolver.resolve();
      final bool isNew = link.linkId.startsWith('cl_') || link.linkId.length <= 5;

      final Map<String, dynamic> payload = <String, dynamic>{
        ...link.toMap(),
        'storeId': storeId,
        'merchantId': storeId,
        'isDeleted': false,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

      if (isNew) {
        final Document created = await _databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.colCheckoutLinks,
          documentId: ID.unique(),
          data: payload,
        );
        return CheckoutLink.fromMap(created.$id, created.data);
      }

      final Document updated = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colCheckoutLinks,
        documentId: link.linkId,
        data: payload,
      );
      return CheckoutLink.fromMap(updated.$id, updated.data);
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in saveLink: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in saveLink: $error');
      rethrow;
    }
  }

  @override
  Future<void> deleteLink(String linkId) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colCheckoutLinks,
        documentId: linkId,
        data: <String, dynamic>{
          'isDeleted': true,
          'status': CheckoutLinkStatus.expired.name,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in deleteLink: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in deleteLink: $error');
      rethrow;
    }
  }

  @override
  Future<CheckoutLink> generateLink({
    required String storeId,
    required List<CheckoutLinkItem> items,
    required String extraChargeName,
    required String extraChargeAmount,
    required String discount,
    required int currentHistoryCount,
    required DateTime createdAt,
  }) async {
    final String resolvedStoreId = await _storeResolver.resolve();
    final num subtotal = items.fold<num>(
      0,
      (sum, item) => sum + (item.quantity * item.unitPrice),
    );
    final num extraCharge = num.tryParse(extraChargeAmount) ?? 0;
    final num discountAmount = num.tryParse(discount) ?? 0;

    final CheckoutLink link = CheckoutLink(
      linkId: 'cl_new',
      merchantId: resolvedStoreId,
      items: items,
      financials: CheckoutFinancials(
        subtotal: subtotal,
        shippingFee: extraCharge,
        discountAmount: discountAmount,
        totalAmount: subtotal + extraCharge - discountAmount,
        extraCharges: extraCharge > 0
            ? <CheckoutExtraCharge>[
                CheckoutExtraCharge(
                  name: extraChargeName.trim().isEmpty
                      ? 'Extra Charge'
                      : extraChargeName.trim(),
                  amount: extraCharge,
                ),
              ]
            : const <CheckoutExtraCharge>[],
        discount: discountAmount > 0
            ? CheckoutDiscount(
                type: CheckoutDiscountType.fixed,
                amountDeducted: discountAmount,
              )
            : null,
      ),
      status: CheckoutLinkStatus.active,
      createdAt: createdAt,
    );

    return saveLink(link);
  }
}


