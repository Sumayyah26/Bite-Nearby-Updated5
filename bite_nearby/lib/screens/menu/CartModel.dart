class CartItem {
  final String id;
  final String title;
  final double price;
  final int quantity;
  final String restaurantId;
  final String? imageUrl; // Make sure this is properly passed

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.restaurantId,
    this.quantity = 1,
    this.imageUrl, // Include in constructor
  });

  CartItem copyWith({
    String? id,
    String? title,
    double? price,
    int? quantity,
    String? restaurantId,
    String? imageUrl,
  }) {
    return CartItem(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      restaurantId: restaurantId ?? this.restaurantId,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
