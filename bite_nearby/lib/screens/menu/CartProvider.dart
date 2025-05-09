import 'package:flutter/material.dart';
import 'CartModel.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => [..._items];

  List<CartItem> getItemsForRestaurant(String restaurantId) {
    return _items.where((item) => item.restaurantId == restaurantId).toList();
  }

  double getTotalForRestaurant(String restaurantId) {
    return _items
        .where((item) => item.restaurantId == restaurantId)
        .fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  void addItem(CartItem newItem) {
    print('Attempting to add item: ${newItem.title}');
    final existingIndex = _items.indexWhere(
      (item) =>
          item.id == newItem.id && item.restaurantId == newItem.restaurantId,
    );

    if (existingIndex >= 0) {
      print('Item exists, increasing quantity');
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + 1,
      );
    } else {
      print('Adding new item to cart');
      _items.add(newItem);
    }
    print('Current cart items: ${_items.length}');
    notifyListeners();
  }

  void removeItem(String itemId, String restaurantId) {
    _items.removeWhere(
      (item) => item.id == itemId && item.restaurantId == restaurantId,
    );
    notifyListeners();
  }

  void updateQuantity(String itemId, String restaurantId, int newQuantity) {
    final index = _items.indexWhere(
      (item) => item.id == itemId && item.restaurantId == restaurantId,
    );

    if (index >= 0) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = _items[index].copyWith(quantity: newQuantity);
      }
      notifyListeners();
    }
  }

  void clearRestaurantCart(String restaurantId) {
    _items.removeWhere((item) => item.restaurantId == restaurantId);
    notifyListeners();
  }

  void clearAll() {
    _items = [];
    notifyListeners();
  }
}
