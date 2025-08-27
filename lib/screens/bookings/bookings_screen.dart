import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../services/websocket_service.dart';
// Add this import
// Add this import
// Add this import
import '../../widgets/booking_card.dart';
import '../../models/user_model.dart'; // Update import
import '../../widgets/client_sidepanel.dart';

// Helper class for section data
class _StatusSectionData {
  final String title;
  final List<Booking> bookings;
  _StatusSectionData(this.title, this.bookings);
}

class BookingsScreen extends StatefulWidget {
  final User user;
  final bool showNavigation;

  const BookingsScreen({
    super.key,
    required this.user,
    this.showNavigation = false,
  });

  @override
  _BookingsScreenState createState() => _BookingsScreenState();
}

// TabBar controller for status filter
final List<_BookingTab> _tabs = [
  _BookingTab('Pending', Icons.pending, 'pending'),
  _BookingTab('In Progress', Icons.play_circle, 'in_progress'),
  _BookingTab('Completed', Icons.check_circle, 'completed'),
  _BookingTab('Cancelled', Icons.cancel, 'cancelled'),
];

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

  // Add the missing _showCancelDialog method
  void _showCancelDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancel Booking'),
          content: Text('Are you sure you want to cancel this booking?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() {
                  _isLoading = true;
                });
                try {
                  await _bookingService.cancelBooking(booking.id);
                  await _loadBookings(_userId!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Booking cancelled successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to cancel booking: $e')),
                  );
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

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
      final token = await _storage.read(key: 'auth_token');
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
        for (var booking in _bookings) {
          print('Booking ID: ${booking.id}, Status: ${booking.status}');
        }
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
    return ClientSidePanel(user: widget.user, parentContext: context);
  }

  // Restore and enhance _buildStatusSection
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
        ...bookings.map(
          (booking) => BookingCard(
            booking: booking,
            onCancel: booking.status.toLowerCase() == 'pending'
                ? () => _showCancelDialog(booking)
                : null,
          ),
        ),
      ],
    );
  }

  // Restore and enhance _buildEmptyView
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: 'No bookings illustration',
            child: Icon(Icons.calendar_today, size: 64, color: Colors.grey),
          ),
          SizedBox(height: 16),
          Text(
            'No bookings yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            'Your bookings will appear here',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/select-service',
                (route) => false,
                arguments: widget.user,
              );
            },
            icon: Icon(Icons.add_box),
            label: Text('Book a Service'),
          ),
        ],
      ),
    );
  }

  // Restore and enhance _buildErrorView
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: 'Error illustration',
            child: Icon(Icons.error_outline, size: 64, color: Colors.red),
          ),
          SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            _error ?? 'Failed to load bookings',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
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

    final List<_StatusSectionData> sections = [];
    if (groupedBookings['pending']!.isNotEmpty) {
      sections.add(_StatusSectionData('Pending', groupedBookings['pending']!));
    }
    if (groupedBookings['in_progress']!.isNotEmpty) {
      sections.add(
        _StatusSectionData('In Progress', groupedBookings['in_progress']!),
      );
    }
    if (groupedBookings['completed']!.isNotEmpty) {
      sections.add(
        _StatusSectionData('Completed', groupedBookings['completed']!),
      );
    }
    if (groupedBookings['cancelled']!.isNotEmpty) {
      sections.add(
        _StatusSectionData('Cancelled', groupedBookings['cancelled']!),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 16),
      itemCount: sections.length,
      itemBuilder: (context, sectionIndex) {
        final section = sections[sectionIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusSection(section.title, section.bookings),
            SizedBox(height: 16),
          ],
        );
      },
    );
  }

  // If you have _showCancelDialog, keep it here as well

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bookings'),
          bottom: TabBar(
            isScrollable: false,
            indicatorColor: Theme.of(context).colorScheme.primary,
            indicatorWeight: 3,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: _tabs
                .map((tab) => Tab(icon: Icon(tab.icon), text: tab.label))
                .toList(),
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
                    : TabBarView(
                        physics: const BouncingScrollPhysics(),
                        children: _tabs.map((tab) {
                          final filtered = _bookings
                              .where(
                                (b) => b.status.toLowerCase() == tab.statusKey,
                              )
                              .toList();
                          return filtered.isEmpty
                              ? _buildEmptyTabView(tab.label)
                              : ListView.builder(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, idx) {
                                    final booking = filtered[idx];
                                    return BookingCard(
                                      booking: booking,
                                      onCancel:
                                          booking.status.toLowerCase() ==
                                              'pending'
                                          ? () => _showCancelDialog(booking)
                                          : null,
                                    );
                                  },
                                );
                        }).toList(),
                      ),
              ),
      ),
    );
  }
}

// Helper class for TabBar tabs
class _BookingTab {
  final String label;
  final IconData icon;
  final String statusKey;
  _BookingTab(this.label, this.icon, this.statusKey);
}

// Empty tab view for each status
Widget _buildEmptyTabView(String label) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          label: 'No $label bookings illustration',
          child: Icon(Icons.inbox, size: 64, color: Colors.grey),
        ),
        SizedBox(height: 16),
        Text(
          'No $label bookings',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Swipe to see other statuses',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    ),
  );
}
