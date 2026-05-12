import '../models/schema/merchant_models.dart';

const Merchant sampleMerchant = Merchant(
  merchantId: 'm_001',
  businessName: 'Yuva Store',
  businessAddress: 'Gongabu, Kathmandu',
  contactInfo: MerchantContactInfo(
    email: 'hello@yuvastore.com',
    phone: '9801000001',
    whatsapp: '9801000001',
  ),
  storeLogoUrl: '',
  verificationStatus: MerchantVerificationStatus.verified,
  stats: MerchantStats(totalSales: 150000, totalOrders: 2184, rtoCount: 179),
);
