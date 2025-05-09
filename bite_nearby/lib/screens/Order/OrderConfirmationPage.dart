import 'package:bite_nearby/screens/home/OrdersPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bite_nearby/screens/menu/CartProvider.dart';
import 'package:bite_nearby/services/OrderService.dart';
import 'package:bite_nearby/services/TableManagement.dart';
import 'package:bite_nearby/Coolors.dart';

class OrderConfirmationPage extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final double totalAmount;

  const OrderConfirmationPage({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.totalAmount,
  });

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage> {
  final _formKey = GlobalKey<FormState>();
  final _tableNumberController = TextEditingController();
  final _tableManagement = TableManagement();
  bool _isSubmitting = false;
  bool _isTableAvailable = true;

  @override
  void dispose() {
    _tableNumberController.dispose();
    super.dispose();
  }

  Future<void> _checkTableAvailability() async {
    if (_tableNumberController.text.isEmpty) return;

    final tableNumber = int.tryParse(_tableNumberController.text);
    if (tableNumber == null || tableNumber < 1 || tableNumber > 20) return;

    final isAvailable = await _tableManagement.checkTableAvailability(
        widget.restaurantId, tableNumber);

    setState(() => _isTableAvailable = isAvailable);
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final tableNumber = int.parse(_tableNumberController.text);

    final isAvailable = await _tableManagement.checkTableAvailability(
        widget.restaurantId, tableNumber);

    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'This table is currently occupied. Please choose another table.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final cart = Provider.of<CartProvider>(context, listen: false);
      final items = cart.getItemsForRestaurant(widget.restaurantId);

      final orderItems = items
          .map((item) => {
                'id': item.id,
                'title': item.title,
                'price': item.price,
                'quantity': item.quantity,
                'imageUrl': item.imageUrl,
              })
          .toList();

      final orderService = OrderService();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final orderId = await orderService.createOrder(
        userId: user.uid,
        restaurantId: widget.restaurantId,
        restaurantName: widget.restaurantName,
        items: orderItems,
        tableNumber: tableNumber,
      );

      await _tableManagement.updateTableStatus(
          widget.restaurantId, tableNumber, 'occupied');

      cart.clearRestaurantCart(widget.restaurantId);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrdersPage(
            orderId: orderId,
            restaurantName: widget.restaurantName,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

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
          'Confirm Order',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Coolors.lightOrange,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final items = cart.getItemsForRestaurant(widget.restaurantId);

    return Scaffold(
      appBar: null,
      backgroundColor: Coolors.ivoryCream,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Items List
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Card(
                            color: Colors.white,
                            margin: EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: item.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item.imageUrl!,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.fastfood),
                                    ),
                              title: Text(
                                item.title,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  '${item.quantity} × ${item.price.toStringAsFixed(2)} SR'),
                              trailing: Text(
                                '${(item.price * item.quantity).toStringAsFixed(2)} SR',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Coolors.oliveGreen),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Table Number Input
                    TextFormField(
                      controller: _tableNumberController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        labelText: 'Table Number',
                        labelStyle: TextStyle(
                            color: Coolors.charcoalBlack), // Label color
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                Coolors.gold, // Border color when not focused
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Coolors
                                .gold, // Border color when enabled but not focused
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Coolors
                                .lightOrange, // Border color when focused
                            width: 2.0,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Coolors
                                .wineRed, // Border color when in error state
                            width: 1.5,
                          ),
                        ),
                        suffixIcon: _tableNumberController.text.isNotEmpty
                            ? Icon(
                                _isTableAvailable ? Icons.check : Icons.close,
                                color: _isTableAvailable
                                    ? Colors.green
                                    : Colors.red,
                              )
                            : null,
                        hintText: 'Enter table number (1-20)',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your table number';
                        }
                        final num = int.tryParse(value);
                        if (num == null) {
                          return 'Please enter a valid number';
                        }
                        if (num < 1 || num > 20) {
                          return 'Please enter a number between 1-20';
                        }
                        if (!_isTableAvailable) {
                          return 'Table is currently occupied';
                        }
                        return null;
                      },
                      onChanged: (value) => _checkTableAvailability(),
                    ),
                    SizedBox(height: 20),

                    // Total and Submit Button
                    Container(
                      padding: EdgeInsets.all(16),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total: ${widget.totalAmount.toStringAsFixed(2)} SR',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Coolors.charcoalBlack,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Coolors.gold,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    'Send Order',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
