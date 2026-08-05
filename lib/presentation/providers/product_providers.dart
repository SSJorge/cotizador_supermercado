import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/product_offer.dart';
import '../../domain/repositories/product_repository.dart';
import '../../infrastructure/repositories/firestore_product_repository.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return FirestoreProductRepository(ref.watch(firestoreProvider));
});

final productsProvider = FutureProvider<List<ProductOffer>>((ref) async {
  return ref.watch(productRepositoryProvider).getAll();
});
