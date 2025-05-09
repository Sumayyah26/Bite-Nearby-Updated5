import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bite_nearby/Coolors.dart';
import 'CartProvider.dart';
import 'CartModel.dart';
import 'package:bite_nearby/screens/Order/OrderConfirmationPage.dart';

class CartPage extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;

  const CartPage({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  Widget _buildHeader() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Coolors.charcoalBlack,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Center(
        child: Text(
          'Cart',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Coolors.ivoryCream,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      backgroundColor: Coolors.ivoryCream,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Consumer<CartProvider>(
              builder: (context, cart, _) {
                final restaurantItems =
                    cart.getItemsForRestaurant(restaurantId);
                final totalAmount = cart.getTotalForRestaurant(restaurantId);

                if (restaurantItems.isEmpty) {
                  return const Center(
                    child: Text(
                      'Your cart is empty',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.only(top: 10),
                        itemCount: restaurantItems.length,
                        itemBuilder: (ctx, index) {
                          final item = restaurantItems[index];
                          return _buildCartItem(context, item, cart);
                        },
                      ),
                    ),
                    _buildTotalSection(totalAmount),
                    _buildCheckoutButton(context),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
      BuildContext context, CartItem item, CartProvider cart) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            // Improved Image Container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[100],
                image: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(item.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: item.imageUrl == null || item.imageUrl!.isEmpty
                  ? Center(
                      child: Icon(Icons.fastfood,
                          size: 40, color: Colors.grey[400]),
                    )
                  : null,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${item.price.toStringAsFixed(2)} SR',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, size: 20),
                        onPressed: () {
                          if (item.quantity > 1) {
                            cart.updateQuantity(
                              item.id,
                              item.restaurantId,
                              item.quantity - 1,
                            );
                          } else {
                            cart.removeItem(item.id, item.restaurantId);
                          }
                        },
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.quantity.toString(),
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, size: 20),
                        onPressed: () {
                          cart.updateQuantity(
                            item.id,
                            item.restaurantId,
                            item.quantity + 1,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Coolors.wineRed),
              onPressed: () {
                cart.removeItem(item.id, item.restaurantId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection(double totalAmount) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${totalAmount.toStringAsFixed(2)} SR',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Coolors.oliveGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: 24),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            final cart = Provider.of<CartProvider>(context, listen: false);
            final totalAmount = cart.getTotalForRestaurant(restaurantId);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderConfirmationPage(
                  restaurantId: restaurantId,
                  restaurantName: restaurantName,
                  totalAmount: totalAmount,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Coolors.gold,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Proceed to Checkout',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
