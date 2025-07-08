import '../services/api_service.dart';
import '../constants/api_constants.dart';
import '../models/booking_model.dart';

class BookingService {
  final ApiService _apiService = ApiService();

  // Booking status constants
  static const String STATUS_PENDING = 'pending';
  static const String STATUS_CONFIRMED = 'confirmed';
  static const String STATUS_COMPLETED = 'completed';
  static const String STATUS_CANCELLED = 'cancelled';

  Future<List<BookingModel>> getUserBookings(String userId) async {
    try {
      final response = await _apiService
          .get('${ApiConstants.getUserBookingsEndpoint}/$userId');

      return (response.data as List)
          .map((booking) => BookingModel.fromJson(booking))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<BookingModel> createBooking(Map<String, dynamic> bookingData) async {
    try {
      final response = await _apiService
          .post(ApiConstants.createBookingEndpoint, data: bookingData);

      return BookingModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await _apiService
          .post('${ApiConstants.bookingsEndpoint}/$bookingId/cancel');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _apiService.patch(
        '${ApiConstants.bookingsEndpoint}/$bookingId',
        data: {'status': status},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<BookingModel> getBooking(String bookingId) async {
    try {
      final response =
          await _apiService.get('${ApiConstants.bookingsEndpoint}/$bookingId');

      return BookingModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
