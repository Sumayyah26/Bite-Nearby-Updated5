import 'package:flutter/material.dart';
import 'package:bite_nearby/services/OrderService.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  final List<Map<String, dynamic>> _currentOrderItems = [];

  List<Map<String, dynamic>> get currentOrderItems => _currentOrderItems;

  void addToOrder(Map<String, dynamic> item) {
    final existingIndex =
        _currentOrderItems.indexWhere((i) => i['id'] == item['id']);

    if (existingIndex >= 0) {
      _currentOrderItems[existingIndex]['quantity'] += item['quantity'];
    } else {
      _currentOrderItems.add(item);
    }
    notifyListeners();
  }

  // In OrderProvider.dart, update the submitOrder method:
  Future<String> submitOrder({
    required String restaurantId,
    required String restaurantName, // Add this parameter
    required int tableNumber,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    return await _orderService.createOrder(
      userId: userId,
      restaurantId: restaurantId,
      items: _currentOrderItems,
      tableNumber: tableNumber,
      restaurantName: restaurantName, // Pass it here
    );
  }
}
