import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../services/review_service.dart';
import '../../models/review_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class ProviderReviewsScreen extends StatefulWidget {
  final String providerId;
  final String providerName;

  const ProviderReviewsScreen({
    super.key,
    required this.providerId,
    required this.providerName,
  });

  @override
  _ProviderReviewsScreenState createState() => _ProviderReviewsScreenState();
}

class _ProviderReviewsScreenState extends State<ProviderReviewsScreen> {
  final ReviewService _reviewService = ReviewService();
  List<Review> _reviews = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _error;
  String _sortBy = 'recent'; // recent, rating_high, rating_low

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);

    try {
      final reviewsData =
          await _reviewService.getProviderReviews(widget.providerId);
      final statsData = await _reviewService.getReviewStats(widget.providerId);

      setState(() {
        _reviews = reviewsData.map((data) => Review.fromJson(data)).toList();
        _stats = statsData;
        _isLoading = false;
        _sortReviews();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _sortReviews() {
    switch (_sortBy) {
      case 'rating_high':
        _reviews.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'rating_low':
        _reviews.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case 'recent':
      default:
        _reviews.sort((a, b) => b.date.compareTo(a.date));
        break;
    }
  }

  void _changeSorting(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      _sortReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.providerName} Reviews'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: _changeSorting,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'recent',
                child: Text('Most Recent'),
              ),
              const PopupMenuItem(
                value: 'rating_high',
                child: Text('Highest Rating'),
              ),
              const PopupMenuItem(
                value: 'rating_low',
                child: Text('Lowest Rating'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadReviews,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Statistics header
                    _buildStatsHeader(),

                    // Reviews list
                    Expanded(
                      child: _reviews.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.reviews,
                                      size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('No reviews yet'),
                                  Text('Be the first to leave a review!'),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _reviews.length,
                              itemBuilder: (context, index) {
                                return ReviewCard(
                                  review: _reviews[index],
                                  onLike: () => _likeReview(_reviews[index]),
                                  onReport: () =>
                                      _reportReview(_reviews[index]),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatsHeader() {
    final averageRating = (_stats['averageRating'] ?? 0.0).toDouble();
    final totalReviews = _stats['totalReviews'] ?? 0;
    final breakdown = _stats['ratingBreakdown'] ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          Row(
            children: [
              // Overall rating
              Expanded(
                child: Column(
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    RatingBarIndicator(
                      rating: averageRating,
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      itemCount: 5,
                      itemSize: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalReviews reviews',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Rating breakdown
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    for (int i = 5; i >= 1; i--)
                      _buildRatingBar(
                          i, breakdown[i.toString()] ?? 0, totalReviews),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    final percentage = total > 0 ? count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$stars'),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 16, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              count.toString(),
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _likeReview(Review review) async {
    try {
      await _reviewService.likeReview(review.id);
      _loadReviews(); // Refresh to show updated like count
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to like review: $e')),
      );
    }
  }

  Future<void> _reportReview(Review review) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => ReportDialog(),
    );

    if (reason != null) {
      try {
        await _reviewService.reportReview(review.id, reason);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review reported successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to report review: $e')),
        );
      }
    }
  }
}

class ReviewCard extends StatelessWidget {
  final Review review;
  final VoidCallback onLike;
  final VoidCallback onReport;

  const ReviewCard({
    super.key,
    required this.review,
    required this.onLike,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and rating
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    review.clientName[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review.clientName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (review.isVerified)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.verified,
                                size: 16,
                                color: Colors.blue,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        timeago.format(review.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag, size: 16),
                          SizedBox(width: 8),
                          Text('Report'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'report') onReport();
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Rating stars
            Row(
              children: [
                RatingBarIndicator(
                  rating: review.rating,
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  itemCount: 5,
                  itemSize: 16,
                ),
                const SizedBox(width: 8),
                if (review.serviceType.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      review.serviceType,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Review text
            Text(
              review.review,
              style: const TextStyle(fontSize: 14),
            ),

            // Images (if any)
            if (review.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(review.images[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Provider response (if any)
            if (review.providerResponse != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.business, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Provider Response',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review.providerResponse!,
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (review.responseDate != null)
                      Text(
                        timeago.format(review.responseDate!),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                TextButton.icon(
                  onPressed: onLike,
                  icon: Icon(
                    review.isLikedByUser
                        ? Icons.thumb_up
                        : Icons.thumb_up_outlined,
                    size: 16,
                    color:
                        review.isLikedByUser ? Colors.blue : Colors.grey[600],
                  ),
                  label: Text(
                    'Helpful (${review.likes})',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          review.isLikedByUser ? Colors.blue : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key});

  @override
  _ReportDialogState createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selectedReason;
  final List<String> _reasons = [
    'Inappropriate content',
    'Spam',
    'Fake review',
    'Personal information',
    'Harassment',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Review'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Why are you reporting this review?'),
          const SizedBox(height: 16),
          ..._reasons.map((reason) => RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
              )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedReason != null
              ? () => Navigator.pop(context, _selectedReason)
              : null,
          child: const Text('Report'),
        ),
      ],
    );
  }
}
