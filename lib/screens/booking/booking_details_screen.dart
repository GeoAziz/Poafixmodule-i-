import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/models/user_model.dart' show UserModel;
import '../../models/user_model.dart' show User;
import '../../models/user.dart' as user_model;
import '../../models/service_category.dart';
import '../../services/proximity_service.dart';
import '../../widgets/provider_map_widget.dart';

class BookingDetailsScreen extends StatefulWidget {
  final UserModel user;
  final ServiceCategory selectedService;

  const BookingDetailsScreen({
    super.key,
    required this.user,
    required this.selectedService,
  });

  @override
  _BookingDetailsScreenState createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Booking data
  String? _selectedSubService;
  Map<String, dynamic>? _selectedProvider;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _location = '';
  String _notes = '';
  double _estimatedPrice = 0;
  List<Map<String, dynamic>> _nearbyProviders = [];
  bool _isLoadingProviders = false;
  double? _userLat;
  double? _userLng;

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  final List<String> _stepTitles = [
    'Service Details',
    'Choose Provider',
    'Schedule',
    'Location',
    'Confirmation',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _estimatedPrice = widget.selectedService.basePrice;
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadNearbyProviders() async {
    if (_isLoadingProviders) return;

    setState(() => _isLoadingProviders = true);

    try {
      // Get current location
      Position? position = await _getCurrentLocation();

      if (position != null) {
        _userLat = position.latitude;
        _userLng = position.longitude;
        final providersData = await ProximityService.getNearbyProviders(
          serviceType: widget.selectedService.id,
          latitude: _userLat,
          longitude: _userLng,
          radiusKm: 10.0,
        );
        if (providersData.isNotEmpty && providersData.first is Map) {
          setState(() {
            _nearbyProviders = List<Map<String, dynamic>>.from(providersData);
          });
        } else if (providersData.isNotEmpty &&
            providersData.first.runtimeType.toString().contains(
              'ProviderModel',
            )) {
          setState(() {
            _nearbyProviders = providersData
                .map((p) => (p as dynamic).toJson() as Map<String, dynamic>)
                .toList();
          });
        } else {
          setState(() {
            _nearbyProviders = [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading providers: $e');
      // Use mock data if API fails
      _loadMockProviders();
    } finally {
      setState(() => _isLoadingProviders = false);
    }
  }

  void _loadMockProviders() {
    setState(() {
      _nearbyProviders = [
        {
          'businessName':
              'David\'s Professional ${widget.selectedService.name}',
          'firstName': 'David',
          'lastName': 'Johnson',
          'rating': 4.8,
          'reviewCount': 127,
          'hourlyRate': widget.selectedService.basePrice,
          'distance': 1.2,
          'experience': 8,
          'isAvailable24x7': widget.selectedService.isAvailable24x7,
          'averageResponseTime': 15,
          'completedJobs': 245,
          'profileImage': null,
          'services': widget.selectedService.services,
          'certifications': ['Licensed Professional', 'Certified Expert'],
        },
        {
          'businessName': 'Expert ${widget.selectedService.name} Solutions',
          'firstName': 'Sarah',
          'lastName': 'Wilson',
          'rating': 4.9,
          'reviewCount': 89,
          'hourlyRate': widget.selectedService.basePrice + 200,
          'distance': 2.1,
          'experience': 12,
          'isAvailable24x7': false,
          'averageResponseTime': 25,
          'completedJobs': 312,
          'profileImage': null,
          'services': widget.selectedService.services,
          'certifications': ['Master Technician', 'Quality Assured'],
        },
        {
          'businessName': 'Quick ${widget.selectedService.name} Service',
          'firstName': 'Michael',
          'lastName': 'Brown',
          'rating': 4.6,
          'reviewCount': 156,
          'hourlyRate': widget.selectedService.basePrice - 100,
          'distance': 3.5,
          'experience': 5,
          'isAvailable24x7': true,
          'averageResponseTime': 20,
          'completedJobs': 178,
          'profileImage': null,
          'services': widget.selectedService.services,
          'certifications': ['Licensed', 'Insured'],
        },
      ];
    });
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book ${widget.selectedService.name}'),
        backgroundColor: widget.selectedService.color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(),

          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildServiceDetailsStep(),
                _buildProviderSelectionStep(),
                _buildScheduleStep(),
                _buildLocationStep(),
                _buildConfirmationStep(),
              ],
            ),
          ),

          // Bottom Navigation
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(20),
      color: widget.selectedService.color,
      child: Row(
        children: List.generate(_stepTitles.length, (index) {
          return Expanded(
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _stepTitles[index],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: index == _currentStep
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildServiceDetailsStep() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What type of ${widget.selectedService.name.toLowerCase()} service do you need?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          ...widget.selectedService.services.map((service) {
            return GestureDetector(
              onTap: () => setState(() => _selectedSubService = service),
              child: Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedSubService == service
                      ? widget.selectedService.color.withOpacity(0.1)
                      : Colors.white,
                  border: Border.all(
                    color: _selectedSubService == service
                        ? widget.selectedService.color
                        : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Radio<String>(
                      value: service,
                      groupValue: _selectedSubService,
                      onChanged: (value) =>
                          setState(() => _selectedSubService = value),
                      activeColor: widget.selectedService.color,
                    ),
                    Expanded(
                      child: Text(
                        service,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _selectedSubService == service
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProviderSelectionStep() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your preferred provider',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          // Map widget at the top
          if (!_isLoadingProviders && _nearbyProviders.isNotEmpty)
            ProviderMapWidget(
              providers: _nearbyProviders,
              initialLat: _userLat ?? -1.2921,
              initialLng: _userLng ?? 36.8219,
              onMarkerTap: (index) {
                // Optionally scroll to card or highlight
              },
            ),
          SizedBox(height: 16),
          _isLoadingProviders
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Finding nearby providers...'),
                    ],
                  ),
                )
              : _nearbyProviders.isEmpty
              ? Center(
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
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: _nearbyProviders.length,
                    itemBuilder: (context, index) {
                      final provider = _nearbyProviders[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: provider['profileImage'] != null
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    provider['profileImage'],
                                  ),
                                )
                              : CircleAvatar(child: Icon(Icons.person)),
                          title: Text(
                            provider['businessName'] ??
                                provider['firstName'] ??
                                'Provider',
                          ),
                          subtitle: Text(
                            'Rating: ${provider['rating'] ?? '-'} | Jobs: ${provider['completedJobs'] ?? '-'}',
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedProvider = provider;
                              });
                            },
                            child: Text(
                              _selectedProvider == provider
                                  ? 'Selected'
                                  : 'Select',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildScheduleStep() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When would you like the service?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),

          // Date Selection
          Card(
            child: ListTile(
              leading: Icon(
                Icons.calendar_today,
                color: widget.selectedService.color,
              ),
              title: Text('Select Date'),
              subtitle: Text(
                _selectedDate != null
                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                    : 'Choose a date',
              ),
              onTap: _selectDate,
              trailing: Icon(Icons.arrow_forward_ios),
            ),
          ),

          SizedBox(height: 16),

          // Time Selection
          Card(
            child: ListTile(
              leading: Icon(
                Icons.access_time,
                color: widget.selectedService.color,
              ),
              title: Text('Select Time'),
              subtitle: Text(
                _selectedTime != null
                    ? '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                    : 'Choose a time',
              ),
              onTap: _selectTime,
              trailing: Icon(Icons.arrow_forward_ios),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where do you need the service?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              labelText: 'Service Location',
              hintText: 'Enter your address',
              prefixIcon: Icon(
                Icons.location_on,
                color: widget.selectedService.color,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.selectedService.color),
              ),
            ),
            onChanged: (value) => setState(() => _location = value),
          ),
          SizedBox(height: 20),
          TextField(
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Additional Notes (Optional)',
              hintText: 'Any specific requirements or instructions...',
              prefixIcon: Icon(Icons.note, color: widget.selectedService.color),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.selectedService.color),
              ),
            ),
            onChanged: (value) => setState(() => _notes = value),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm Your Booking',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConfirmationItem('Service', _selectedSubService ?? ''),
                  _buildConfirmationItem(
                    'Provider',
                    _selectedProvider != null
                        ? (_selectedProvider!['name'] as String)
                        : '',
                  ),
                  _buildConfirmationItem(
                    'Date',
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : '',
                  ),
                  _buildConfirmationItem(
                    'Time',
                    _selectedTime != null
                        ? '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                        : '',
                  ),
                  _buildConfirmationItem('Location', _location),
                  if (_notes.isNotEmpty)
                    _buildConfirmationItem('Notes', _notes),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estimated Cost:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'KES ${widget.selectedService.basePrice}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.selectedService.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.selectedService.color,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Confirm Booking',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(child: Text(value, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Previous'),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceed() ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.selectedService.color,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep == _stepTitles.length - 1 ? 'Confirm' : 'Next',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        return _selectedSubService != null;
      case 1:
        return _selectedProvider != null;
      case 2:
        return _selectedDate != null && _selectedTime != null;
      case 3:
        return _location.isNotEmpty;
      case 4:
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep < _stepTitles.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _confirmBooking();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _confirmBooking() {
    // TODO: Implement booking API call
    // Convert UserModel to User before navigation
    final user = user_model.User.fromUserModel(widget.user);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Booking Confirmed! 🎉'),
        content: Text(
          'Your booking has been successfully created. The provider will contact you shortly.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(
                context,
                '/bookings',
                arguments: user,
              );
            },
            child: Text('View My Bookings'),
          ),
        ],
      ),
    );
  }
}
