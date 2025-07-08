import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../services/auth_storage.dart';
import '../../services/websocket_service.dart';
// Add this import
import '../home/home_screen.dart'; // Add this import
// Add this import
import '../../widgets/booking_card.dart';
import '../../models/user_model.dart'; // Update import

class BookingsScreen extends StatefulWidget {
  final User user;
  final bool showNavigation; // Add this parameter

  const BookingsScreen({
    Key? key,
    required this.user,
    this.showNavigation = false, // Default to false
  }) : super(key: key);

  @override
  _BookingsScreenState createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final _storage = const FlutterSecureStorage();
  final BookingService _bookingService = BookingService();
  final WebSocketService _webSocketService = WebSocketService();
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _error;
  String? _userId;
  Map<String, String>? _profileData;
  int _currentIndex = 2; // Default to bookings tab

  @override
  void initState() {
    super.initState();
    print('BookingsScreen initialized');
    _loadUserCredentials();
    _loadProfileData();
    _setupWebSocketListener();
  }

  Future<void> _loadUserCredentials() async {
    try {
      // Get credentials using the same keys used in login
      final userId = await _storage.read(key: 'userId');
      final token = await _storage.read(key: 'token');
      final userType = await _storage.read(key: 'userType');

      print('Loading credentials from storage:');
      print('UserID: $userId');
      print('UserType: $userType');
      print('Has token: ${token != null}');

      if (userId == null) {
        throw Exception('User ID not found in storage');
      }

      setState(() {
        _userId = userId;
      });

      await _loadBookings(userId);
    } catch (e) {
      print('Error loading credentials: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading credentials: $e')),
        );
      }
    }
  }

  Future<void> _loadProfileData() async {
    try {
      final name = await _storage.read(key: 'name');
      final email = await _storage.read(key: 'email');

      if (mounted) {
        setState(() {
          _profileData = {
            'name': name ?? 'User',
            'email': email ?? 'user@example.com',
          };
        });
      }
    } catch (e) {
      print('Error loading profile data: $e');
    }
  }

  Future<void> _loadBookings(String userId) async {
    if (userId.isEmpty) {
      setState(() {
        _error = 'User ID is missing. Please login again.';
        _isLoading = false;
      });
      return;
    }

    try {
      print('Loading bookings for user: $userId');
      final bookings = await _bookingService.getClientBookings(userId);

      if (mounted) {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
          _error = null;
        });

        // Debug log the results
        print('Loaded ${_bookings.length} bookings');
        _bookings.forEach((booking) {
          print('Booking ID: ${booking.id}, Status: ${booking.status}');
        });
      }
    } catch (e) {
      print('Error loading bookings: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load bookings. Please try again.';
          _isLoading = false;
          _bookings = [];
        });
      }
    }
  }

  void _setupWebSocketListener() {
    _webSocketService.socket.on('booking_status_updated', (data) {
      if (data['clientId'] == _userId) {
        _loadBookings(_userId!);
      }
    });
  }

  @override
  void dispose() {
    _webSocketService.socket.off('booking_status_updated');
    super.dispose();
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_profileData?['name'] ?? 'User'),
            accountEmail: Text(_profileData?['email'] ?? 'user@example.com'),
            currentAccountPicture: CircleAvatar(
              child: Text(
                (_profileData?['name'] ?? 'U').substring(0, 1).toUpperCase(),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () => Navigator.pushReplacementNamed(context, '/home'),
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          // ...other drawer items...
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // Create User object from stored data
            final name = await _storage.read(key: 'name') ?? '';
            final email = await _storage.read(key: 'email') ?? '';
            final userType = await _storage.read(key: 'userType') ?? '';

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  user: User(
                    id: _userId ?? '',
                    name: name,
                    email: email,
                    userType: userType,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadBookings(_userId!),
              child: _error != null
                  ? _buildErrorView()
                  : _bookings.isEmpty
                      ? _buildEmptyView()
                      : _buildBookingsList(),
            ),
      bottomNavigationBar: widget.showNavigation
          ? BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
                switch (index) {
                  case 0:
                    Navigator.pushReplacementNamed(context, '/home');
                    break;
                  case 1:
                    Navigator.pushReplacementNamed(
                        context, '/select-service'); // Updated route
                    break;
                  case 2:
                    // Already on bookings screen
                    break;
                  case 3:
                    Navigator.pushReplacementNamed(context, '/profile');
                    break;
                }
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.book),
                  label: 'Bookings',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_circle),
                  label: 'Profile',
                ),
              ],
            )
          : null, // Conditionally show the bottom navigation bar
    );
  }

  Widget _buildBookingsList() {
    // Group bookings by status
    final Map<String, List<Booking>> groupedBookings = {
      'pending': [],
      'in_progress': [],
      'completed': [],
      'cancelled': [],
    };

    for (var booking in _bookings) {
      final status = booking.status.toLowerCase();
      groupedBookings[status]?.add(booking);
    }

    return ListView(
      padding: EdgeInsets.symmetric(vertical: 16),
      children: [
        if (groupedBookings['pending']!.isNotEmpty) ...[
          _buildStatusSection('Pending', groupedBookings['pending']!),
          SizedBox(height: 16),
        ],
        if (groupedBookings['in_progress']!.isNotEmpty) ...[
          _buildStatusSection('In Progress', groupedBookings['in_progress']!),
          SizedBox(height: 16),
        ],
        if (groupedBookings['completed']!.isNotEmpty) ...[
          _buildStatusSection('Completed', groupedBookings['completed']!),
          SizedBox(height: 16),
        ],
        if (groupedBookings['cancelled']!.isNotEmpty)
          _buildStatusSection('Cancelled', groupedBookings['cancelled']!),
      ],
    );
  }

  Widget _buildStatusSection(String title, List<Booking> bookings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        SizedBox(height: 8),
        ...bookings.map((booking) => BookingCard(
              booking: booking,
              onCancel: booking.status.toLowerCase() == 'pending'
                  ? () => _showCancelDialog(booking)
                  : null,
            )),
      ],
    );
  }

  void _showCancelDialog(Booking booking) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        // Use dialogContext instead of context
        title: Text('Cancel Booking'),
        content: Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog first

              try {
                await _bookingService.cancelBooking(booking.id);

                if (mounted) {
                  // Check if widget is still mounted
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Booking cancelled successfully')),
                  );
                  _loadBookings(_userId!); // Refresh the list
                }
              } catch (e) {
                if (mounted) {
                  // Check if widget is still mounted
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel booking: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Yes'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icon(Icons.check_circle, color: Colors.green);
      case 'pending':
        return Icon(Icons.pending, color: Colors.orange);
      case 'cancelled':
        return Icon(Icons.cancel, color: Colors.red);
      default:
        return Icon(Icons.help_outline, color: Colors.grey);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _capitalizeStatus(String status) {
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No bookings yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            'Your bookings will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            _error ?? 'Failed to load bookings',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _userId != null ? _loadBookings(_userId!) : null,
            icon: Icon(Icons.refresh),
            label: Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
