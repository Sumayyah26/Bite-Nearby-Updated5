import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitFeedback({
    required String orderId,
    required double restaurantRating,
    required Map<String, double> itemRatings, // Map of itemId to rating
    String? comment,
  }) async {
    try {
      // Convert item ratings to a format suitable for Firestore
      final itemRatingsData = itemRatings.map((itemId, rating) =>
          MapEntry(itemId, {'rating': rating, 'itemId': itemId}));

      // Save detailed feedback
      await _firestore.collection('feedback').add({
        'orderId': orderId,
        'restaurantRating': restaurantRating,
        'itemRatings': itemRatingsData,
        'comment': comment ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update the order document to mark feedback as submitted
      await _firestore.collection('pastOrders').doc(orderId).update({
        'feedbackSubmitted': true,
      });

      // Update restaurant's average rating (optional)
      await _updateRestaurantRating(orderId, restaurantRating);

      // Update items' average ratings (optional)
      await _updateItemRatings(itemRatings);
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }

  Future<void> _updateRestaurantRating(String orderId, double rating) async {
    try {
      // Get the order to find the restaurantId
      final orderDoc =
          await _firestore.collection('pastOrders').doc(orderId).get();
      final restaurantId = orderDoc['restaurantId'];

      if (restaurantId != null) {
        // Get current restaurant data
        final restaurantDoc =
            await _firestore.collection('restaurants').doc(restaurantId).get();
        final currentData = restaurantDoc.data() ?? {};

        // Calculate new average rating
        final currentRating = currentData['rating'] ?? 0.0;
        final ratingCount = currentData['ratingCount'] ?? 0;
        final newRating =
            ((currentRating * ratingCount) + rating) / (ratingCount + 1);

        // Update restaurant document
        await _firestore.collection('restaurants').doc(restaurantId).update({
          'rating': newRating,
          'ratingCount': ratingCount + 1,
        });
      }
    } catch (e) {
      // Fail silently for rating updates - not critical path
      print('Error updating restaurant rating: $e');
    }
  }

  Future<void> _updateItemRatings(Map<String, double> itemRatings) async {
    try {
      final batch = _firestore.batch();

      for (final entry in itemRatings.entries) {
        final itemRef = _firestore.collection('menuItems').doc(entry.key);

        // Get current item data
        final itemDoc = await itemRef.get();
        if (itemDoc.exists) {
          final currentData = itemDoc.data() ?? {};

          // Calculate new average rating
          final currentRating = currentData['rating'] ?? 0.0;
          final ratingCount = currentData['ratingCount'] ?? 0;
          final newRating =
              ((currentRating * ratingCount) + entry.value) / (ratingCount + 1);

          // Add to batch update
          batch.update(itemRef, {
            'rating': newRating,
            'ratingCount': ratingCount + 1,
          });
        }
      }

      // Commit all updates at once
      await batch.commit();
    } catch (e) {
      // Fail silently for rating updates - not critical path
      print('Error updating item ratings: $e');
    }
  }
}
