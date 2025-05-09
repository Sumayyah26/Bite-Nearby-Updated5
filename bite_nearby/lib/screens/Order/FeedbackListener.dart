import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bite_nearby/screens/Order/FeedbackScreen.dart';

class FeedbackListenerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static StreamSubscription<QuerySnapshot>? _subscription;
  static bool _isFeedbackScreenVisible = false; // 🔐 Add this line

  static void initialize(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Cancel any existing subscription if active
    _subscription?.cancel();

    try {
      _subscription = _firestore
          .collection('pastOrders')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .where('feedbackSubmitted', isEqualTo: false)
          .orderBy('servedAt', descending: true)
          .limit(1) // ✅ Optional improvement
          .snapshots()
          .listen((snapshot) {
        print("📡 Snapshot received with ${snapshot.docs.length} doc(s)");
        if (snapshot.docs.isNotEmpty) {
          final order = snapshot.docs.first;
          print("🎯 Showing feedback screen for order: ${order.id}");
          _showFeedbackScreen(context, order);
        }
      });
    } catch (e) {
      print("🔥 Feedback listener failed: $e");
    }
  }

  static void _showFeedbackScreen(
      BuildContext context, DocumentSnapshot order) {
    if (_isFeedbackScreenVisible) return;
    _isFeedbackScreenVisible = true;

    // Convert order items to the required format
    final List<Map<String, dynamic>> orderItems =
        (order['items'] as List<dynamic>)
            .map((item) => {
                  'id': item['id'],
                  'title': item['title'],
                  'imageUrl': item['imageUrl'],
                })
            .toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (context) => FeedbackScreen(
              orderId: order.id,
              restaurantName: order['restaurantName'] ?? 'Unnamed Restaurant',
              orderItems: orderItems,
            ),
            fullscreenDialog: true,
          ),
        )
            .then((_) {
          _isFeedbackScreenVisible = false;
        });
      } catch (e) {
        _isFeedbackScreenVisible = false;
        print("Navigation error: $e");
      }
    });
  }

  static void dispose() {
    _subscription?.cancel();
    _isFeedbackScreenVisible = false; // 🔁 Reset when disposing
  }
}
