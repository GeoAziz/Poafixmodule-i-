import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../models/provider_model.dart';
import '../services/enhanced_proximity_service.dart';
import '../services/booking_service.dart';
import '../services/location_service.dart';

class EnhancedBookingScreen extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final User user;

  const EnhancedBookingScreen({
    super.key, // Use super parameter for key
    required this.serviceId,
    required this.serviceName,
    required this.user,
  });

  @override
  EnhancedBookingScreenState createState() =>
      EnhancedBookingScreenState(); // Make state class public
}

class EnhancedBookingScreenState extends State<EnhancedBookingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _currentStep = 0;
  List<ProviderModel> _nearbyProviders = [];
  ProviderModel? _selectedProvider;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _description = '';
  bool _isUrgent = false;
  bool _isLoading = false;
  Position? _currentLocation;

  final List<String> _stepTitles = [
    'Select Provider',
    'Choose Date & Time',
    'Service Details',
    'Review & Confirm',
    'Booking Confirmed'
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _loadNearbyProviders();
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadNearbyProviders() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      _currentLocation = await LocationService().getCurrentLocation();

      // Ensure authentication header is sent and correct API usage
      final List<ProviderModel> providers = await ProximityService().getNearbyProviders(
        serviceType: widget.serviceId,
        latitude: _currentLocation?.latitude ?? 0.0,
        longitude: _currentLocation?.longitude ?? 0.0,
        radiusKm: 10.0,
      );

      if (mounted) {
        setState(() {
          _nearbyProviders = providers;
          _isLoading = false;
        });
      }
      if (providers.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No providers found nearby.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading providers: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildAppBar(),
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildProviderSelection(),
                _buildDateTimeSelection(),
                _buildServiceDetails(),
                _buildReviewConfirm(),
                _buildBookingConfirmed(),
              ],
            ),
          ),
          if (_currentStep < 4) _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book ${widget.serviceName}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _stepTitles[_currentStep],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
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

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: List.generate(5, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? (isCompleted ? Colors.green : Color(0xFF6366F1))
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProviderSelection() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Finding nearby providers...'),
          ],
        ),
      );
    }

    if (_nearbyProviders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text('No providers found in your area'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadNearbyProviders,
              child: Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: EdgeInsets.all(20),
        itemCount: _nearbyProviders.length,
        itemBuilder: (context, index) {
          final provider = _nearbyProviders[index];
          final isSelected = _selectedProvider?.id == provider.id;

          return Container(
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Color(0xFF6366F1) : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.08),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    _selectedProvider = provider;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: provider.profileImage != null
                            ? NetworkImage(provider.profileImage!)
                            : null,
                        child: provider.profileImage == null
                            ? Text(provider.name.substring(0, 1).toUpperCase())
                            : null,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.star, size: 16, color: Colors.amber),
                                SizedBox(width: 4),
                                Text('${provider.rating}'),
                                SizedBox(width: 8),
                                Text(
                                  '${provider.distance?.toStringAsFixed(1)} km away',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'KSh ${provider.hourlyRate}/hour',
                              style: TextStyle(
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Color(0xFF6366F1),
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateTimeSelection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'When do you need the service?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),

            // Urgent toggle
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isUrgent ? Colors.red[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isUrgent ? Colors.red[300]! : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emergency,
                    color: _isUrgent ? Colors.red : Colors.grey[600],
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Urgent Service',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                                _isUrgent ? Colors.red[700] : Colors.grey[700],
                          ),
                        ),
                        Text(
                          'Need service within 2 hours',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                _isUrgent ? Colors.red[600] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isUrgent,
                    onChanged: (value) {
                      setState(() {
                        _isUrgent = value;
                        if (value) {
                          _selectedDate = DateTime.now();
                          _selectedTime = TimeOfDay.now();
                        }
                      });
                    },
                    activeColor: Colors.red,
                  ),
                ],
              ),
            ),

            if (!_isUrgent) ...[
              SizedBox(height: 24),

              // Date Selection
              Text(
                'Select Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 30)),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey[600]),
                      SizedBox(width: 12),
                      Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : 'Select date',
                        style: TextStyle(
                          color: _selectedDate != null
                              ? Colors.black
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Time Selection
              Text(
                'Select Time',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() {
                      _selectedTime = time;
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey[600]),
                      SizedBox(width: 12),
                      Text(
                        _selectedTime != null
                            ? _selectedTime!.format(context)
                            : 'Select time',
                        style: TextStyle(
                          color: _selectedTime != null
                              ? Colors.black
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDetails() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Describe your problem',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              maxLines: 6,
              decoration: InputDecoration(
                hintText:
                    'Please describe what needs to be fixed or the service you need...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.all(16),
              ),
              onChanged: (value) {
                setState(() {
                  _description = value;
                });
              },
            ),
            SizedBox(height: 24),
            Text(
              'Additional Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Tips for better service',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Be specific about the problem\n'
                    '• Mention any previous attempts to fix\n'
                    '• Include relevant details about equipment/location',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[600],
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

  Widget _buildReviewConfirm() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review Your Booking',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),

            // Service Summary
            _buildSummaryCard(
              'Service',
              widget.serviceName,
              Icons.build,
            ),

            // Provider Summary
            if (_selectedProvider != null)
              _buildSummaryCard(
                'Provider',
                _selectedProvider!.name,
                Icons.person,
                subtitle:
                    '⭐ ${_selectedProvider!.rating} • ${_selectedProvider!.distance?.toStringAsFixed(1)} km away',
              ),

            // Date & Time Summary
            if (_selectedDate != null || _isUrgent)
              _buildSummaryCard(
                'Date & Time',
                _isUrgent
                    ? 'Urgent - Within 2 hours'
                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} at ${_selectedTime?.format(context)}',
                Icons.schedule,
              ),

            // Description
            if (_description.isNotEmpty)
              _buildSummaryCard(
                'Description',
                _description,
                Icons.description,
              ),

            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your booking request will be sent to the provider for confirmation.',
                      style: TextStyle(color: Colors.green[700]),
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

  Widget _buildSummaryCard(String title, String content, IconData icon,
      {String? subtitle}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF6366F1)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingConfirmed() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 50,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Booking Confirmed!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Your booking request has been sent to ${_selectedProvider?.name}. You will receive a notification once confirmed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                if (!mounted) {
                  return; // Guard against using context after dispose
                }
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                  arguments: widget.user,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26), // Changed from withOpacity(0.1)
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Back'),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _canProceed() ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep == 3 ? 'Confirm Booking' : 'Next',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedProvider != null;
      case 1:
        return _isUrgent || (_selectedDate != null && _selectedTime != null);
      case 2:
        return _description.isNotEmpty;
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _nextStep() async {
    if (_currentStep == 3) {
      // Confirm booking
      await _confirmBooking();
    } else {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _confirmBooking() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await BookingService().createBooking({
        'serviceId': widget.serviceId,
        'providerId': _selectedProvider!.id,
        'clientId': widget.user.id,
        'scheduledDate': _isUrgent
            ? DateTime.now().toIso8601String()
            : _selectedDate!.toIso8601String(),
        'scheduledTime': _isUrgent
            ? TimeOfDay.now().format(context)
            : _selectedTime!.format(context),
        'description': _description,
        'isUrgent': _isUrgent,
        'location': {
          'type': 'Point',
          'coordinates': [
            _currentLocation?.longitude ?? 0.0,
            _currentLocation?.latitude ?? 0.0,
          ],
        },
      });

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating booking: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
