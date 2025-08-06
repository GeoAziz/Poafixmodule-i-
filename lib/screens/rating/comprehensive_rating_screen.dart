import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../services/review_service.dart';
import '../../services/rating_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ComprehensiveRatingScreen extends StatefulWidget {
  final String bookingId;
  final String providerId;
  final String? providerName;
  final String? serviceType;

  const ComprehensiveRatingScreen({
    Key? key,
    required this.bookingId,
    required this.providerId,
    this.providerName,
    this.serviceType,
  }) : super(key: key);

  @override
  _ComprehensiveRatingScreenState createState() => _ComprehensiveRatingScreenState();
}

class _ComprehensiveRatingScreenState extends State<ComprehensiveRatingScreen> {
  double _overallRating = 0.0;
  String _reviewText = '';
  bool _isSubmitting = false;
  List<File> _images = [];
  final ImagePicker _picker = ImagePicker();

  // Category ratings for detailed feedback
  final Map<String, double> _categoryRatings = {
    'Quality': 0.0,
    'Timeliness': 0.0,
    'Communication': 0.0,
    'Professionalism': 0.0,
    'Value for Money': 0.0,
  };

  // Quick feedback options
  final Map<String, bool> _quickFeedback = {
    'Arrived on time': false,
    'Professional conduct': false,
    'Clean work area': false,
    'Fair pricing': false,
    'Would recommend': false,
    'Fixed the problem': false,
  };

  final RatingService _ratingService = RatingService();
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _reviewController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rate ${widget.providerName ?? "Service Provider"}'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service summary
            _buildServiceSummary(),
            
            const SizedBox(height: 24),
            
            // Overall rating
            _buildOverallRating(),
            
            const SizedBox(height: 24),
            
            // Category ratings
            _buildCategoryRatings(),
            
            const SizedBox(height: 24),
            
            // Quick feedback
            _buildQuickFeedback(),
            
            const SizedBox(height: 24),
            
            // Written review
            _buildWrittenReview(),
            
            const SizedBox(height: 24),
            
            // Photo upload
            _buildPhotoUpload(),
            
            const SizedBox(height: 32),
            
            // Submit button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Completed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Provider: ${widget.providerName ?? "Unknown"}'),
            Text('Service: ${widget.serviceType ?? "Service"}'),
            const SizedBox(height: 8),
            const Text(
              'How was your experience?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallRating() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Rating',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  RatingBar.builder(
                    initialRating: _overallRating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 40,
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _overallRating = rating;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getRatingDescription(_overallRating),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRatings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detailed Ratings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._categoryRatings.keys.map((category) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category, style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  RatingBar.builder(
                    initialRating: _categoryRatings[category]!,
                    minRating: 0,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 20,
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
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFeedback() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Feedback',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _quickFeedback.keys.map((feedback) => FilterChip(
                label: Text(feedback),
                selected: _quickFeedback[feedback]!,
                onSelected: (selected) {
                  setState(() {
                    _quickFeedback[feedback] = selected;
                  });
                },
                selectedColor: Colors.blue[100],
                checkmarkColor: Colors.blue[700],
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWrittenReview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Write a Review',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share details about your experience (optional)',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Tell others about your experience...',
                border: OutlineInputBorder(),
                helperText: 'Help others by sharing specific details',
              ),
              onChanged: (value) {
                setState(() {
                  _reviewText = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoUpload() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Photos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Show others the completed work (optional)',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (_images.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _images.length) {
                      return _buildAddPhotoButton();
                    }
                    return _buildPhotoItem(_images[index], index);
                  },
                ),
              )
            else
              _buildAddPhotoButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: _pickImage,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo, color: Colors.grey),
              Text('Add Photo', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoItem(File image, int index) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              image,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _overallRating > 0 && !_isSubmitting ? _submitRatingAndReview : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Submit Rating & Review',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _pickImage() async {
    if (_images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 photos allowed')),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _images.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  String _getRatingDescription(double rating) {
    if (rating == 0) return 'Tap to rate';
    if (rating <= 1) return 'Poor';
    if (rating <= 2) return 'Fair';
    if (rating <= 3) return 'Good';
    if (rating <= 4) return 'Very Good';
    return 'Excellent';
  }

  Future<void> _submitRatingAndReview() async {
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide an overall rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Submit rating with category breakdowns
      await _ratingService.createRating({
        'bookingId': widget.bookingId,
        'providerId': widget.providerId,
        'score': _overallRating,
        'comment': _reviewText,
        'serviceType': widget.serviceType ?? '',
        'categoryRatings': _categoryRatings,
        'quickFeedback': _quickFeedback,
      });

      // Submit detailed review if text is provided
      if (_reviewText.isNotEmpty) {
        await _reviewService.submitReview(
          providerId: widget.providerId,
          bookingId: widget.bookingId,
          rating: _overallRating,
          review: _reviewText,
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
          SnackBar(content: Text('Error submitting feedback: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}
