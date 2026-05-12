import '../models/schema/product_models.dart';

const List<Product> sampleSchemaProducts = [
  Product(
    id: 'prod_001',
    merchantId: 'm_001',
    name: 'Yuva Watch',
    description: 'Everyday steel watch',
    basePrice: 2200,
    attributes: ['Color'],
    variants: [
      ProductVariant(
        variantId: 'v_001_red',
        options: {'Color': 'Red'},
        price: 2200,
        inventoryCount: 20,
        isInventoryTracked: true,
        imageUrl: 'https://r2.example.com/products/watch-red.png',
      ),
      ProductVariant(
        variantId: 'v_001_blue',
        options: {'Color': 'Blue'},
        price: 2250,
        inventoryCount: 23,
        isInventoryTracked: true,
        imageUrl: 'https://r2.example.com/products/watch-blue.png',
      ),
    ],
  ),
  Product(
    id: 'prod_002',
    merchantId: 'm_001',
    name: 'Urban Bottle',
    description: 'Insulated water bottle',
    basePrice: 1100,
    attributes: ['Color'],
    variants: [
      ProductVariant(
        variantId: 'v_002_default',
        options: {'Color': 'Default'},
        price: 1100,
        inventoryCount: 120,
        isInventoryTracked: true,
        imageUrl: 'https://r2.example.com/products/bottle.png',
      ),
    ],
  ),
  Product(
    id: 'prod_003',
    merchantId: 'm_001',
    name: 'Flex Tee',
    description: 'Cotton t-shirt',
    basePrice: 950,
    attributes: ['Size'],
    variants: [
      ProductVariant(
        variantId: 'v_003_m',
        options: {'Size': 'M'},
        price: 950,
        inventoryCount: 140,
        isInventoryTracked: true,
        imageUrl: 'https://r2.example.com/products/flex-tee-m.png',
      ),
      ProductVariant(
        variantId: 'v_003_l',
        options: {'Size': 'L'},
        price: 950,
        inventoryCount: 140,
        isInventoryTracked: true,
        imageUrl: 'https://r2.example.com/products/flex-tee-l.png',
      ),
    ],
  ),
];
