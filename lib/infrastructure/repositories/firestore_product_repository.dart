import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/product_offer.dart';
import '../../domain/repositories/product_repository.dart';

class FirestoreProductRepository implements ProductRepository {
  final FirebaseFirestore firestore;

  FirestoreProductRepository(this.firestore);

  CollectionReference<Map<String, dynamic>> get _products =>
      firestore.collection('products');

  @override
  Future<List<ProductOffer>> getAll() async {
    final snapshot = await _products.get();

    return snapshot.docs
        .map((doc) => ProductOffer.fromMap(doc.id, doc.data()))
        .where(
          (product) =>
              product.name.isNotEmpty &&
              product.price > 0 &&
              product.quantity > 0,
        )
        .toList();
  }

  @override
  Future<void> create(ProductOffer product) async {
    await _products.add({
      ...product.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> update(ProductOffer product) async {
    if (product.id.isEmpty) {
      throw ArgumentError('No se puede actualizar un producto sin id.');
    }

    await _products.doc(product.id).update({
      ...product.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> delete(String id) async {
    await _products.doc(id).delete();
  }
}
