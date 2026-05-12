import 'package:flutter_test/flutter_test.dart';

import 'package:merchantportal/data/models/schema/product_models.dart';
import 'package:merchantportal/data/repositories/products_repository.dart';

void main() {
  group('SampleProductsRepository', () {
    late SampleProductsRepository repo;

    setUp(() {
      repo = SampleProductsRepository();
    });

    test('fetchProducts returns a non-empty list from sample data', () async {
      final products = await repo.fetchProducts();
      expect(products, isNotEmpty);
    });

    test('saveProduct creates a new product', () async {
      final initial = await repo.fetchProducts();
      final initialCount = initial.length;

      const newProduct = Product(
        id: 'prod_test_new',
        merchantId: 'store_01',
        name: 'New Test Product',
        description: 'Created in test',
        basePrice: 999,
        attributes: ['Size'],
        variants: [],
      );

      await repo.saveProduct(newProduct);
      final updated = await repo.fetchProducts();
      expect(updated.length, initialCount + 1);
      expect(updated.any((p) => p.id == 'prod_test_new'), isTrue);
    });

    test('saveProduct updates an existing product', () async {
      final products = await repo.fetchProducts();
      final existing = products.first;

      final updated = Product(
        id: existing.id,
        merchantId: existing.merchantId,
        name: 'Updated Name',
        description: existing.description,
        basePrice: existing.basePrice,
        attributes: existing.attributes,
        variants: existing.variants,
      );

      await repo.saveProduct(updated);
      final result = await repo.fetchProducts();
      final found = result.firstWhere((p) => p.id == existing.id);
      expect(found.name, 'Updated Name');
    });

    test('deleteProduct removes the product', () async {
      final products = await repo.fetchProducts();
      final id = products.first.id;

      await repo.deleteProduct(id);
      final result = await repo.fetchProducts();
      expect(result.any((p) => p.id == id), isFalse);
    });

    test('saveProduct inserts at start for new items', () async {
      const newProduct = Product(
        id: 'prod_test_order',
        merchantId: 'store_01',
        name: 'First Product',
        description: '',
        basePrice: 100,
        attributes: [],
        variants: [],
      );

      await repo.saveProduct(newProduct);
      final result = await repo.fetchProducts();
      expect(result.first.id, 'prod_test_order');
    });
  });
}
