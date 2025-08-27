import 'package:flutter/material.dart';
import '../my_service_screen.dart';
import '../settings_screen.dart';
import '../contact_support_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// Add this import
// For Lottie animation
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../services/location_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../widgets/service_provider_widgets.dart';
import 'jobs_screen.dart';
import '../../widgets/activity_card.dart';
import '../../services/provider_location_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../screens/auth/login_screen.dart';
import '../../widgets/earnings_chart.dart';
import '../../models/user_model.dart' as poafix;
// Updated import path
import '../../services/provider_service.dart';
import '../../services/websocket_service.dart';
import '../../services/notification_service.dart';
import '../../services/booking_service.dart';
import '../../models/booking.dart';
import '../../widgets/booking_card.dart';
import '../finance/financial_management_screen.dart';
import '../../middleware/auth_middleware.dart';
import '../notification_screen.dart'; // Update import path
import '../../services/auth_service.dart'; // Add this import
import '../document_upload_screen.dart'; // Add this import
import '../../services/provider_document_service.dart'; // Add this import
// <-- Add this import for User model

final StreamController<Position> locationUpdateController =
    StreamController<Position>.broadcast();

class ServiceProviderScreen extends StatefulWidget {
  final String userName;
  final String userId;
  final String businessName;
  final String serviceType;

  const ServiceProviderScreen({
    super.key,
    required this.userName,
    required this.userId,
    required this.businessName,
    required this.serviceType,
  });

  @override
  _ServiceProviderScreenState createState() => _ServiceProviderScreenState();
}

