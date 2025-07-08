import 'package:flutter/material.dart';
import '../../services/review_service.dart';
// Make sure that the file '../../services/review_service.dart' exists and defines a class named ReviewService.
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ReviewServiceScreen extends StatefulWidget {
  final String bookingId;
  final String providerId;

  const ReviewServiceScreen({
    Key? key,
    required this.bookingId,
    required this.providerId,
  }) : super(key: key);

  @override
  _ReviewServiceScreenState createState() => _ReviewServiceScreenState();
}

class _ReviewServiceScreenState extends State<ReviewServiceScreen> {
  final _reviewController = TextEditingController();
  double _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Write Review')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() => _rating = rating);
              },
            ),
            SizedBox(height: 16),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write your review here...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitReview,
              child: Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please select a rating')));
      return;
    }

    try {
      await ReviewService().submitReview(
        providerId: widget.providerId,
        bookingId: widget.bookingId,
        rating: _rating,
        review: _reviewController.text,
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to submit review: $e')));
    }
  }
}
