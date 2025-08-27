import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../services/booking_service.dart';
import '../../services/websocket.service.dart';
import '../../models/booking.dart';
import '../../models/job.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../services/job_service.dart';
import '../../services/notification_service.dart';
import '../../services/service_request.service.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class JobsScreen extends StatefulWidget {
  final String providerId;

  const JobsScreen({super.key, required this.providerId});

  @override
  _JobsScreenState createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> with TickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  final WebSocketService _webSocketService = WebSocketService();
  final _storage = const FlutterSecureStorage();
  final JobService _jobService = JobService();
  final NotificationService _notificationService = NotificationService();
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  String? _providerId;
  Map<String, dynamic>? _providerData;
  Timer? _refreshTimer;
  bool _autoRefresh = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final bool _isSearching = false;
  String _sortBy = 'date'; // 'date', 'status', 'client'

  @override
  void initState() {
    super.initState();
    _providerId = widget.providerId; // Use the provided ID directly
    _loadProviderData();
    _setupAutoRefresh();
    _tabController = TabController(length: 4, vsync: this);
    _setupWebSocketListeners();
  }

  Future<void> _loadProviderData() async {
    try {
      final providerId = await _storage.read(key: 'userId');
      final name = await _storage.read(key: 'name');
      final businessName = await _storage.read(key: 'businessName');

      if (providerId == null) throw Exception('Provider ID not found');

      setState(() {
        _providerId = providerId;
        _providerData = {'name': name, 'businessName': businessName};
      });

      await _fetchBookings();
    } catch (e) {
      print('Error loading provider data: $e');
      setState(() => _error = e.toString());
    }
  }

  void _setupAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(minutes: 1), (_) {
      if (_autoRefresh && mounted) {
        _fetchBookings();
      }
    });
  }

  void _setupWebSocketListeners() {
    if (_providerId == null) return;

    _webSocketService.socket.on('booking_created', (data) {
      if (data['providerId'] == _providerId) {
        _showNotification('New Booking', 'You have a new booking request');
        _fetchBookings();
      }
    });

    _webSocketService.socket.on('booking_updated', (data) {
      if (data['providerId'] == _providerId) {
        _fetchBookings();
      }
    });
  }

  Future<void> _fetchBookings() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get current provider ID
      final providerId = await _storage.read(key: 'userId');
      if (providerId == null) {
        throw Exception('Provider ID not found');
      }

      print('🔍 Fetching bookings for provider: $providerId');

      final List<Booking> bookings = await _bookingService
          .getProviderBookings();

      print('📦 Received ${bookings.length} bookings');
      for (var booking in bookings) {
        print('DEBUG Booking: id=${booking.id}, status=${booking.status}');
      }

      if (!mounted) return;

      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      print('⚠️ Error: $e');
      if (!mounted) return;

      setState(() {
        _error =
            'Unable to load bookings. Please check your connection and try again.';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load bookings'),
          action: SnackBarAction(label: 'Retry', onPressed: _fetchBookings),
          duration: Duration(seconds: 5),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Booking> _filterBookings(String status) {
    print('🔍 Filtering bookings for status: $status');
    final filtered = _bookings.where((booking) {
      final match = booking.status.toLowerCase() == status.toLowerCase();
      print(
        'DEBUG Filter: id=${booking.id}, status=${booking.status}, match=$match',
      );
      return match;
    }).toList();
    print('📊 Found ${filtered.length} bookings with status: $status');
    return filtered;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/empty_jobs.json',
            width: 200,
            height: 200,
            repeat: true,
          ),
          const SizedBox(height: 20),
          Text('No jobs yet', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          Text(
            'Your jobs will appear here',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _fetchBookings, child: Text('Refresh')),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/error.json',
            width: 200,
            height: 200,
            repeat: true,
          ),
          const SizedBox(height: 20),
          Text(
            'Oops! Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            'Error: ${_error ?? 'Failed to load jobs'}\nPlease ensure you are logged in as a service provider.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _fetchBookings, child: Text('Try Again')),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/loading.json',
            width: 200,
            height: 200,
            repeat: true,
          ),
          const SizedBox(height: 20),
          Text('Loading jobs...', style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<Booking> bookings) {
    if (bookings.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _fetchBookings,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return AnimationConfiguration.staggeredList(
      position: _bookings.indexOf(booking),
      duration: Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: _getStatusColor(booking.status),
                      width: 4,
                    ),
                  ),
                ),
                child: ExpansionTile(
                  title: Text(
                    booking.serviceType,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Client: ${booking.clientName}'),
                      Text(
                        'Date: ${DateFormat('MMM d, y').format(booking.scheduledDate)}',
                      ),
                    ],
                  ),
                  trailing: _buildStatusBadge(booking.status),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Time', booking.displayScheduledTime),
                          _buildDetailRow('Phone', booking.clientPhone),
                          _buildDetailRow('Address', booking.displayAddress),
                          if (booking.notes.isNotEmpty)
                            _buildDetailRow('Notes', booking.notes),
                          SizedBox(height: 16),
                          _buildActionButtons(booking),
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
  }

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        padding: EdgeInsets.all(16),
        itemBuilder: (context, index) => Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Container(
            height: 100,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 200, height: 20, color: Colors.white),
                SizedBox(height: 8),
                Container(width: 150, height: 16, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true, // Add this to make tabs scrollable
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
        ),
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        tabs: [
          _buildTab('Pending', Icons.schedule),
          _buildTab('Accepted', Icons.check_circle),
          _buildTab('In Progress', Icons.engineering),
          _buildTab('Completed', Icons.done_all),
        ],
      ),
    );
  }

  Widget _buildTab(String text, IconData icon) {
    return Tab(
      height: 50, // Add fixed height
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8), // Add horizontal padding
        child: Row(
          mainAxisSize: MainAxisSize.min, // Change to min
          children: [
            Icon(icon, size: 16),
            SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(fontSize: 13), // Reduce font size slightly
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: _isSearching ? 60 : 0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search bookings...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.sort),
              onSelected: (value) {
                setState(() => _sortBy = value);
                _sortBookings();
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'date', child: Text('Sort by Date')),
                PopupMenuItem(value: 'status', child: Text('Sort by Status')),
                PopupMenuItem(value: 'client', child: Text('Sort by Client')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sortBookings() {
    setState(() {
      _bookings.sort((a, b) {
        switch (_sortBy) {
          case 'date':
            return b.scheduledDate.compareTo(a.scheduledDate);
          case 'status':
            return a.status.compareTo(b.status);
          case 'client':
            return a.clientName.compareTo(b.clientName);
          default:
            return 0;
        }
      });
    });
  }

  Future<void> _handleBookingAction(Booking booking, String action) async {
    // Show confirmation dialog before proceeding
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action.capitalize()} Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to ${action.toLowerCase()} this booking?',
            ),
            SizedBox(height: 16),
            // Job Preview
            _buildBookingPreview(booking),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'accept' ? Colors.green : Colors.red,
            ),
            child: Text(action.capitalize()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      _showLoadingDialog(message: '${action.capitalize()}ing booking...');

      if (action == 'accept') {
        final result = await _bookingService.acceptBooking(booking.id);

        // Handle both booking and job
        final updatedBooking = result['booking'] as Booking;
        final newJob = result['job'] as Job;

        _updateBookingInList(updatedBooking);

        // First dismiss the loading dialog
        Navigator.of(context, rootNavigator: true).pop();

        // Show success message with job details
        await _showJobCreatedDialog(newJob);

        // Automatic refresh and switch to Accepted tab
        await _fetchBookings();
        _tabController.animateTo(1);
      } else if (action == 'reject') {
        await _bookingService.rejectBooking(booking.id);
        Navigator.of(context, rootNavigator: true).pop();
        _showSnackBar('Booking rejected successfully', Colors.red);
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _handleBookingResponse(String bookingId, String status) async {
    try {
      setState(() => _isLoading = true);

      // Update booking status
      final response = await _jobService.updateBookingStatus(
        bookingId: bookingId,
        status: status,
        providerId: widget.providerId,
      );

      if (response['success']) {
        // Safely access serviceRequestId
        final booking = response['booking'];
        final serviceRequestId =
            booking != null && booking.containsKey('serviceRequestId')
            ? booking['serviceRequestId']
            : null;

        // Update service request status only if serviceRequestId exists
        if (serviceRequestId != null) {
          await ServiceRequestService().updateRequestStatus(
            serviceRequestId,
            status,
            status == 'rejected' ? 'Booking rejected by provider' : null,
          );
        } else {
          print(
            'Warning: booking missing serviceRequestId, skipping updateRequestStatus',
          );
        }

        // Ensure clientId is present before creating notification
        final clientId = booking != null && booking.containsKey('clientId')
            ? booking['clientId']
            : null;
        if (clientId == null) {
          print(
            'Warning: booking missing clientId, notification will not be sent',
          );
        } else {
          await _notificationService.createNotification({
            'recipientId': clientId,
            'recipientModel': 'Client',
            'type': status == 'accepted'
                ? 'BOOKING_ACCEPTED'
                : 'BOOKING_REJECTED',
            'title': 'Booking ${status.toUpperCase()}',
            'message': 'Your booking request has been $status',
            'data': {
              'bookingId': bookingId,
              'status': status,
              'serviceType': booking?['serviceType'],
            },
          });
        }

        // Emit socket event
        _webSocketService.socket.emit('booking_status_update', {
          'bookingId': bookingId,
          'status': status,
          'providerId': widget.providerId,
        });

        await _fetchBookings();
      }
    } catch (e) {
      print('Error handling booking: $e');
      _showSnackBar('Failed to update booking: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildBookingPreview(Booking booking) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            _buildDetailRow('Service', booking.displayServiceName),
            _buildDetailRow('Client', booking.displayClientName),
            _buildDetailRow(
              'Date',
              DateFormat('MMM d, y').format(booking.scheduledDate),
            ),
            _buildDetailRow('Time', booking.displayScheduledTime),
            _buildDetailRow(
              'Location',
              booking.location?['address'] ?? 'No address provided',
            ),
            if (booking.notes.isNotEmpty == true)
              _buildDetailRow('Notes', booking.notes),
            _buildDetailRow('Amount', '\$${booking.amount.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildJobPreview(Job job) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            _buildDetailRow('Service', job.serviceType),
            _buildDetailRow('Client', job.clientName),
            _buildDetailRow(
              'Date',
              DateFormat('MMM d, y').format(job.scheduledDate),
            ),
            _buildDetailRow('Time', job.scheduledTime),
            _buildDetailRow(
              'Location',
              job.location['address'] ?? 'No address provided',
            ),
            if (job.notes?.isNotEmpty == true)
              _buildDetailRow('Notes', job.notes!),
            _buildDetailRow('Status', job.status),
          ],
        ),
      ),
    );
  }

  Future<void> _showJobCreatedDialog(Job job) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Job Created Successfully'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Job #${job.id} has been created.'),
            SizedBox(height: 16),
            _buildJobPreview(job),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to job details screen
              // TODO: Implement job details navigation
            },
            child: Text('View Job Details'),
          ),
        ],
      ),
    );
  }

  // Add improved loading dialog with message
  void _showLoadingDialog({String message = 'Processing...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(message),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotification(String title, String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(message),
          ],
        ),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _tabController.animateTo(0), // Switch to Pending tab
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Booking booking) {
    if (booking.status.toLowerCase() == 'pending') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () => _handleBookingResponse(booking.id, 'accepted'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Accept'),
          ),
          ElevatedButton(
            onPressed: () => _handleBookingResponse(booking.id, 'rejected'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reject'),
          ),
        ],
      );
    } else if (booking.status.toLowerCase() == 'accepted') {
      return Center(
        child: ElevatedButton(
          onPressed: () => _handleJobAction(booking.id, 'in_progress'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: Text('Start Job'),
        ),
      );
    } else if (booking.status.toLowerCase() == 'in_progress') {
      return Center(
        child: ElevatedButton(
          onPressed: () => _handleJobAction(booking.id, 'completed'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          child: Text('Complete Job'),
        ),
      );
    }
    return SizedBox.shrink();
  }

  Future<void> _handleJobAction(String bookingId, String status) async {
    try {
      setState(() => _isLoading = true);

      // Update booking status
      final response = await _jobService.updateBookingStatus(
        bookingId: bookingId,
        status: status,
        providerId: widget.providerId,
      );

      if (response['success']) {
        final booking = response['booking'];
        if (booking != null && booking['clientId'] != null) {
          // 1. Notify client that job is completed
          await _notificationService.createNotification({
            'recipientId': booking['clientId'],
            'recipientModel': 'Client',
            'type': 'JOB_COMPLETED',
            'title': 'Job Completed',
            'message': 'Your job has been completed by the provider.',
            'data': {
              'bookingId': bookingId,
              'status': status,
              'serviceType': booking['serviceType'],
              'action': 'completed',
            },
          });

          // 2. Notify client that payment is required
          await _notificationService.createNotification({
            'recipientId': booking['clientId'],
            'recipientModel': 'Client',
            'type': 'PAYMENT_REQUEST',
            'title': 'Payment Required',
            'message': 'Please proceed to payment for your completed job.',
            'data': {
              'bookingId': bookingId,
              'status': status,
              'serviceType': booking['serviceType'],
              'amount': booking['amount'],
            },
          });

          // Optionally emit socket events for both
          _webSocketService.socket.emit('job_status_update', {
            'bookingId': bookingId,
            'status': status,
            'providerId': widget.providerId,
          });
          _webSocketService.socket.emit('payment_request', {
            'clientId': booking['clientId'],
            'bookingId': bookingId,
            'providerId': widget.providerId,
          });
        }
        await _fetchBookings();
      }
    } catch (e) {
      print('Error handling job action: $e');
      _showSnackBar('Failed to update job: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTabBar(),
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                ? _buildErrorState()
                : RefreshIndicator(
                    onRefresh: _fetchBookings,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBookingsList(_filterBookings('pending')),
                        _buildBookingsList(_filterBookings('accepted')),
                        _buildBookingsList(_filterBookings('in_progress')),
                        _buildBookingsList(_filterBookings('completed')),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchBookings,
        child: Icon(Icons.refresh),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.green;
      case 'completed':
        return Colors.purple;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  void _updateBookingInList(Booking updatedBooking) {
    setState(() {
      final index = _bookings.indexWhere((b) => b.id == updatedBooking.id);
      if (index != -1) {
        _bookings[index] = updatedBooking;
      }
    });
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    _webSocketService.socket.off('booking_created');
    _webSocketService.socket.off('booking_updated');
    _tabController.dispose();
    super.dispose();
  }
}
