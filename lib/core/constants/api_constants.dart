class ApiConstants {
  // Base URL
  static const String baseUrl = 'http://your-backend-url.com/api';

  // Authentication endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String resetPasswordEndpoint = '/auth/reset-password';

  // User endpoints
  static const String getUserEndpoint = '/users';

  // Booking endpoints
  static const String bookingsEndpoint = '/bookings';
  static const String createBookingEndpoint = bookingsEndpoint;
  static const String getUserBookingsEndpoint = '$bookingsEndpoint/user';
  static String bookingByIdEndpoint(String id) => '$bookingsEndpoint/$id';
  static String updateBookingStatusEndpoint(String id) =>
      '$bookingsEndpoint/$id/status';
  static String cancelBookingEndpoint(String id) =>
      '$bookingsEndpoint/$id/cancel';

  // Service endpoints
  static const String servicesEndpoint = '/services';
  static const String getServicesEndpoint = servicesEndpoint;
  static String getServiceByIdEndpoint(String id) => '$servicesEndpoint/$id';

  // Payment endpoints
  static const String paymentsEndpoint = '/payments';
  static const String createPaymentEndpoint = paymentsEndpoint;
  static String getPaymentHistoryEndpoint(String userId) =>
      '$paymentsEndpoint/user/$userId';
  static String processPaymentEndpoint(String bookingId) =>
      '$paymentsEndpoint/process/$bookingId';
}
