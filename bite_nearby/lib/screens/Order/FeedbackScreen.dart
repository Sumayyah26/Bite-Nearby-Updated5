import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:bite_nearby/Coolors.dart';
import 'package:bite_nearby/services/FeedbackService.dart';
import 'package:provider/provider.dart';

class FeedbackScreen extends StatefulWidget {
  final String orderId;
  final String restaurantName;
  final List<Map<String, dynamic>> orderItems;

  const FeedbackScreen({
    Key? key,
    required this.orderId,
    required this.restaurantName,
    required this.orderItems,
  }) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  double _restaurantRating = 0;
  final Map<String, double> _itemRatings = {};
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize ratings for all items
    for (var item in widget.orderItems) {
      _itemRatings[item['id']] = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Coolors.ivoryCream,
      appBar: AppBar(
        backgroundColor: Coolors.charcoalBlack,
        title: Text(
          'Share your Feedback ${widget.restaurantName}',
          style: TextStyle(
            color: Coolors.lightOrange,
            fontSize: 20, // Slightly larger font size
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Coolors.lightOrange),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant Rating
              _buildSectionHeader('Overall Restaurant Experience'),
              _buildRatingBar(
                _restaurantRating,
                (rating) => setState(() => _restaurantRating = rating),
              ),
              const SizedBox(height: 32),

              // Items Rating
              if (widget.orderItems.isNotEmpty) ...[
                _buildSectionHeader('Rate Your Ordered Items'),
                const SizedBox(height: 12),
                ...widget.orderItems.map((item) => _buildItemRatingCard(item)),
                const SizedBox(height: 24),
              ],

              // Comments
              _buildSectionHeader('Additional Comments'),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Tell us about your experience...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Coolors.gold),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Coolors.gold,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SUBMIT FEEDBACK',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildRatingBar(double rating, Function(double) onRatingUpdate) {
    return RatingBar.builder(
      initialRating: rating,
      minRating: 1,
      itemCount: 5,
      itemSize: 36,
      itemPadding: const EdgeInsets.symmetric(horizontal: 4),
      itemBuilder: (context, _) => Icon(
        Icons.star,
        color: Coolors.gold,
      ),
      onRatingUpdate: onRatingUpdate,
    );
  }

  Widget _buildItemRatingCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white, // Changed card color to white
      elevation: 2, // Added slight elevation for better visibility
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                // Item Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item['imageUrl'] != null
                      ? Image.network(
                          item['imageUrl'],
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
                const SizedBox(width: 12),
                // Item Name
                Expanded(
                  child: Text(
                    item['title'] ?? 'Unknown Item',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87, // Ensure text is visible on white
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Rating Bar
            _buildRatingBar(
              _itemRatings[item['id']] ?? 0,
              (rating) => setState(() => _itemRatings[item['id']] = rating),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.fastfood, color: Coolors.gold),
    );
  }

  Future<void> _submitFeedback() async {
    if (_restaurantRating == 0) {
      _showSnackbar('Please rate the restaurant', isError: true);
      return;
    }

    if (_itemRatings.values.any((rating) => rating == 0)) {
      _showSnackbar('Please rate all items', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Provider.of<FeedbackService>(context, listen: false).submitFeedback(
        orderId: widget.orderId,
        restaurantRating: _restaurantRating,
        itemRatings: _itemRatings,
        comment: _commentController.text,
      );

      _showSnackbar('Thank you for your feedback!', isError: false);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackbar('Failed to submit feedback: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Coolors.wineRed : Coolors.oliveGreen,
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
