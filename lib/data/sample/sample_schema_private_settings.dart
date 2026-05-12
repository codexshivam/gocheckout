import '../models/schema/private_settings_models.dart';

const MerchantVerificationPrivateSettings sampleVerificationPrivateSettings =
    MerchantVerificationPrivateSettings(
      citizenshipUrl: 'https://r2.example.com/docs/citizenship-front-back.pdf',
      businessRegUrl: 'https://r2.example.com/docs/business-reg.pdf',
      panUrl: 'https://r2.example.com/docs/pan.pdf',
    );

const MerchantPaymentsPrivateSettings samplePaymentsPrivateSettings =
    MerchantPaymentsPrivateSettings(
      esewa: PaymentMethodSecrets(
        isActive: true,
        credentials: {
          'merchantCode': 'ESEWA_001',
          'secretKey': 'esewa-secret-key',
        },
      ),
      khalti: PaymentMethodSecrets(
        isActive: false,
        credentials: {
          'publicKey': 'khalti-public-key',
          'secretKey': 'khalti-secret-key',
        },
      ),
      bankTransfer: PaymentMethodSecrets(
        isActive: true,
        credentials: {
          'bankName': 'Nabil Bank',
          'accountName': 'Yuva Store Pvt Ltd',
          'accountNumber': '1234567890',
        },
      ),
      cod: PaymentMethodSecrets(
        isActive: true,
        credentials: {},
      ),
    );