class _ServiceProviderScreenState extends State<ServiceProviderScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  String? userName;
  String? userEmail;
  bool _isLoading = true;
  Position? _currentPosition;
  bool _locationEnabled = false;
  Timer? _locationTimer;
  final storage = FlutterSecureStorage();
  String? _serviceProviderId;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  bool _isOnline = false;
  final LocationService _locationService = LocationService();
  Timer? _locationUpdateTimer;
  bool _isUpdatingLocation = false;
  static const updateInterval = Duration(seconds: 30); // More frequent updates
  final ProviderLocationService _providerLocationService =
      ProviderLocationService();
  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription? _connectionStatusSubscription;
  final NotificationService _notificationService = NotificationService();
  final BookingService _bookingService = BookingService();
  List<Booking> _bookings = [];
  List<dynamic> _upcomingAppointments = [];
  List<dynamic> _recentActivities = [];
  bool _isAppointmentsLoading = false;
  bool _isActivitiesLoading = false;
  Future<void> _fetchUpcomingAppointments() async {
    setState(() => _isAppointmentsLoading = true);
    try {
      final providerId = _serviceProviderId ?? widget.userId;
      final response = await http.get(
        Uri.parse(
          'https://09ecb564d140.ngrok-free.app/api/providers/$providerId/upcoming-appointments',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _upcomingAppointments = data['appointments'] ?? [];
        });
      } else {
        print('Failed to fetch upcoming appointments: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching upcoming appointments: $e');
    } finally {
      setState(() => _isAppointmentsLoading = false);
    }
  }

  Future<void> _fetchRecentActivities() async {
    setState(() => _isActivitiesLoading = true);
    try {
      final providerId = _serviceProviderId ?? widget.userId;
      final response = await http.get(
        Uri.parse(
          'https://09ecb564d140.ngrok-free.app/api/providers/$providerId/recent-activities',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _recentActivities = data['activities'] ?? [];
        });
      } else {
        print('Failed to fetch recent activities: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching recent activities: $e');
    } finally {
      setState(() => _isActivitiesLoading = false);
    }
  }

  final _storage = FlutterSecureStorage();
  String _providerName = '';
  String _providerEmail = '';
  bool _hasDocumentsPending = false;

  Map<String, dynamic>? _dashboardStats;
  Future<void> _fetchDashboardStats() async {
    try {
      final providerId = _serviceProviderId ?? widget.userId;
      final response = await http.get(
        Uri.parse(
          'https://09ecb564d140.ngrok-free.app/api/providers/$providerId/dashboard',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _dashboardStats = json.decode(response.body);
        });
      } else {
        print('Failed to fetch dashboard stats: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching dashboard stats: $e');
    }
  }

  final PageController _pageController = PageController();
  late TabController _tabController;

  List<Widget> get _screens => [
    _buildDashboardContent(),
    JobsScreen(providerId: widget.userId),
    NotificationsScreen(), // Remove user parameter since it's optional now
    FinancialManagementScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkDocuments();
    print('Initializing ServiceProviderScreen with userId: ${widget.userId}');
    _checkAuthentication();
    _loadProviderData();
    _fetchDashboardStats();
    _fetchUpcomingAppointments();
    _fetchRecentActivities();
  }

  Future<void> _checkAuthentication() async {
    try {
      final storage = const FlutterSecureStorage();
      final isLoggedIn = await storage.read(key: 'isLoggedIn') ?? 'false';
      final userType = await storage.read(key: 'user_type');

      print('Auth Check - isLoggedIn: $isLoggedIn, userType: $userType');

      if (isLoggedIn != 'true' || userType != 'service-provider') {
        if (mounted) {
          print('Not authenticated, redirecting to login');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print('Error checking authentication: $e');
    }
  }

  Future<void> _checkProviderAccess() async {
    try {
      final isProvider = await _authService.isProvider();
      if (!isProvider) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        }
      }
    } catch (e) {
      print('Error checking provider access: $e');
    }
  }

  Future<void> _checkAuthAndInitialize() async {
    if (!mounted) return;

    final isAuthenticated = await AuthMiddleware.checkAuth(context);
    if (isAuthenticated) {
      await _initializeProvider();
      await _initializeServices();
      await _setupBookingListeners();
    }
  }

  Future<void> _initializeProvider() async {
    try {
      await _fetchUserData();
      final storedId = await storage.read(key: 'userId');
      setState(() {
        _serviceProviderId = storedId ?? widget.userId;
      });

      if (_serviceProviderId == null || _serviceProviderId!.isEmpty) {
        throw Exception('Provider ID not found');
      }

      print('Initialized provider with ID: $_serviceProviderId');

      await _checkLocationPermission();
      if (_locationEnabled) {
        final wasOnline = await _providerLocationService.checkProviderStatus(
          _serviceProviderId!,
        );
        if (wasOnline) {
          setState(() => _isOnline = true);
          _startLocationUpdates();
        }
      }
    } catch (e) {
      print('Error initializing provider: $e');
      _showErrorDialog('Failed to initialize: Please try logging in again');
    }
  }

  Future<void> _initializeServices() async {
    try {
      if (!_webSocketService.isConnected) {
        // Ensure userId is valid before connecting
        final parsedId = int.tryParse(widget.userId);
        if (parsedId != null) {
          await _webSocketService.connect(widget.userId);
        } else {
          throw Exception('Invalid user ID format');
        }
      }
      _startLocationUpdates();
    } catch (e) {
      print('Error initializing services: $e');
      // Handle error appropriately
    }
  }

  Future<void> _setupBookingListeners() async {
    try {
      // Listen for new booking notifications
      _notificationService.socketStream?.listen((message) {
        if (message is Map<String, dynamic> && message['type'] == 'booking') {
          _fetchBookings(); // Refresh bookings list
          _showBookingNotification(message);
        }
      });

      // Initial fetch
      await _fetchBookings();
    } catch (e) {
      print('Error setting up booking listeners: $e');
    }
  }

  Future<void> _fetchBookings() async {
    try {
      print('Starting to fetch bookings...');
      final List<dynamic> bookingsData = await _bookingService
          .getProviderBookings();

      if (mounted) {
        setState(() {
          _bookings = bookingsData
              .map((b) {
                try {
                  if (b is Map<String, dynamic>) {
                    return Booking.fromJson(b);
                  }
                  print('Invalid booking data format');
                  return null;
                } catch (e) {
                  print('Error parsing booking: $e');
                  return null;
                }
              })
              .where((b) => b != null)
              .cast<Booking>()
              .toList();
        });
      }
    } catch (e) {
      print('Error in _fetchBookings: $e');
      if (mounted) {
        setState(() => _bookings = []);
      }
    }
  }

  void _showBookingNotification(Map<String, dynamic> data) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New booking request received!'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _showBookingDetails(data['booking']),
        ),
      ),
    );
  }

  void _showBookingDetails(Map<String, dynamic> bookingData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Booking Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Client: ${bookingData['clientName'] ?? 'N/A'}'),
                SizedBox(height: 8),
                Text('Service: ${bookingData['serviceType'] ?? 'N/A'}'),
                SizedBox(height: 8),
                Text('Date: ${bookingData['date'] ?? 'N/A'}'),
                SizedBox(height: 8),
                Text('Time: ${bookingData['time'] ?? 'N/A'}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadServiceProviderId() async {
    try {
      _serviceProviderId = await storage.read(key: 'userId') ?? widget.userId;
      if (_serviceProviderId != null) {
        _setupLocationUpdates();
      }
    } catch (e) {
      print('Error loading service provider ID: $e');
    }
  }

  void _setupLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(Duration(minutes: 1), (timer) async {
      if (_isOnline) {
        await _updateLocation();
      }
    });
  }

  Future<void> _updateLocation() async {
    if (_isUpdatingLocation) return;
    _isUpdatingLocation = true;

    try {
      if (!_locationEnabled) {
        await _checkLocationPermission();
        if (!_locationEnabled) return;
      }

      final String providerId = _serviceProviderId ?? widget.userId;
      if (providerId.isEmpty) {
        throw Exception('Provider ID not found');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 10),
      );

      print('Position received: ${position.latitude}, ${position.longitude}');

      if (!mounted) return;

      await ProviderService.updateLocation(providerId, {
        'type': 'Point',
        'coordinates': [position.longitude, position.latitude],
      }, _isOnline);

      setState(() {
        _currentPosition = position;
        _locationEnabled = true;
      });
    } catch (e) {
      print('Error in _updateLocation: $e');
      if (mounted) {
        setState(() => _isOnline = false);
        _showErrorDialog('Location update failed: ${e.toString()}');
      }
    } finally {
      _isUpdatingLocation = false;
    }
  }

  Future<void> _updateProviderLocation(Map<String, dynamic> location) async {
    try {
      await ProviderService.updateLocation(
        widget.userId,
        location,
        true, // or your availability status
      );
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  _fetchUserData() async {
    String? fetchedUserName = await _secureStorage.read(key: 'userName');
    String? fetchedUserEmail = await _secureStorage.read(key: 'email');
    setState(() {
      userName = fetchedUserName ?? widget.userName;
      userEmail = fetchedUserEmail ?? 'No Email';
      _isLoading = false;
    });
  }

  Future<void> _checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationPermissionDialog(
          'Location services are disabled. Please enable location services to continue.',
          isService: true,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationPermissionDialog(
            'Location permissions are required to provide services. Please enable location permissions.',
            isPermission: true,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationPermissionDialog(
          'Location permissions are permanently denied. Please enable them in your device settings.',
          isPermission: true,
        );
        return;
      }

      setState(() {
        _locationEnabled = true;
      });
      _updateLocation();
    } catch (e) {
      _showErrorDialog('Error checking location permissions: ${e.toString()}');
    }
  }

  void _showLocationPermissionDialog(
    String message, {
    bool isService = false,
    bool isPermission = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              SizedBox(height: 16),
              Text(
                'You must enable location services to use this app as a service provider.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isOnline = false;
                  _locationEnabled = false;
                });
              },
            ),
            TextButton(
              child: Text('Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                if (isService) {
                  Geolocator.openLocationSettings();
                } else if (isPermission) {
                  Geolocator.openAppSettings();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveLocationToServer(Position position) async {
    try {
      final String? userId = await _secureStorage.read(key: 'userId');
      if (userId == null) return;

      await _providerLocationService.updateLocation(
        providerId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
        isAvailable: _isOnline, // Changed from isOnline to isAvailable
      );

      locationUpdateController.add(position);
    } catch (e) {
      print('Error saving location: $e');
    }
  }

  void _showLocationDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Services'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _isLoading
              ? UserAccountsDrawerHeader(
                  accountName: Text('Loading...'),
                  accountEmail: Text('Please wait'),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.blue),
                  ),
                )
              : UserAccountsDrawerHeader(
                  accountName: Text(
                    _providerName,
                    style: TextStyle(fontSize: 18.0),
                  ),
                  accountEmail: Text(
                    _providerEmail,
                    style: TextStyle(fontSize: 14.0),
                  ),
                  currentAccountPicture: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: CircleAvatar(
                      key: ValueKey<String>(_providerName),
                      backgroundColor: Colors.blue,
                      radius: 50,
                      child: Text(
                        _providerName.isNotEmpty
                            ? _providerName[0].toUpperCase()
                            : 'S',
                        style: TextStyle(color: Colors.white, fontSize: 40),
                      ),
                    ),
                  ),
                ),
          _drawerItem('My Services', Icons.work, () {
            _navigateToScreen(context, MyServiceScreen());
          }),
          _drawerItem('Document Verification', Icons.file_present, () {
            _navigateToScreen(context, DocumentUploadScreen());
          }, badge: _hasDocumentsPending), // This is the new item we added
          _drawerItem('Calendar', Icons.calendar_today, () {
            Navigator.pop(context);
            Navigator.pushNamed(
              context,
              '/calendar',
              arguments: poafix.User(
                id: widget.userId,
                name: userName ?? widget.userName,
                email: '',
                userType: 'provider',
                phone: '',
              ),
            );
          }),
          _drawerItem('Financial Management', Icons.monetization_on, () {
            _navigateToScreen(context, FinancialManagementScreen());
          }),
          _drawerItem('Settings', Icons.settings, () {
            _navigateToScreen(context, SettingsScreen());
          }),
          _drawerItem('Support/Help', Icons.help, () {
            _navigateToScreen(context, ContactSupportScreen());
          }),
          Divider(),
          ListTile(
            title: Text('Log Out'),
            leading: Icon(Icons.logout),
            onTap: _logOut,
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool badge = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: ListTile(
        title: Text(title),
        leading: Stack(
          children: [
            Icon(icon),
            if (badge)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: BoxConstraints(minWidth: 12, minHeight: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpinKitFadingCircle(color: Colors.white, size: 50.0),
              SizedBox(height: 16),
              Text(
                'Logging out...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logOut() async {
    _showLoadingDialog();

    try {
      // Cancel any active timers first
      _locationUpdateTimer?.cancel();
      _locationTimer?.cancel();

      // Only try to update location if we have valid coordinates
      if (_currentPosition != null) {
        try {
          await _providerLocationService.updateLocation(
            providerId: _serviceProviderId ?? widget.userId,
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            isAvailable: false,
          );
        } catch (e) {
          print('Failed to update location status during logout: $e');
          // Continue with logout even if location update fails
        }
      }

      final storage = const FlutterSecureStorage();

      // Clear all stored data
      await Future.wait([
        storage.delete(key: 'userName'),
        storage.delete(key: 'email'),
        storage.delete(key: 'auth_token'),
        storage.delete(key: 'userId'),
        storage.delete(key: 'userType'),
        storage.delete(key: 'isLoggedIn'),
        storage.delete(key: 'user_type'),
      ]);

      // Add a small delay for visual effect
      await Future.delayed(Duration(milliseconds: 800));

      // Check if the context is still valid
      if (!mounted) return;

      // Navigate to login screen and clear navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print('Error during logout: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Remove loading dialog
        _showErrorDialog('Failed to logout. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: _buildGradientAppBar(),
        drawer: _buildDrawer(),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildDashboardContent(),
            JobsScreen(providerId: widget.userId),
            NotificationsScreen(),
            FinancialManagementScreen(),
          ],
        ),
        bottomNavigationBar: _buildGlassBottomNavigation(),
        floatingActionButton: _buildOnlineToggleButton(),
      ),
    );
  }

  Widget _buildGlassBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white.withOpacity(0.85),
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Notifications',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.monetization_on),
          label: 'Finance',
        ),
      ],
    );
  }

  Widget _buildProfileScreen() {
    return Center(child: Text('Profile Screen - Coming Soon'));
  }

  PreferredSizeWidget _buildGradientAppBar() {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
          ),
        ),
      ),
      title: Text(
        _getScreenTitle(),
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications),
          onPressed: () => _onItemTapped(2), // Switch to notifications tab
        ),
      ],
    );
  }

  String _getScreenTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Jobs';
      case 2:
        return 'Notifications';
      case 3:
        return 'Financial Management';
      default:
        return 'Service Dashboard';
    }
  }

  Widget _buildOnlineStatusSwitch() {
    return Switch(value: _isOnline, onChanged: _toggleOnlineStatus);
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchUserData();
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: AnimationLimiter(
          child: Column(
            children: AnimationConfiguration.toStaggeredList(
              duration: Duration(milliseconds: 375),
              childAnimationBuilder: (widget) => SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                _buildWelcomeHeader(),
                _buildStatusCards(),
                _buildRecentActivities(),
                _buildUpcomingAppointments(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black12, offset: Offset(0, 4), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                child: Text(
                  userName?.isNotEmpty == true
                      ? userName![0].toUpperCase()
                      : 'S',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    Text(
                      userName ?? widget.userName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Here\'s a quick overview of your activities and earnings.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCards() {
    final stats = [
      {
        'icon': Icons.work,
        'value': (_dashboardStats?['jobsDone']?.toString() ?? '0'),
        'label': 'Jobs',
      },
      {
        'icon': Icons.star,
        'value':
            (_dashboardStats?['ratings'] != null &&
                _dashboardStats!['ratings'] > 0)
            ? _dashboardStats!['ratings'].toStringAsFixed(2)
            : 'No ratings',
        'label': 'Rating',
      },
      {
        'icon': Icons.people,
        'value': (_dashboardStats?['clients']?.toString() ?? '0'),
        'label': 'Clients',
      },
      {
        'icon': Icons.timer,
        'value': (_dashboardStats?['hours']?.toString() ?? '0'),
        'label': 'Hours',
      },
    ];
    return Padding(
      padding: EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) => StatCard(
          icon: stats[index]['icon'] as IconData,
          value: stats[index]['value'] as String,
          label: stats[index]['label'] as String,
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Recent Activities',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _isActivitiesLoading
            ? Center(child: CircularProgressIndicator())
            : _recentActivities.isEmpty
            ? Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey[400]),
                    SizedBox(height: 8),
                    Text(
                      'No recent activities found.',
                      style: GoogleFonts.poppins(),
                    ),
                  ],
                ),
              )
            : AnimationLimiter(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _recentActivities.length,
                  itemBuilder: (context, index) {
                    final activity = _recentActivities[index];
                    final statusColor = activity['status'] == 'completed'
                        ? Colors.green
                        : activity['status'] == 'cancelled'
                        ? Colors.red
                        : Colors.orange;
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 400),
                      child: SlideAnimation(
                        verticalOffset: 30.0,
                        child: FadeInAnimation(
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 6,
                            margin: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                // Optionally show details
                              },
                              child: Padding(
                                padding: EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.work,
                                          color: statusColor,
                                          size: 28,
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            activity['serviceType'] ??
                                                'Service',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(
                                              0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            activity['status']?.toUpperCase() ??
                                                '',
                                            style: GoogleFonts.poppins(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 20,
                                          color: Colors.blueGrey,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          activity['client']?['name'] ??
                                              'Client',
                                          style: GoogleFonts.poppins(),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 18,
                                          color: Colors.blueGrey,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          activity['schedule'] != null
                                              ? activity['schedule']
                                                    .toString()
                                                    .substring(0, 10)
                                              : '',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        SizedBox(width: 12),
                                        Icon(
                                          Icons.access_time,
                                          size: 18,
                                          color: Colors.blueGrey,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          activity['schedule'] != null
                                              ? activity['schedule']
                                                    .toString()
                                                    .substring(11, 16)
                                              : '',
                                          style: GoogleFonts.poppins(),
                                        ),
                                      ],
                                    ),
                                    if (activity['address'] != null &&
                                        activity['address']
                                            .toString()
                                            .isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(top: 8),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 18,
                                              color: Colors.blueGrey,
                                            ),
                                            SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                activity['address'],
                                                style: GoogleFonts.poppins(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
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

  Widget _buildEarningsOverview() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Earnings Overview',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildEarningTile(
                    icon: Icons.account_balance_wallet,
                    amount: 'KES ${_dashboardStats?['monthlyEarnings'] ?? 0}',
                    label: 'This Month',
                    color: Colors.white,
                  ),
                  _buildEarningTile(
                    icon: Icons.pending,
                    amount: 'KES ${_dashboardStats?['pendingEarnings'] ?? 0}',
                    label: 'Pending',
                    color: Colors.white70,
                  ),
                ],
              ),
              SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value:
                      (_dashboardStats?['monthlyEarnings'] ?? 0) /
                      (_dashboardStats?['monthlyTarget'] ?? 1),
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '${(((_dashboardStats?['monthlyEarnings'] ?? 0) / (_dashboardStats?['monthlyTarget'] ?? 1)) * 100).toStringAsFixed(0)}% of monthly target',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 16),
              EarningsChart(data: _dashboardStats?['earningsData'] ?? []),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEarningTile({
    required IconData icon,
    required String amount,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        SizedBox(height: 8),
        Text(
          amount,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: GoogleFonts.poppins(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildUpcomingAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Upcoming Appointments',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _isAppointmentsLoading
            ? Center(child: CircularProgressIndicator())
            : _upcomingAppointments.isEmpty
            ? Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                    SizedBox(height: 8),
                    Text(
                      'No upcoming appointments found.',
                      style: GoogleFonts.poppins(),
                    ),
                  ],
                ),
              )
            : AnimationLimiter(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _upcomingAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = _upcomingAppointments[index];
                    final statusColor = appointment['status'] == 'confirmed'
                        ? Colors.green
                        : appointment['status'] == 'pending'
                        ? Colors.orange
                        : Colors.blue;
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 400),
                      child: SlideAnimation(
                        verticalOffset: 30.0,
                        child: FadeInAnimation(
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 6,
                            margin: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                // Optionally show details
                              },
                              child: Padding(
                                padding: EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.event,
                                          color: statusColor,
                                          size: 28,
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            appointment['serviceType'] ??
                                                'Service',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(
                                              0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            appointment['status']
                                                    ?.toUpperCase() ??
                                                '',
                                            style: GoogleFonts.poppins(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 20,
                                          color: Colors.blueGrey,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          appointment['client']?['name'] ??
                                              'Client',
                                          style: GoogleFonts.poppins(),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 18,
                                          color: Colors.blueGrey,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          appointment['schedule'] != null
                                              ? appointment['schedule']
                                                    .toString()
                                                    .substring(0, 10)
                                              : '',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        SizedBox(width: 12),
                                        Icon(
                                          Icons.access_time,
                                          size: 18,
                                          color: Colors.blueGrey,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          appointment['schedule'] != null
                                              ? appointment['schedule']
                                                    .toString()
                                                    .substring(11, 16)
                                              : '',
                                          style: GoogleFonts.poppins(),
                                        ),
                                      ],
                                    ),
                                    if (appointment['address'] != null &&
                                        appointment['address']
                                            .toString()
                                            .isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(top: 8),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 18,
                                              color: Colors.blueGrey,
                                            ),
                                            SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                appointment['address'],
                                                style: GoogleFonts.poppins(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
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

  Widget _buildOnlineToggleButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        final newStatus = !_isOnline;
        setState(() {
          _isOnline = newStatus;
        });
        if (newStatus) {
          _startLocationUpdates();
        } else {
          _locationUpdateTimer?.cancel();
        }
      },
      backgroundColor: _isOnline ? Colors.green : Colors.grey,
      icon: Icon(_isOnline ? Icons.wifi : Icons.wifi_off),
      label: Text(_isOnline ? 'Online' : 'Offline'),
    );
  }

  Future<void> _updateProviderStatus(bool available) async {
    try {
      final response = await http.post(
        Uri.parse('http://your-api-url/api/provider/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'providerId': widget.userId,
          'available': available,
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to update status: ${response.body}');
      }
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  Future<void> _startLocationUpdates() async {
    _locationUpdateTimer?.cancel();

    // Initial update
    await _updateLocation();

    // Set up periodic updates
    _locationUpdateTimer = Timer.periodic(updateInterval, (_) async {
      if (_isOnline && !_isUpdatingLocation && mounted) {
        await _updateLocation();
      }
    });
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    _locationUpdateTimer?.cancel();
    _locationTimer?.cancel();
    locationUpdateController.close();
    _connectionStatusSubscription?.cancel();
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _toggleOnlineStatus(bool value) async {
    if (_serviceProviderId == null || _serviceProviderId!.isEmpty) {
      _showErrorDialog('Provider ID not found. Please log in again.');
      return;
    }

    try {
      if (value && !_locationEnabled) {
        await _checkLocationPermission();
        if (!_locationEnabled) return;
      }

      // Get current position with increased timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 10),
      );

      final String providerId = _serviceProviderId ?? widget.userId;
      if (providerId.isEmpty) {
        throw Exception('Invalid provider ID');
      }

      await ProviderService.updateLocation(providerId, {
        'coordinates': [position.longitude, position.latitude],
      }, value);

      setState(() {
        _isOnline = value;
        _currentPosition = position;
      });

      if (value) {
        _startLocationUpdates();
      } else {
        _locationUpdateTimer?.cancel();
      }
    } catch (e) {
      print('Error in _toggleOnlineStatus: $e');
      _showErrorDialog('Failed to update status: ${e.toString()}');
      setState(() => _isOnline = !value);
    }
  }

  Widget _buildBookingsList() {
    return ListView.builder(
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        return BookingCard(
          booking: booking,
          isProviderView: true, // Add this
          onAccept: () => _handleBookingAction(booking, 'accept'),
          onReject: () => _handleBookingAction(booking, 'reject'),
        );
      },
    );
  }

  Future<void> _handleBookingAction(Booking booking, String action) async {
    try {
      final bookingService = BookingService();
      if (action == 'accept') {
        await bookingService.acceptBooking(booking.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking accepted successfully')),
        );
      } else if (action == 'reject') {
        await bookingService.rejectBooking(booking.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Booking rejected')));
      }
      await _fetchBookings(); // Refresh the bookings list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to $action booking: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadProviderData() async {
    try {
      final name =
          await _storage.read(key: 'provider_name') ??
          await _storage.read(key: 'businessName') ??
          'Service Provider';
      final email =
          await _storage.read(key: 'provider_email') ??
          await _storage.read(key: 'email') ??
          'No email';

      if (mounted) {
        setState(() {
          _providerName = name;
          _providerEmail = email;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading provider data: $e');
    }
  }

  Future<void> _checkDocuments() async {
    final needsVerification = await ProviderDocumentService()
        .needsVerification();
    setState(() => _hasDocumentsPending = needsVerification);
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
  }
}

class HomeScreen extends StatelessWidget {
  final String? userName;

  const HomeScreen({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    // Open profile settings or detailed profile
                    print("Profile tapped");
                  },
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: CircleAvatar(
                      key: ValueKey<String>(userName ?? "J"),
                      radius: 60,
                      backgroundColor: Colors.blue,
                      child: Text(
                        userName != null && userName!.isNotEmpty
                            ? userName![0].toUpperCase()
                            : 'J',
                        style: TextStyle(color: Colors.white, fontSize: 40),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    // Open profile settings or detailed profile
                    print("Name tapped");
                  },
                  child: Text(
                    userName ?? 'Service Provider',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Service Description: Expert in home repairs and maintenance.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    Text('4.8 (25 reviews)', style: TextStyle(fontSize: 16)),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Contact: johndoe@example.com',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Availability: Available Monday to Friday, 9 AM - 6 PM',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text('Plumbing')),
                    Chip(label: Text('Electrical')),
                    Chip(label: Text('Handyman')),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upcoming Tasks',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: Text('Task 1: Kitchen Repair'),
                    subtitle: Text('Date: 02/15/2025'),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () {
                      // Navigate to task details
                    },
                  ),
                ),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: Text('Task 2: Plumbing Service'),
                    subtitle: Text('Date: 02/17/2025'),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () {
                      // Navigate to task details
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Earnings Overview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: Text('Total Earnings: \$1200'),
                    subtitle: Text('This month'),
                  ),
                ),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: Text('Pending Payment: \$500'),
                    subtitle: Text('Due in 7 days'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Client Ratings & Reviews',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    Text('4.8 (25 reviews)', style: TextStyle(fontSize: 16)),
                  ],
                ),
                SizedBox(height: 8),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: Text('Great service!'),
                    subtitle: Text('John Doe - 5 stars'),
                  ),
                ),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: Text('Highly recommend!'),
                    subtitle: Text('Jane Smith - 5 stars'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
