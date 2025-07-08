import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../services/socket_service.dart';

class BookingNotifier extends ChangeNotifier {
  final SocketService _socketService = SocketService();
  Booking? _currentBooking;
  bool _isLoading = false;

  Booking? get currentBooking => _currentBooking;
  bool get isLoading => _isLoading;

  void initialize(Booking booking) {
    _currentBooking = booking;
    _subscribeToUpdates(booking);
  }

  void _subscribeToUpdates(Booking booking) {
    _socketService.onBookingUpdate = (updatedBooking) {
      _currentBooking = updatedBooking;
      notifyListeners();
    };
    _socketService.subscribeToBooking(booking.id);
  }

  void updateBookingStatus(String newStatus) {
    if (_currentBooking != null) {
      _currentBooking = _currentBooking!.copyWith(status: newStatus);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_currentBooking != null) {
      _socketService.unsubscribeFromBooking(_currentBooking!.id);
    }
    super.dispose();
  }
}
