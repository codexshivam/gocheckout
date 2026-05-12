class ProductVariant {
  const ProductVariant({
    required this.variantId,
    required this.options,
    required this.price,
    required this.inventoryCount,
    required this.isInventoryTracked,
    required this.imageUrl,
  });

  final String variantId;
  final Map<String, String> options;
  final num price;
  final int inventoryCount;
  final bool isInventoryTracked;
  final String imageUrl;

  Map<String, dynamic> toMap() => {
    'variantId': variantId,
    'options': options,
    'price': price,
    'inventoryCount': inventoryCount,
    'isInventoryTracked': isInventoryTracked,
    'imageUrl': imageUrl,
  };

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      variantId: map['variantId'] as String? ?? '',
      options: ((map['options'] as Map<String, dynamic>?) ?? const {}).map(
        (k, v) => MapEntry(k, v.toString()),
      ),
      price: map['price'] as num? ?? 0,
      inventoryCount: map['inventoryCount'] as int? ?? 0,
      isInventoryTracked: map['isInventoryTracked'] as bool? ?? true,
      imageUrl: map['imageUrl'] as String? ?? '',
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.merchantId,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.attributes,
    required this.variants,
  });

  final String id;
  final String merchantId;
  String get storeId => merchantId;
  final String name;
  final String description;
  final num basePrice;
  final List<String> attributes;
  final List<ProductVariant> variants;

  Map<String, dynamic> toMap() => {
    'storeId': merchantId,
    'merchantId': merchantId,
    'name': name,
    'description': description,
    'basePrice': basePrice,
    'attributes': attributes,
    'variants': variants.map((v) => v.toMap()).toList(),
  };

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    final String resolvedStoreId =
        map['storeId'] as String? ?? map['merchantId'] as String? ?? '';
    return Product(
      id: id,
      merchantId: resolvedStoreId,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      basePrice: map['basePrice'] as num? ?? 0,
      attributes: ((map['attributes'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      variants: ((map['variants'] as List<dynamic>?) ?? const [])
          .map((e) => ProductVariant.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
