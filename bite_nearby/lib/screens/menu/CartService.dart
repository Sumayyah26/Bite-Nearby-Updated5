import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addToCart(String restaurantId, Map<String, dynamic> item) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Check if item already exists in cart
    final existingItem = await _firestore
        .collection('Users')
        .doc(user.uid)
        .collection('Cart')
        .where('itemId', isEqualTo: item['id'])
        .get();

    if (existingItem.docs.isNotEmpty) {
      // Update quantity if item exists
      await _firestore
          .collection('Users')
          .doc(user.uid)
          .collection('Cart')
          .doc(existingItem.docs.first.id)
          .update({
        'quantity': FieldValue.increment(1),
      });
    } else {
      // Add new item to cart
      await _firestore
          .collection('Users')
          .doc(user.uid)
          .collection('Cart')
          .add({
        ...item,
        'restaurantId': restaurantId,
        'quantity': 1,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getCartItems() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('Users')
        .doc(user.uid)
        .collection('Cart')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        ...data,
        'cartItemId': doc.id, // Add document ID for easy reference
      };
    }).toList();
  }

  Future<void> removeFromCart(String cartItemId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('Users')
        .doc(user.uid)
        .collection('Cart')
        .doc(cartItemId)
        .delete();
  }

  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (newQuantity <= 0) {
      await removeFromCart(cartItemId);
    } else {
      await _firestore
          .collection('Users')
          .doc(user.uid)
          .collection('Cart')
          .doc(cartItemId)
          .update({'quantity': newQuantity});
    }
  }

  Future<void> clearCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('Users')
        .doc(user.uid)
        .collection('Cart')
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
