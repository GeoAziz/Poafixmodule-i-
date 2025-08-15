import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../models/booking.dart';
import '../models/user_model.dart';
import '../services/booking_service.dart';
import '../models/calendar_event.dart';

class EnhancedCalendarScreen extends StatefulWidget {
  final User user;

  const EnhancedCalendarScreen({
    super.key,
    required this.user,
  });

  @override
  _EnhancedCalendarScreenState createState() => _EnhancedCalendarScreenState();
}

class _EnhancedCalendarScreenState extends State<EnhancedCalendarScreen>
    with TickerProviderStateMixin {
  late BookingService _bookingService;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<CalendarEvent>> _events = {};
  bool _isLoading = true;
  bool _isUploading = false;
  String? _uploadingFile;

  // Animation controllers
  late AnimationController _calendarAnimationController;
  late AnimationController _eventListAnimationController;
  late Animation<double> _calendarAnimation;
  late Animation<double> _eventListAnimation;

  @override
  void initState() {
    super.initState();
    _bookingService = BookingService();
    _selectedDay = _focusedDay;

    // Initialize animations
    _calendarAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _eventListAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    _calendarAnimation = CurvedAnimation(
      parent: _calendarAnimationController,
      curve: Curves.easeInOut,
    );

    _eventListAnimation = CurvedAnimation(
      parent: _eventListAnimationController,
      curve: Curves.easeInOut,
    );

    _loadEvents();
  }

  @override
  void dispose() {
    _calendarAnimationController.dispose();
    _eventListAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await _bookingService.getProviderBookings();
      setState(() {
        _events = _groupEventsByDate(bookings);
        _isLoading = false;
      });
      _calendarAnimationController.forward();
      _eventListAnimationController.forward();
    } catch (e) {
      print('Error loading events: $e');
      setState(() => _isLoading = false);
      _showError('Failed to load calendar events');
    }
  }

  Map<DateTime, List<CalendarEvent>> _groupEventsByDate(
      List<Booking> bookings) {
    Map<DateTime, List<CalendarEvent>> grouped = {};
    for (var booking in bookings) {
      final date = DateTime(
        booking.scheduledDate.year,
        booking.scheduledDate.month,
        booking.scheduledDate.day,
      );
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(CalendarEvent.fromBooking(booking));
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Schedule',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Refresh Calendar',
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter Events',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickStats(),
          FadeTransition(
            opacity: _calendarAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, -0.1),
                end: Offset.zero,
              ).animate(_calendarAnimation),
              child: _buildCalendar(),
            ),
          ),
          Expanded(
            child: FadeTransition(
              opacity: _eventListAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(_eventListAnimation),
                child: _isLoading ? _buildLoadingState() : _buildEventList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEventDialog,
        label: Text('Block Time'),
        icon: Icon(Icons.block),
        tooltip: 'Block time slot',
      ),
    );
  }

  Widget _buildQuickStats() {
    final todayEvents = _events[DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        )] ??
        [];

    final upcomingCount = _events.values
        .expand((e) => e)
        .where((e) => e.date.isAfter(DateTime.now()))
        .length;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Colors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            'Today',
            '${todayEvents.length}',
            Icons.today,
          ),
          _buildStatCard(
            'Upcoming',
            '$upcomingCount',
            Icons.upcoming,
          ),
          _buildStatCard(
            'Completed',
            '${_events.values.expand((e) => e).where((e) => e.status == 'completed').length}',
            Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      margin: EdgeInsets.all(8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: TableCalendar(
        firstDay: DateTime.now().subtract(Duration(days: 365)),
        lastDay: DateTime.now().add(Duration(days: 365)),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: (day) => _events[day] ?? [],
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _eventListAnimationController.forward(from: 0);
        },
        onFormatChanged: (format) {
          setState(() => _calendarFormat = format);
        },
        calendarStyle: CalendarStyle(
          markersMaxCount: 3,
          markerDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/calendar-loading.json',
            width: 200,
            height: 200,
          ),
          SizedBox(height: 16),
          Text(
            'Loading your schedule...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final events = _events[_selectedDay] ?? [];

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/empty-calendar.json',
              width: 200,
              height: 200,
            ),
            SizedBox(height: 16),
            Text(
              'No events for ${DateFormat('MMMM d, y').format(_selectedDay!)}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    final isExpiring = event.status == 'pending' &&
        event.date.difference(DateTime.now()).inDays <= 7;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border:
                isExpiring ? Border.all(color: Colors.orange, width: 2) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildEventTypeIcon(event.type),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          event.description,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(event.status),
                ],
              ),
              if (isExpiring) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Expires in ${event.date.difference(DateTime.now()).inDays} days',
                        style: GoogleFonts.poppins(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (event.comment != null) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.comment, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.comment!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventTypeIcon(String type) {
    final iconData = {
          'booking': Icons.calendar_today,
          'job': Icons.work,
          'blocked': Icons.block,
        }[type] ??
        Icons.event;

    final color = {
          'booking': Colors.blue,
          'job': Colors.green,
          'blocked': Colors.red,
        }[type] ??
        Colors.grey;

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = {
          'pending': Colors.orange,
          'confirmed': Colors.green,
          'completed': Colors.blue,
          'cancelled': Colors.red,
        }[status] ??
        Colors.grey;

    final icon = {
          'pending': Icons.hourglass_empty,
          'confirmed': Icons.check_circle,
          'completed': Icons.done_all,
          'cancelled': Icons.cancel,
        }[status] ??
        Icons.help;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(CalendarEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  _buildEventTypeIcon(event.type),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, MMMM d, y').format(event.date),
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(event.status),
                ],
              ),
              SizedBox(height: 24),
              _buildDetailSection('Description', event.description),
              if (event.comment != null)
                _buildDetailSection('Admin Comment', event.comment!),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (event.status == 'pending') ...[
                    _buildActionButton(
                      'Accept',
                      Icons.check,
                      Colors.green,
                      () => _handleEventAction(event, 'accept'),
                    ),
                    _buildActionButton(
                      'Reject',
                      Icons.close,
                      Colors.red,
                      () => _handleEventAction(event, 'reject'),
                    ),
                  ],
                  if (event.status == 'confirmed')
                    _buildActionButton(
                      'Complete',
                      Icons.done_all,
                      Colors.blue,
                      () => _handleEventAction(event, 'complete'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            content,
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: GoogleFonts.poppins(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _handleEventAction(CalendarEvent event, String action) async {
    try {
      // TODO: Implement action handling with your booking service
      Navigator.pop(context);
      _showSuccess('Event ${action}ed successfully');
      _loadEvents();
    } catch (e) {
      _showError('Failed to $action event: $e');
    }
  }

  void _showAddEventDialog() {
    // TODO: Implement add event dialog
  }

  void _showFilterDialog() {
    // TODO: Implement filter dialog
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
