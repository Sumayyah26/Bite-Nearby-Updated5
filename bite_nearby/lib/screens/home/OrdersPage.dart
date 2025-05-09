import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bite_nearby/Coolors.dart';
import 'package:bite_nearby/screens/Order/FeedbackListener.dart';

class OrdersPage extends StatefulWidget {
  final String orderId;
  final String restaurantName;
  final bool showHistory;

  const OrdersPage({
    super.key,
    required this.orderId,
    required this.restaurantName,
    this.showHistory = false,
  });

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Stream<dynamic> _dataStream;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<QuerySnapshot>? _feedbackSubscription;
  @override
  void initState() {
    super.initState();
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _setupOrderStream(userId);

    // Initialize feedback listener after UI frame is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FeedbackListenerService.initialize(context);
    });
  }

  @override
  void dispose() {
    _feedbackSubscription?.cancel();
    super.dispose();
  }

  void _setupOrderStream(String userId) {
    if (widget.orderId.isEmpty) {
      final collection = widget.showHistory ? 'pastOrders' : 'activeOrders';
      _dataStream = FirebaseFirestore.instance
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      _dataStream = _getOrderStream(widget.orderId);
    }
  }

  Stream<DocumentSnapshot> _getOrderStream(String orderId) {
    return FirebaseFirestore.instance
        .collection('activeOrders')
        .doc(orderId)
        .snapshots()
        .asyncMap((activeDoc) {
      if (activeDoc.exists) return activeDoc;
      return FirebaseFirestore.instance
          .collection('pastOrders')
          .doc(orderId)
          .get();
    });
  }

  Widget _buildOrdersHeader() {
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
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              'Your Orders',
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Coolors.lightOrange,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Coolors.charcoalBlack,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Coolors.gold,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: 'Current Orders'),
                Tab(text: 'Order History'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: widget.orderId.isEmpty ? 2 : 1,
      child: Scaffold(
        appBar: null,
        backgroundColor: Coolors.ivoryCream,
        body: Column(
          children: [
            widget.orderId.isEmpty
                ? _buildOrdersHeader()
                : _buildOrderDetailHeader(),
            Expanded(
              child: widget.orderId.isEmpty
                  ? TabBarView(
                      children: [
                        _buildOrderList(false),
                        _buildOrderList(true),
                      ],
                    )
                  : _buildOrderDetails(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailHeader() {
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
          'Order #${widget.orderId.substring(0, 8)}',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList(bool showHistory) {
    final collection = showHistory ? 'pastOrders' : 'activeOrders';
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text('Please sign in to view orders'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data?.docs ?? [];
        if (orders.isEmpty) {
          return Center(
            child: Text(
              showHistory ? 'No past orders' : 'No active orders',
              style: const TextStyle(fontSize: 18),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index].data() as Map<String, dynamic>;
            return _buildOrderCard(orders[index].id, order);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(String orderId, Map<String, dynamic> order) {
    return Card(
      color: const Color.fromARGB(255, 255, 255, 255),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrdersPage(
                orderId: orderId,
                restaurantName: order['restaurantName'] ?? 'Restaurant',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${orderId.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Chip(
                    label: Text(order['status'] ?? 'pending'),
                    backgroundColor: _getStatusColor(order['status']),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order['restaurantName'] ?? 'Restaurant',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (order['tableNumber'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Table: ${order['tableNumber']}'),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order['items']?.length ?? 0} items',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    '${order['total']?.toStringAsFixed(2) ?? '0.00'} SR',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _dataStream as Stream<DocumentSnapshot>,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Order not found'));
        }

        final order = snapshot.data!.data() as Map<String, dynamic>;
        return _buildSingleOrder(order);
      },
    );
  }

  Widget _buildSingleOrder(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
    final total = order['total'] ?? 0.0;
    final tableNumber = order['tableNumber'] ?? '--';
    final completedAt = order['completedAt'] as Timestamp?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusIndicator(status),
          const SizedBox(height: 24),
          Text(
            'Order from ${order['restaurantName'] ?? 'Restaurant'}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('Table: $tableNumber'),
          if (completedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Completed on ${_formatDate(completedAt.toDate())}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Your Order:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Column(
            children: items.map((item) => _buildOrderItem(item)).toList(),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '$total SR',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          item['imageUrl'] != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item['imageUrl'],
                    width: 50,
                    height: 50,
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
                  child: const Icon(Icons.fastfood, color: Colors.grey),
                ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? 'Item',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text('${item['quantity']} × ${item['price']} SR'),
              ],
            ),
          ),
          Text(
            '${(item['price'] * item['quantity']).toStringAsFixed(2)} SR',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status.toLowerCase()) {
      case 'preparing':
        statusColor = Colors.orange;
        statusIcon = Icons.timer;
        statusText = 'Preparing your order';
        break;
      case 'ready':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Ready for pickup';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        statusText = 'Order completed';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Order received';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              Text(
                'Status updates in real-time',
                style: TextStyle(color: statusColor.withOpacity(0.8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'preparing':
        return Colors.orange[100]!;
      case 'ready':
        return Colors.green[100]!;
      case 'completed':
        return Colors.blue[100]!;
      default:
        return Colors.grey[200]!;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
