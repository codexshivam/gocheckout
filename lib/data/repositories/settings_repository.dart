// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';

import '../config/appwrite_config.dart';
import '../models/schema/merchant_models.dart';
import '../models/schema/private_settings_models.dart';
import '../sample/sample_schema_merchants.dart';
import '../sample/sample_schema_private_settings.dart';
import '../services/active_store_resolver.dart';
import '../services/auth_service.dart';
import '../services/store_migration_service.dart';

class SettingsPayload {
  const SettingsPayload({
    required this.merchant,
    required this.verification,
    required this.payments,
  });

  final Merchant merchant;
  final MerchantVerificationPrivateSettings verification;
  final MerchantPaymentsPrivateSettings payments;
}

abstract class SettingsRepository {
  Future<SettingsPayload> fetchSettings();
  Future<Merchant> updateMerchant(Merchant merchant);
  Future<MerchantVerificationPrivateSettings> updateVerification(
    MerchantVerificationPrivateSettings verification,
  );
  Future<MerchantPaymentsPrivateSettings> updatePayments(
    MerchantPaymentsPrivateSettings payments,
  );
  Future<MerchantPaymentsPrivateSettings> updateSinglePaymentMethod({
    required String providerKey,
    required PaymentMethodSecrets method,
  });
}

class SampleSettingsRepository implements SettingsRepository {
  Merchant _merchant = sampleMerchant;
  MerchantVerificationPrivateSettings _verification =
      sampleVerificationPrivateSettings;
  MerchantPaymentsPrivateSettings _payments = samplePaymentsPrivateSettings;

  @override
  Future<SettingsPayload> fetchSettings() async {
    return SettingsPayload(
      merchant: _merchant,
      verification: _verification,
      payments: _payments,
    );
  }

  @override
  Future<Merchant> updateMerchant(Merchant merchant) async {
    _merchant = merchant;
    return _merchant;
  }

  @override
  Future<MerchantVerificationPrivateSettings> updateVerification(
    MerchantVerificationPrivateSettings verification,
  ) async {
    _verification = verification;
    return _verification;
  }

  @override
  Future<MerchantPaymentsPrivateSettings> updatePayments(
    MerchantPaymentsPrivateSettings payments,
  ) async {
    _payments = MerchantPaymentsPrivateSettings(
      esewa: payments.esewa,
      khalti: payments.khalti,
      bankTransfer: payments.bankTransfer,
      cod: payments.cod,
      lastModifiedAt: DateTime.now().toUtc().toIso8601String(),
      lastModifiedBy: 'local@sample',
    );
    return _payments;
  }

  @override
  Future<MerchantPaymentsPrivateSettings> updateSinglePaymentMethod({
    required String providerKey,
    required PaymentMethodSecrets method,
  }) async {
    switch (providerKey) {
      case 'esewa':
        _payments = MerchantPaymentsPrivateSettings(
          esewa: method,
          khalti: _payments.khalti,
          bankTransfer: _payments.bankTransfer,
          cod: _payments.cod,
          lastModifiedAt: DateTime.now().toUtc().toIso8601String(),
          lastModifiedBy: 'local@sample',
        );
        break;
      case 'khalti':
        _payments = MerchantPaymentsPrivateSettings(
          esewa: _payments.esewa,
          khalti: method,
          bankTransfer: _payments.bankTransfer,
          cod: _payments.cod,
          lastModifiedAt: DateTime.now().toUtc().toIso8601String(),
          lastModifiedBy: 'local@sample',
        );
        break;
      case 'bankTransfer':
        _payments = MerchantPaymentsPrivateSettings(
          esewa: _payments.esewa,
          khalti: _payments.khalti,
          bankTransfer: method,
          cod: _payments.cod,
          lastModifiedAt: DateTime.now().toUtc().toIso8601String(),
          lastModifiedBy: 'local@sample',
        );
        break;
      case 'cod':
        _payments = MerchantPaymentsPrivateSettings(
          esewa: _payments.esewa,
          khalti: _payments.khalti,
          bankTransfer: _payments.bankTransfer,
          cod: method,
          lastModifiedAt: DateTime.now().toUtc().toIso8601String(),
          lastModifiedBy: 'local@sample',
        );
        break;
      default:
        throw ArgumentError.value(providerKey, 'providerKey', 'Unsupported provider.');
    }
    return _payments;
  }
}

class AppwriteSettingsRepository implements SettingsRepository {
  AppwriteSettingsRepository({
    required ActiveStoreResolver storeResolver,
    AppwriteConfig? config,
    AuthService? authService,
    StoreMigrationService? migrationService,
    Databases? databases,
  })  : _storeResolver = storeResolver,
        _config = config ?? AppwriteConfig.instance,
        _authService = authService ?? AuthService(config: config),
        _migrationService = migrationService ??
            StoreMigrationService(config: config, databases: databases),
        _databasesOverride = databases;

  final ActiveStoreResolver _storeResolver;
  final AppwriteConfig _config;
  final AuthService _authService;
  final StoreMigrationService _migrationService;
  final Databases? _databasesOverride;

  Databases get _databases => _databasesOverride ?? _config.databases;

