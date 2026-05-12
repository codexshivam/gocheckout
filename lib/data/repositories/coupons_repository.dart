// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';

import '../config/appwrite_config.dart';
import '../models/schema/coupon_models.dart';
import '../sample/sample_schema_coupons.dart';
import '../services/active_store_resolver.dart';

abstract class CouponsRepository {
  Future<List<Coupon>> fetchCoupons();
  Future<Coupon> saveCoupon(Coupon coupon);
  Future<void> deleteCoupon(String couponId);
}

class SampleCouponsRepository implements CouponsRepository {
  final List<Coupon> _coupons = List<Coupon>.from(sampleSchemaCoupons);

  @override
  Future<List<Coupon>> fetchCoupons() async {
    return List<Coupon>.from(_coupons);
  }

  @override
  Future<Coupon> saveCoupon(Coupon coupon) async {
    final int index = _coupons.indexWhere((c) => c.id == coupon.id);
    if (index >= 0) {
      _coupons[index] = coupon;
    } else {
      _coupons.insert(0, coupon);
    }
    return coupon;
  }

  @override
  Future<void> deleteCoupon(String couponId) async {
    _coupons.removeWhere((c) => c.id == couponId);
  }
}

class AppwriteCouponsRepository implements CouponsRepository {
  AppwriteCouponsRepository({
    required ActiveStoreResolver storeResolver,
    AppwriteConfig? config,
    Databases? databases,
  }) : _storeResolver = storeResolver,
       _config = config ?? AppwriteConfig.instance,
       _databasesOverride = databases;

  final ActiveStoreResolver _storeResolver;
  final AppwriteConfig _config;
  final Databases? _databasesOverride;

  Databases get _databases => _databasesOverride ?? _config.databases;

  Future<void> _ensureUniqueCode({
    required String merchantId,
    required String normalizedCode,
    String? ignoreCouponId,
  }) async {
    final DocumentList collisions = await _databases.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.colCoupons,
      queries: <String>[
        Query.equal('merchantId', merchantId),
        Query.equal('code', normalizedCode),
      ],
    );

    final bool hasCollision = collisions.documents.any(
      (doc) => ignoreCouponId == null || doc.$id != ignoreCouponId,
    );
    if (hasCollision) {
      throw AppwriteException(
        'Coupon code already exists for this store.',
        409,
        null,
      );
    }
  }

  @override
  Future<List<Coupon>> fetchCoupons() async {
    try {
      final String merchantId = await _storeResolver.resolve();
      final DocumentList docs = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colCoupons,
        queries: <String>[
          Query.equal('merchantId', merchantId),
          Query.equal('isDeleted', false),
        ],
      );

      return docs.documents
          .map((doc) => Coupon.fromMap(doc.$id, doc.data))
          .toList(growable: false);
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in fetchCoupons: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in fetchCoupons: $error');
      rethrow;
    }
  }

  @override
  Future<Coupon> saveCoupon(Coupon coupon) async {
    try {
      final String merchantId = await _storeResolver.resolve();
      final String normalizedCode = coupon.code.trim().toUpperCase();

      await _ensureUniqueCode(
        merchantId: merchantId,
        normalizedCode: normalizedCode,
        ignoreCouponId: coupon.id.startsWith('cp_') ? null : coupon.id,
      );

      final String? userEmail = await _storeResolver.resolveUserEmail();
      final DateTime now = DateTime.now().toUtc();
      final Coupon payload = Coupon(
        id: coupon.id,
        merchantId: merchantId,
        code: normalizedCode,
        discountType: coupon.discountType,
        discountValue: coupon.discountValue,
        usageTracker: coupon.usageTracker,
        lifecycleStatus: coupon.lifecycleStatus,
        startsAt: coupon.startsAt,
        endsAt: coupon.endsAt,
        minOrderAmount: coupon.minOrderAmount,
        maxDiscountAmount: coupon.maxDiscountAmount,
        perCustomerLimit: coupon.perCustomerLimit,
        allowedCustomerPhone: coupon.allowedCustomerPhone,
        createdBy: coupon.createdBy ?? userEmail,
        createdAt: coupon.createdAt ?? now.toIso8601String(),
        updatedAt: now.toIso8601String(),
        isDeleted: false,
      );

      final bool isNew = coupon.id.startsWith('cp_');
      if (isNew) {
        final Document created = await _databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.colCoupons,
          documentId: ID.unique(),
          data: payload.toMap(),
        );
        return Coupon.fromMap(created.$id, created.data);
      }

      final Document updated = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colCoupons,
        documentId: coupon.id,
        data: payload.toMap(),
      );
      return Coupon.fromMap(updated.$id, updated.data);
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in saveCoupon: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in saveCoupon: $error');
      rethrow;
    }
  }

  @override
  Future<void> deleteCoupon(String couponId) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colCoupons,
        documentId: couponId,
        data: <String, dynamic>{
          'isDeleted': true,
          'lifecycleStatus': CouponLifecycleStatus.archived.name,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in deleteCoupon: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in deleteCoupon: $error');
      rethrow;
    }
  }
}
