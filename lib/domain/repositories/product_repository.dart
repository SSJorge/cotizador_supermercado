import '../entities/product_offer.dart';

abstract class ProductRepository {
  Future<List<ProductOffer>> getAll();
  Future<void> create(ProductOffer product);
  Future<void> update(ProductOffer product);
  Future<void> delete(String id);
}
