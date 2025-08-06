import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../services/rating_service.dart';
import '../../services/review_service.dart';

class RatingScreen extends StatefulWidget {
  final String bookingId;
  final String providerId;
  final String? providerName;
  final String? serviceType;

  const RatingScreen({
    Key? key,
    required this.bookingId,
    required this.providerId,
    this.providerName,
    this.serviceType,
  }) : super(key: key);

  @override
  _RatingScreenState createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double _rating = 0.0;
  String _comment = '';
  bool _isSubmitting = false;
  bool _submitBoth = true; // Submit both rating and review

  final RatingService _ratingService = RatingService();
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _commentController = TextEditingController();

  // Category ratings for detailed feedback
  final Map<String, double> _categoryRatings = {
    'Quality': 0.0,
    'Timeliness': 0.0,
    'Communication': 0.0,
    'Professionalism': 0.0,
  };

  Future<void> _submitFeedback() async {
    if (_rating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Submit rating
      await _ratingService.createRating({
        'bookingId': widget.bookingId,
        'providerId': widget.providerId,
        'score': _rating,
        'comment': _comment,
        'serviceType': widget.serviceType ?? '',
        'categoryRatings': _categoryRatings,
      });

      // Submit detailed review if text is provided
      if (_submitBoth && _comment.isNotEmpty) {
        await _reviewService.submitReview(
          providerId: widget.providerId,
          bookingId: widget.bookingId,
          rating: _rating,
          reviewText: _comment, // Fixed parameter name
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit feedback: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildCategoryRating(String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              category,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: RatingBar.builder(
              initialRating: _categoryRatings[category] ?? 0.0,
              minRating: 0,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 25,
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _categoryRatings[category] = rating;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Service'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue[100],
                      child: Text(
                        (widget.providerName ?? 'P')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.providerName ?? 'Service Provider',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.serviceType != null)
                            Text(
                              widget.serviceType!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Overall rating
            const Text(
              'How was your overall experience?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Center(
              child: Column(
                children: [
                  RatingBar.builder(
                    initialRating: _rating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 40,
                    glow: true,
                    glowColor: Colors.amber.withOpacity(0.5),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      setState(() => _rating = rating);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getRatingText(_rating),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _getRatingColor(_rating),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Category ratings
            const Text(
              'Rate specific aspects:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: _categoryRatings.keys
                      .map((category) => _buildCategoryRating(category))
                      .toList(),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Comment section
            const Text(
              'Share your experience (optional):',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Tell others about your experience...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              onChanged: (value) => _comment = value,
            ),
            
            const SizedBox(height: 16),
            
            // Submit options
            CheckboxListTile(
              title: const Text('Also submit as a public review'),
              subtitle: const Text('Help other users find great service providers'),
              value: _submitBoth,
              onChanged: (value) {
                setState(() {
                  _submitBoth = value ?? true;
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Feedback',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Skip option
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Skip for now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Excellent!';
    if (rating >= 3.5) return 'Good';
    if (rating >= 2.5) return 'Average';
    if (rating >= 1.5) return 'Poor';
    if (rating >= 1.0) return 'Very Poor';
    return 'Tap to rate';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return Colors.green;
    if (rating >= 3.0) return Colors.orange;
    if (rating >= 2.0) return Colors.red;
    return Colors.grey;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
