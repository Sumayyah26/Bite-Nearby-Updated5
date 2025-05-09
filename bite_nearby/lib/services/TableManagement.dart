import 'package:cloud_firestore/cloud_firestore.dart';

// In TableManagement.dart
class TableManagement {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> checkTableAvailability(
      String restaurantId, int tableNumber) async {
    final tableId = '${restaurantId}_table_$tableNumber';
    final doc = await _firestore.collection('tables').doc(tableId).get();
    return doc.exists && doc.data()?['status'] == 'available';
  }

  Future<void> updateTableStatus(
      String restaurantId, int tableNumber, String status) async {
    final tableId = '${restaurantId}_table_$tableNumber';
    await _firestore.collection('tables').doc(tableId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getRestaurantTables(String restaurantId) {
    return _firestore
        .collection('tables')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots();
  }
}
