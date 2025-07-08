import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../utils/date_formatter.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onCancel;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool isProviderView;
  final BuildContext? parentContext; // Add this field

  const BookingCard({
    Key? key,
    required this.booking,
    this.onCancel,
    this.onAccept,
    this.onReject,
    this.isProviderView = false,
    this.parentContext, // Add this parameter
  }) : super(key: key);

  Color _getStatusColor() {
    switch (booking.status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          ListTile(
            title: Text(
              booking.serviceType ?? 'Unknown Service',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                booking.status.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Divider(),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  Icons.calendar_today,
                  'Scheduled for:',
                  DateFormatter.formatScheduledDate(booking.scheduledDate),
                  context, // Pass context here
                ),
                SizedBox(height: 8),
                _buildInfoRow(
                  Icons.access_time,
                  'Booked:',
                  DateFormatter.getRelativeDate(
                      booking.createdAt ?? DateTime.now()),
                  context, // Pass context here
                ),
                SizedBox(height: 8),
                _buildInfoRow(
                  Icons.attach_money,
                  'Amount:',
                  'KES ${booking.amount}',
                  context, // Pass context here
                ),
              ],
            ),
          ),
          if (booking.status.toLowerCase() == 'pending')
            Padding(
              padding: EdgeInsets.all(12),
              child: isProviderView
                  ? Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onAccept,
                            icon: Icon(Icons.check_circle, color: Colors.green),
                            label: Text('Accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.withOpacity(0.1),
                              foregroundColor: Colors.green,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onReject,
                            icon: Icon(Icons.cancel, color: Colors.red),
                            label: Text('Reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.1),
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: onCancel,
                      icon: Icon(Icons.cancel, color: Colors.red),
                      label: Text('Cancel Booking'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        foregroundColor: Colors.red,
                        minimumSize: Size(double.infinity, 44),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, BuildContext context) {
    // Add context parameter
    return MouseRegion(
      cursor: label == 'Booked:'
          ? SystemMouseCursors.help
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: label == 'Booked:'
            ? (details) => _showDateTimeTooltip(details, context)
            : null, // Pass context
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDateTimeTooltip(TapDownDetails details, BuildContext context) {
    // Add context parameter
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          child: Text(
            DateFormatter.getFullDateTime(booking.createdAt ?? DateTime.now()),
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
