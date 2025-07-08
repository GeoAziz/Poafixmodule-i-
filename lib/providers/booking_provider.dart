import 'package:flutter/foundation.dart';
import '../core/services/booking_service.dart';
import '../core/models/booking_model.dart';

class BookingProvider with ChangeNotifier {
  final BookingService _bookingService = BookingService();

  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Optionally, you could add an init() method to initialize or reset the state
  void init() {
    _bookings = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // Fetch bookings for a user
  Future<void> fetchUserBookings(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _bookings = await _bookingService.getUserBookings(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new booking
  Future<void> createBooking(Map<String, dynamic> bookingData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newBooking = await _bookingService.createBooking(bookingData);
      _bookings.add(newBooking);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancel a booking
  Future<void> cancelBooking(String bookingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _bookingService.cancelBooking(bookingId);
      _bookings.removeWhere((booking) => booking.id == bookingId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _bookingService.updateBookingStatus(bookingId, status);
      final booking = _bookings.firstWhere((b) => b.id == bookingId);
      booking.status = status; // Assuming BookingModel has a status field
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
