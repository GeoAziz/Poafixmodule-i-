import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../services/review_service.dart';
import '../../models/review_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class ComprehensiveReviewScreen extends StatefulWidget {
  final String providerId;
  final String providerName;

  const ComprehensiveReviewScreen({
    Key? key,
    required this.providerId,
    required this.providerName,
  }) : super(key: key);

  @override
  _ComprehensiveReviewScreenState createState() => _ComprehensiveReviewScreenState();
}

class _ComprehensiveReviewScreenState extends State<ComprehensiveReviewScreen>
    with TickerProviderStateMixin {
  final ReviewService _reviewService = ReviewService();
  List<Review> _reviews = [];
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;
  String? _error;
  String _sortBy = 'recent';
  String _filterBy = 'all';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final futures = await Future.wait([
        _reviewService.getProviderReviews(widget.providerId),
        _reviewService.getReviewStats(widget.providerId),
        _reviewService.getReviewAnalytics(widget.providerId),
      ]);
      
      setState(() {
        _reviews = (futures[0] as List).map((data) => Review.fromJson(data)).toList();
        _stats = futures[1] as Map<String, dynamic>;
        _analytics = futures[2] as Map<String, dynamic>;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Review> filteredReviews = List.from(_reviews);

    // Apply rating filter
    switch (_filterBy) {
      case 'excellent':
        filteredReviews = filteredReviews.where((r) => r.rating >= 4.5).toList();
        break;
      case 'good':
        filteredReviews = filteredReviews.where((r) => r.rating >= 3.5 && r.rating < 4.5).toList();
        break;
      case 'poor':
        filteredReviews = filteredReviews.where((r) => r.rating < 3.5).toList();
        break;
      case 'with_photos':
        filteredReviews = filteredReviews.where((r) => r.images.isNotEmpty).toList();
        break;
      case 'verified':
        filteredReviews = filteredReviews.where((r) => r.isVerified).toList();
        break;
    }

    // Apply sorting
    switch (_sortBy) {
      case 'rating_high':
        filteredReviews.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'rating_low':
        filteredReviews.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case 'helpful':
        filteredReviews.sort((a, b) => b.likes.compareTo(a.likes));
        break;
      case 'recent':
      default:
        filteredReviews.sort((a, b) => b.date.compareTo(a.date));
        break;
    }

    setState(() {
      _reviews = filteredReviews;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.providerName} Reviews'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Reviews'),
            Tab(text: 'Analytics'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value.startsWith('sort_')) {
                setState(() {
                  _sortBy = value.replaceFirst('sort_', '');
                  _applyFilters();
                });
              } else if (value.startsWith('filter_')) {
                setState(() {
                  _filterBy = value.replaceFirst('filter_', '');
                  _applyFilters();
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sort_recent',
                child: Text('Sort: Most Recent'),
              ),
              const PopupMenuItem(
                value: 'sort_rating_high',
                child: Text('Sort: Highest Rating'),
              ),
              const PopupMenuItem(
                value: 'sort_rating_low',
                child: Text('Sort: Lowest Rating'),
              ),
              const PopupMenuItem(
                value: 'sort_helpful',
                child: Text('Sort: Most Helpful'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'filter_all',
                child: Text('Filter: All Reviews'),
              ),
              const PopupMenuItem(
                value: 'filter_excellent',
                child: Text('Filter: Excellent (4.5+)'),
              ),
              const PopupMenuItem(
                value: 'filter_good',
                child: Text('Filter: Good (3.5-4.4)'),
              ),
              const PopupMenuItem(
                value: 'filter_poor',
                child: Text('Filter: Poor (<3.5)'),
              ),
              const PopupMenuItem(
                value: 'filter_with_photos',
                child: Text('Filter: With Photos'),
              ),
              const PopupMenuItem(
                value: 'filter_verified',
                child: Text('Filter: Verified Only'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildReviewsTab(),
                    _buildAnalyticsTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall rating summary
          _buildRatingSummary(),
          
          const SizedBox(height: 24),
          
          // Rating breakdown
          _buildRatingBreakdown(),
          
          const SizedBox(height: 24),
          
          // Recent highlights
          _buildRecentHighlights(),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    final averageRating = _stats['averageRating']?.toDouble() ?? 0.0;
    final totalReviews = _stats['totalReviews'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Overall Rating',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                      ),
                      RatingBarIndicator(
                        rating: averageRating,
                        itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 20,
                      ),
                      const SizedBox(height: 8),
                      Text('Based on $totalReviews reviews'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _buildRatingRow(5, _stats['rating5'] ?? 0, totalReviews),
                      _buildRatingRow(4, _stats['rating4'] ?? 0, totalReviews),
                      _buildRatingRow(3, _stats['rating3'] ?? 0, totalReviews),
                      _buildRatingRow(2, _stats['rating2'] ?? 0, totalReviews),
                      _buildRatingRow(1, _stats['rating1'] ?? 0, totalReviews),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(int stars, int count, int total) {
    final percentage = total > 0 ? (count / total) : 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$stars'),
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
          const SizedBox(width: 8),
          Text('$count'),
        ],
      ),
    );
  }

  Widget _buildRatingBreakdown() {
    if (_analytics['categoryBreakdown'] == null) return Container();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rating Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...(_analytics['categoryBreakdown'] as Map<String, dynamic>).entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(entry.key),
                    ),
                    Expanded(
                      flex: 3,
                      child: RatingBarIndicator(
                        rating: (entry.value as num).toDouble(),
                        itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 16,
                      ),
                    ),
                    Text(
                      (entry.value as num).toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentHighlights() {
    final recentExcellent = _reviews.where((r) => r.rating >= 4.5).take(3).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Highlights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...recentExcellent.map((review) => _buildHighlightItem(review)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightItem(Review review) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            child: Text(review.clientName[0].toUpperCase()),
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
                    const SizedBox(width: 8),
                    RatingBarIndicator(
                      rating: review.rating,
                      itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                      itemCount: 5,
                      itemSize: 12,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  review.review,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  timeago.format(review.date),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Column(
      children: [
        // Filter summary
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            children: [
              Text(
                '${_reviews.length} reviews',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text('Sorted by: ${_sortBy.replaceAll('_', ' ')}'),
            ],
          ),
        ),
        
        // Reviews list
        Expanded(
          child: ListView.builder(
            itemCount: _reviews.length,
            itemBuilder: (context, index) {
              return _buildReviewCard(_reviews[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  child: Text(review.clientName[0].toUpperCase()),
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
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Verified',
                                style: TextStyle(fontSize: 10, color: Colors.blue),
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: review.rating,
                            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                            itemCount: 5,
                            itemSize: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeago.format(review.date),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Review text
            Text(review.review),
            
            // Images
            if (review.images.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
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
              ),
            
            // Actions
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _likeReview(review),
                  icon: Icon(
                    review.isLikedByUser ? Icons.thumb_up : Icons.thumb_up_outlined,
                    size: 16,
                  ),
                  label: Text('${review.likes}'),
                ),
                TextButton.icon(
                  onPressed: () => _reportReview(review),
                  icon: const Icon(Icons.flag_outlined, size: 16),
                  label: const Text('Report'),
                ),
              ],
            ),
            
            // Provider response
            if (review.providerResponse != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Response from Provider',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(review.providerResponse!),
                    if (review.responseDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          timeago.format(review.responseDate!),
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Analytics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Key metrics
          if (_analytics['trends'] != null)
            _buildTrendsCard(),
          
          const SizedBox(height: 16),
          
          // Common themes
          if (_analytics['commonThemes'] != null)
            _buildCommonThemesCard(),
        ],
      ),
    );
  }

  Widget _buildTrendsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rating Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Add trend visualization here
            Text('Average rating has ${_analytics['trends']['direction']} by ${_analytics['trends']['change']}% this month'),
          ],
        ),
      ),
    );
  }

  Widget _buildCommonThemesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Common Themes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_analytics['commonThemes'] as List<dynamic>)
                  .map((theme) => Chip(
                        label: Text(theme['word']),
                        avatar: CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          child: Text('${theme['count']}'),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _likeReview(Review review) async {
    try {
      await _reviewService.likeReview(review.id);
      _loadData(); // Refresh to show updated like count
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class ReportDialog extends StatefulWidget {
  @override
  _ReportDialogState createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String _selectedReason = '';
  final List<String> _reasons = [
    'Inappropriate content',
    'Spam',
    'Fake review',
    'Harassment',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Review'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _reasons.map((reason) => RadioListTile<String>(
          title: Text(reason),
          value: reason,
          groupValue: _selectedReason,
          onChanged: (value) {
            setState(() {
              _selectedReason = value!;
            });
          },
        )).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedReason.isNotEmpty
              ? () => Navigator.pop(context, _selectedReason)
              : null,
          child: const Text('Report'),
        ),
      ],
    );
  }
}
