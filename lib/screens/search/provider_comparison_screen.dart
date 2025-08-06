import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../services/provider_service.dart';
import '../../models/provider_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ProviderComparisonScreen extends StatefulWidget {
  final String serviceType;
  final LatLng location;

  const ProviderComparisonScreen({
    Key? key,
    required this.serviceType,
    required this.location,
  }) : super(key: key);

  @override
  _ProviderComparisonScreenState createState() => _ProviderComparisonScreenState();
}

class _ProviderComparisonScreenState extends State<ProviderComparisonScreen> {
  List<Map<String, dynamic>> _providers = [];
  bool _isLoading = true;
  String? _error;
  String _sortBy = 'price'; // price, rating, distance

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() => _isLoading = true);
    
    try {
      final providers = await ProviderService.compareProviderPrices(
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
        serviceType: widget.serviceType,
      );
      
      setState(() {
        _providers = providers;
        _isLoading = false;
        _sortProviders();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _sortProviders() {
    switch (_sortBy) {
      case 'price':
        _providers.sort((a, b) => (a['basePrice'] ?? 0).compareTo(b['basePrice'] ?? 0));
        break;
      case 'rating':
        _providers.sort((a, b) => (b['averageRating'] ?? 0).compareTo(a['averageRating'] ?? 0));
        break;
      case 'distance':
        _providers.sort((a, b) => (a['distance'] ?? 0).compareTo(b['distance'] ?? 0));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compare ${widget.serviceType} Providers'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortProviders();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'price', child: Text('Sort by Price')),
              const PopupMenuItem(value: 'rating', child: Text('Sort by Rating')),
              const PopupMenuItem(value: 'distance', child: Text('Sort by Distance')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _providers.isEmpty
                  ? _buildEmptyState()
                  : _buildComparisonList(),
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
            onPressed: _loadProviders,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No providers found for comparison'),
        ],
      ),
    );
  }

  Widget _buildComparisonList() {
    return Column(
      children: [
        // Header with stats
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            children: [
              Text(
                '${_providers.length} providers found',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text('Sorted by: ${_sortBy.toUpperCase()}'),
            ],
          ),
        ),
        
        // Comparison table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.blue[50],
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('Provider', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Rating', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Distance', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        
        // Provider comparison list
        Expanded(
          child: ListView.builder(
            itemCount: _providers.length,
            itemBuilder: (context, index) {
              final provider = _providers[index];
              final isLowest = _isLowestPrice(provider, index);
              final isHighestRated = _isHighestRated(provider, index);
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Card(
                  elevation: isLowest || isHighestRated ? 4 : 1,
                  color: isLowest ? Colors.green[50] : 
                         isHighestRated ? Colors.orange[50] : null,
                  child: InkWell(
                    onTap: () => _showProviderDetails(provider),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Provider info
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      provider['businessName'] ?? 'Unknown',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (provider['isVerified'] ?? false)
                                          const Icon(Icons.verified, size: 16, color: Colors.blue),
                                        if (provider['isAvailable'] ?? false)
                                          Container(
                                            margin: const EdgeInsets.only(left: 4),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green[100],
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Text('Available', style: TextStyle(fontSize: 10)),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Price
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'KES ${provider['basePrice'] ?? 'N/A'}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isLowest ? Colors.green[700] : null,
                                      ),
                                    ),
                                    if (isLowest)
                                      Text(
                                        'Lowest',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              
                              // Rating
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.star, size: 16, color: Colors.amber),
                                        Text('${(provider['averageRating'] ?? 0).toStringAsFixed(1)}'),
                                      ],
                                    ),
                                    Text(
                                      '(${provider['totalRatings'] ?? 0})',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                    if (isHighestRated)
                                      Text(
                                        'Top Rated',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.orange[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              
                              // Distance
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${(provider['distance'] / 1000).toStringAsFixed(1)} km',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          
                          // Additional info
                          if (provider['specialOffers'] != null || provider['responseTime'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  if (provider['specialOffers'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red[100],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        provider['specialOffers'],
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  if (provider['responseTime'] != null)
                                    Text(
                                      'Avg response: ${provider['responseTime']}',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isLowestPrice(Map<String, dynamic> provider, int index) {
    if (_providers.isEmpty) return false;
    final prices = _providers
        .where((p) => p['basePrice'] != null)
        .map((p) => p['basePrice'] as num)
        .toList();
    if (prices.isEmpty) return false;
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    return provider['basePrice'] == minPrice;
  }

  bool _isHighestRated(Map<String, dynamic> provider, int index) {
    if (_providers.isEmpty) return false;
    final ratings = _providers
        .where((p) => p['averageRating'] != null)
        .map((p) => p['averageRating'] as num)
        .toList();
    if (ratings.isEmpty) return false;
    final maxRating = ratings.reduce((a, b) => a > b ? a : b);
    return provider['averageRating'] == maxRating && maxRating >= 4.5;
  }

  void _showProviderDetails(Map<String, dynamic> provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ProviderDetailModal(provider: provider),
    );
  }
}

class ProviderDetailModal extends StatelessWidget {
  final Map<String, dynamic> provider;

  const ProviderDetailModal({Key? key, required this.provider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                child: Text((provider['businessName'] ?? 'P')[0].toUpperCase()),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider['businessName'] ?? 'Unknown Provider',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(provider['serviceOffered'] ?? ''),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Quick stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Rating', '${(provider['averageRating'] ?? 0).toStringAsFixed(1)}⭐'),
              _buildStatItem('Price', 'KES ${provider['basePrice'] ?? 'N/A'}'),
              _buildStatItem('Distance', '${(provider['distance'] / 1000).toStringAsFixed(1)} km'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Description
          if (provider['description'] != null)
            Text(provider['description']),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to booking screen
                  },
                  child: const Text('Book Now'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to provider profile
                  },
                  child: const Text('View Profile'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
