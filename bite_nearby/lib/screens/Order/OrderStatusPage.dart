import 'package:bite_nearby/screens/home/OrdersPage.dart';
import 'package:flutter/material.dart';
import 'package:bite_nearby/Coolors.dart';

class OrderStatusPage extends StatelessWidget {
  final String restaurantName;

  const OrderStatusPage({super.key, required this.restaurantName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Status'),
        backgroundColor: Colors.green[100],
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Coolors.oliveGreen),
            const SizedBox(height: 20),
            Text(
              'Order Sent to $restaurantName!', // Fixed interpolation
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your order has been received and is being prepared',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrdersPage(
                      orderId: '',
                      restaurantName: '',
                    ),
                  ),
                );
              },
              child: const Text('View Orders'),
            )
          ],
        ),
      ),
    );
  }
}
