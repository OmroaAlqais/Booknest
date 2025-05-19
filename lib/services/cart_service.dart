import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? get user => FirebaseAuth.instance.currentUser;

  CollectionReference get _cartRef =>
      _firestore.collection('users').doc(user?.uid).collection('cart');

  Future<void> addToCart(String bookId, Map<String, dynamic> bookData) async {
    final doc = await _cartRef.doc(bookId).get();
    if (doc.exists) {
      await _cartRef.doc(bookId).update({
        'quantity': FieldValue.increment(1),
      });
    } else {
      await _cartRef.doc(bookId).set({
        ...bookData,
        'quantity': 1,
      });
    }
  }

  Future<void> removeFromCart(String bookId) async {
    await _cartRef.doc(bookId).delete();
  }

  Future<void> updateQuantity(String bookId, int quantity) async {
    await _cartRef.doc(bookId).update({'quantity': quantity});
  }

  Stream<QuerySnapshot> get cartStream => _cartRef.snapshots();
}