  @override
  Future<SettingsPayload> fetchSettings() async {
    try {
      final String storeId = await _storeResolver.resolve();
      await _migrationService.ensureStoreDocumentShape(storeId);
      final Document storeDoc = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colStores,
        documentId: storeId,
      );

      final Map<String, dynamic> data = storeDoc.data;
      final Merchant merchant = Merchant.fromMap(
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

      final MerchantVerificationPrivateSettings verification =
          MerchantVerificationPrivateSettings.fromMap(
            (data['verificationDocs'] as Map<String, dynamic>?) ??
                <String, dynamic>{},
          );

      final MerchantPaymentsPrivateSettings payments =
          MerchantPaymentsPrivateSettings.fromMap(
            (data['paymentSettings'] as Map<String, dynamic>?) ??
                <String, dynamic>{},
          );

      return SettingsPayload(
        merchant: merchant,
        verification: verification,
        payments: payments,
      );
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in fetchSettings: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in fetchSettings: $error');
      rethrow;
    }
  }

  @override
  Future<Merchant> updateMerchant(Merchant merchant) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colStores,
        documentId: merchant.merchantId,
        data: <String, dynamic>{
          'businessName': merchant.businessName,
          'businessAddress': merchant.businessAddress,
          'contactInfo': merchant.contactInfo.toMap(),
          'storeLogoUrl': merchant.storeLogoUrl,
          'verificationStatus': merchant.verificationStatus.name,
          'stats': merchant.stats.toMap(),
        },
      );
      return merchant;
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in updateMerchant: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in updateMerchant: $error');
      rethrow;
    }
  }

  @override
  Future<MerchantVerificationPrivateSettings> updateVerification(
    MerchantVerificationPrivateSettings verification,
  ) async {
    try {
      final String storeId = await _storeResolver.resolve();
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colStores,
        documentId: storeId,
        data: <String, dynamic>{
          'verificationDocs': verification.toMap(),
        },
      );
      return verification;
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in updateVerification: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in updateVerification: $error');
      rethrow;
    }
  }

  @override
  Future<MerchantPaymentsPrivateSettings> updatePayments(
    MerchantPaymentsPrivateSettings payments,
  ) async {
    try {
      final String storeId = await _storeResolver.resolve();
      final User? user = await _authService.checkSession();
      final MerchantPaymentsPrivateSettings payload =
          MerchantPaymentsPrivateSettings(
            esewa: payments.esewa,
            khalti: payments.khalti,
            bankTransfer: payments.bankTransfer,
            cod: payments.cod,
            lastModifiedAt: DateTime.now().toUtc().toIso8601String(),
            lastModifiedBy: user?.email,
          );
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colStores,
        documentId: storeId,
        data: <String, dynamic>{
          'paymentSettings': payload.toMap(),
        },
      );
      return payload;
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in updatePayments: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in updatePayments: $error');
      rethrow;
    }
  }

  @override
  Future<MerchantPaymentsPrivateSettings> updateSinglePaymentMethod({
    required String providerKey,
    required PaymentMethodSecrets method,
  }) async {
    try {
      final String storeId = await _storeResolver.resolve();
      final User? user = await _authService.checkSession();
      final Document storeDoc = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colStores,
        documentId: storeId,
      );

      final MerchantPaymentsPrivateSettings existing =
          MerchantPaymentsPrivateSettings.fromMap(
            (storeDoc.data['paymentSettings'] as Map<String, dynamic>?) ??
                <String, dynamic>{},
          );

      final MerchantPaymentsPrivateSettings payload;
      switch (providerKey) {
        case 'esewa':
          payload = MerchantPaymentsPrivateSettings(
            esewa: method,
            khalti: existing.khalti,
            bankTransfer: existing.bankTransfer,
            cod: existing.cod,
            lastModifiedAt: DateTime.now().toUtc().toIso8601String(),
            lastModifiedBy: user?.email,
          );
          break;
        case 'khalti':
          payload = MerchantPaymentsPrivateSettings(
            esewa: existing.esewa,
            khalti: method,
            bankTransfer: existing.bankTransfer,
            cod: existing.cod,
            lastModifiedAt: DateTime.now().toUtc().toIso8601String(),
            lastModifiedBy: user?.email,
          );
          break;
        case 'bankTransfer':
          payload = MerchantPaymentsPrivateSettings(
            esewa: existing.esewa,
            khalti: existing.khalti,
            bankTransfer: method,
            cod: existing.cod,
            lastModifiedAt: DateTime.now().toUtc().toIso8601String(),
            lastModifiedBy: user?.email,
          );
          break;
        case 'cod':
          payload = MerchantPaymentsPrivateSettings(
            esewa: existing.esewa,
            khalti: existing.khalti,
            bankTransfer: existing.bankTransfer,
            cod: method,
            lastModifiedAt: DateTime.now().toUtc().toIso8601String(),
            lastModifiedBy: user?.email,
          );
          break;
        default:
          throw ArgumentError.value(
            providerKey,
            'providerKey',
            'Unsupported provider.',
          );
      }

      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colStores,
        documentId: storeId,
        data: <String, dynamic>{
          'paymentSettings': payload.toMap(),
        },
      );
      return payload;
    } on AppwriteException catch (error) {
      debugPrint(
        'AppwriteException in updateSinglePaymentMethod($providerKey): ${error.message}',
      );
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in updateSinglePaymentMethod: $error');
      rethrow;
    }
  }
}
