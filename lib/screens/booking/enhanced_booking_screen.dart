import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/user_model.dart';
import '../../models/service_category_model.dart';
import '../../models/provider_model.dart';
import '../../services/enhanced_proximity_service.dart';
import '../../services/booking_service.dart';

class EnhancedBookingScreen extends StatefulWidget {
  final User user;
  final ServiceCategoryModel selectedService;
  final Position? userLocation;

  const EnhancedBookingScreen({
    Key? key,
    required this.user,
    required this.selectedService,
    this.userLocation,
  }) : super(key: key);

  @override
  _EnhancedBookingScreenState createState() => _EnhancedBookingScreenState();
}

class _EnhancedBookingScreenState extends State<EnhancedBookingScreen> {
  final PageController _pageController = PageController();
  final ProximityService _proximityService = ProximityService();
  final BookingService _bookingService = BookingService();
  
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Booking data
  String? _selectedSubService;
  ProviderModel? _selectedProvider;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _location = '';
  String _notes = '';
  double _estimatedPrice = 0;
  bool _isUrgent = false;
  List<ProviderModel> _nearbyProviders = [];

  final List<String> _stepTitles = [
    'Service Details',
    'Choose Provider',
    'Schedule',
    'Location & Details',
    'Confirmation',
  ];

  @override
  void initState() {
    super.initState();
    _estimatedPrice = widget.selectedService.basePrice;
    _loadNearbyProviders();
  }

  Future<void> _loadNearbyProviders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final providers = await _proximityService.getNearbyProviders(
        serviceType: widget.selectedService.id,
        latitude: widget.userLocation?.latitude,
        longitude: widget.userLocation?.longitude,
      );

      setState(() {
        _nearbyProviders = providers;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading providers: $e');
      setState(() {
        _isLoading = false;
      });
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.selectedService.color, widget.selectedService.color.withOpacity(0.8)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(_stepTitles.length, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: index <= _currentStep 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_stepTitles.length, (index) {
              return Expanded(
                child: Text(
                  _stepTitles[index],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: index == _currentStep 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetailsStep() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Overview Card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.selectedService.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.selectedService.color.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.selectedService.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.selectedService.icon, 
                    color: widget.selectedService.color,
                    size: 30,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.selectedService.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        widget.selectedService.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: widget.selectedService.color),
                          SizedBox(width: 4),
                          Text(
                            '${widget.selectedService.nearbyProviders} providers nearby',
                            style: TextStyle(
                              color: widget.selectedService.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          Text(
            'Select specific service type:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          SizedBox(height: 16),
          
          Expanded(
            child: ListView.builder(
              itemCount: widget.selectedService.subServices.length,
              itemBuilder: (context, index) {
                final service = widget.selectedService.subServices[index];
                final isSelected = _selectedSubService == service;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _selectedSubService = service),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? widget.selectedService.color.withOpacity(0.1)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected 
                                ? widget.selectedService.color
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: widget.selectedService.color.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ] : [],
                        ),
                        child: Row(
                          children: [
                            Radio<String>(
                              value: service,
                              groupValue: _selectedSubService,
                              onChanged: (value) => setState(() => _selectedSubService = value),
                              activeColor: widget.selectedService.color,
                            ),
                            Expanded(
                              child: Text(
                                service,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                  color: isSelected 
                                      ? widget.selectedService.color
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: widget.selectedService.color,
                                size: 20,
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
      ),
    );
  }

  Widget _buildProviderSelectionStep() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: widget.selectedService.color),
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
            Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No providers found nearby',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'We\'ll search for providers in a wider area',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNearbyProviders,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.selectedService.color,
              ),
              child: Text('Search Again'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Choose your provider',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_nearbyProviders.length} available',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          Expanded(
            child: ListView.builder(
              itemCount: _nearbyProviders.length,
              itemBuilder: (context, index) {
                final provider = _nearbyProviders[index];
                final isSelected = _selectedProvider?.id == provider.id;
                final distance = provider.metadata['distance'] ?? 'N/A';
                
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => _selectedProvider = provider),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? widget.selectedService.color.withOpacity(0.1)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? widget.selectedService.color
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Provider Avatar
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: widget.selectedService.color,
                              backgroundImage: provider.profileImage != null && provider.profileImage!.isNotEmpty
                                  ? NetworkImage(provider.profileImage!)
                                  : null,
                              child: provider.profileImage == null || provider.profileImage!.isEmpty
                                  ? Text(
                                      provider.name[0].toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    )
                                  : null,
                            ),
                            
                            SizedBox(width: 16),
                            
                            // Provider Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          provider.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ),
                                      if (provider.isVerified)
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.verified, size: 12, color: Colors.blue[700]),
                                              SizedBox(width: 2),
                                              Text(
                                                'Verified',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.blue[700],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 4),
                                  
                                  // Rating and Distance
                                  Row(
                                    children: [
                                      Icon(Icons.star, color: Colors.orange, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        '${provider.rating} (${provider.totalRatings} reviews)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        '${distance} km away',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 4),
                                  
                                  // Experience and Rate
                                  Row(
                                    children: [
                                      Text(
                                        '${provider.completedJobs} jobs completed',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Spacer(),
                                      Text(
                                        'KES ${provider.hourlyRate}/hr',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: widget.selectedService.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Selection Indicator
                            Radio<String>(
                              value: provider.id,
                              groupValue: _selectedProvider?.id,
                              onChanged: (value) => setState(() => _selectedProvider = provider),
                              activeColor: widget.selectedService.color,
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
            'When do you need the service?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Urgent Service Toggle
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
                  color: _isUrgent ? Colors.red[600] : Colors.grey[600],
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Urgent Service',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isUrgent ? Colors.red[700] : Colors.grey[700],
                        ),
                      ),
                      Text(
                        'Need service within 2 hours (+20% fee)',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isUrgent ? Colors.red[600] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isUrgent,
                  onChanged: (value) => setState(() => _isUrgent = value),
                  activeColor: Colors.red[600],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          if (!_isUrgent) ...[
            // Date Selection
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.selectedService.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_today, color: widget.selectedService.color),
                ),
                title: Text('Select Date'),
                subtitle: Text(_selectedDate != null 
                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                    : 'Choose a date'),
                onTap: _selectDate,
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Time Selection
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.selectedService.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.access_time, color: widget.selectedService.color),
                ),
                title: Text('Select Time'),
                subtitle: Text(_selectedTime != null 
                    ? '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                    : 'Choose a time'),
                onTap: _selectTime,
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),
          ] else ...[
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.flash_on, color: Colors.orange[600], size: 40),
                  SizedBox(height: 12),
                  Text(
                    'Emergency Service',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'A provider will be assigned and contacted immediately. Service will begin within 2 hours.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange[600]),
                  ),
                ],
              ),
            ),
          ],
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
            'Service location & details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Location Input
          TextField(
            decoration: InputDecoration(
              labelText: 'Service Address',
              hintText: 'Enter your address or location',
              prefixIcon: Icon(Icons.location_on, color: widget.selectedService.color),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.selectedService.color, width: 2),
              ),
            ),
            onChanged: (value) => setState(() => _location = value),
            maxLines: 2,
          ),
          
          SizedBox(height: 20),
          
          // Additional Notes
          TextField(
            decoration: InputDecoration(
              labelText: 'Additional Notes (Optional)',
              hintText: 'Any specific requirements, instructions, or details...',
              prefixIcon: Icon(Icons.note, color: widget.selectedService.color),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.selectedService.color, width: 2),
              ),
            ),
            onChanged: (value) => setState(() => _notes = value),
            maxLines: 4,
          ),
          
          SizedBox(height: 24),
          
          // Price Estimation
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.selectedService.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.selectedService.color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Cost',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Base Price:'),
                    Text('KES ${widget.selectedService.basePrice.toInt()}'),
                  ],
                ),
                if (_isUrgent) ...[
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Urgent Fee (20%):'),
                      Text(
                        '+KES ${(widget.selectedService.basePrice * 0.2).toInt()}',
                        style: TextStyle(color: Colors.red[600]),
                      ),
                    ],
                  ),
                ],
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'KES ${(_isUrgent ? widget.selectedService.basePrice * 1.2 : widget.selectedService.basePrice).toInt()}',
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          SizedBox(height: 20),
          
          Expanded(
            child: SingleChildScrollView(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Details
                      _buildConfirmationSection(
                        'Service',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.selectedService.name,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (_selectedSubService != null)
                              Text(
                                _selectedSubService!,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                          ],
                        ),
                      ),
                      
                      // Provider Details
                      if (_selectedProvider != null)
                        _buildConfirmationSection(
                          'Provider',
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: widget.selectedService.color,
                                child: Text(
                                  _selectedProvider!.name[0],
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedProvider!.name,
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.star, size: 14, color: Colors.orange),
                                        Text(
                                          ' ${_selectedProvider!.rating}',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        if (_selectedProvider!.isVerified) ...[
                                          SizedBox(width: 8),
                                          Icon(Icons.verified, size: 14, color: Colors.blue),
                                          Text(
                                            ' Verified',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Schedule
                      _buildConfirmationSection(
                        'Schedule',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isUrgent) ...[
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.emergency, size: 16, color: Colors.red[700]),
                                    SizedBox(width: 4),
                                    Text(
                                      'URGENT - Within 2 hours',
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              if (_selectedDate != null)
                                Text(
                                  '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              if (_selectedTime != null)
                                Text(
                                  'at ${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Location
                      if (_location.isNotEmpty)
                        _buildConfirmationSection(
                          'Location',
                          Text(_location),
                        ),
                      
                      // Notes
                      if (_notes.isNotEmpty)
                        _buildConfirmationSection(
                          'Notes',
                          Text(_notes),
                        ),
                      
                      Divider(),
                      
                      // Total Cost
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Cost:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'KES ${(_isUrgent ? widget.selectedService.basePrice * 1.2 : widget.selectedService.basePrice).toInt()}',
                            style: TextStyle(
                              fontSize: 20,
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
            ),
          ),
          
          SizedBox(height: 20),
          
          // Confirm Button
          Container(
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
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Confirm Booking',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationSection(String title, Widget content) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: widget.selectedService.color,
            ),
          ),
          SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
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
                  side: BorderSide(color: widget.selectedService.color),
                ),
                child: Text(
                  'Previous',
                  style: TextStyle(color: widget.selectedService.color),
                ),
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
                elevation: 0,
              ),
              child: Text(
                _currentStep == _stepTitles.length - 1 ? 'Confirm Booking' : 'Next',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
        return _isUrgent || (_selectedDate != null && _selectedTime != null);
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.selectedService.color,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.selectedService.color,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _confirmBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create booking data
      final bookingData = {
        'serviceType': widget.selectedService.id,
        'subService': _selectedSubService,
        'providerId': _selectedProvider?.id,
        'scheduledDate': _isUrgent ? null : _selectedDate?.toIso8601String(),
        'scheduledTime': _isUrgent ? null : _selectedTime?.format(context),
        'location': _location,
        'notes': _notes,
        'isUrgent': _isUrgent,
        'estimatedPrice': _isUrgent ? widget.selectedService.basePrice * 1.2 : widget.selectedService.basePrice,
        'status': 'pending',
      };

      // Create booking via API
      final booking = await _bookingService.createBooking(bookingData);

      setState(() {
        _isLoading = false;
      });

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 48,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Booking Confirmed! 🎉',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                _isUrgent 
                    ? 'Your urgent booking has been submitted. A provider will contact you within 30 minutes.'
                    : 'Your booking has been confirmed. The provider will contact you shortly to confirm the schedule.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/bookings', arguments: widget.user);
              },
              style: TextButton.styleFrom(
                backgroundColor: widget.selectedService.color,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('View My Bookings'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Booking Error'),
          content: Text('Failed to create booking. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
