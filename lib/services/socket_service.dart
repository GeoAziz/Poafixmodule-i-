import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';
import '../models/booking.dart';

class SocketService {
  late IO.Socket socket;
  Function(Booking)? onBookingUpdate;
  Function(String)? onProviderLocation;

  void initialize() {
    socket = IO.io(ApiConfig.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.onConnect((_) => print('Socket connected'));
    socket.onDisconnect((_) => print('Socket disconnected'));
    socket.onError((error) => print('Socket error: $error'));

    socket.on('booking_update', (data) {
      if (onBookingUpdate != null) {
        final booking = Booking.fromJson(data);
        onBookingUpdate!(booking);
      }
    });

    socket.on('provider_location', (data) {
      if (onProviderLocation != null) {
        onProviderLocation!(data.toString());
      }
    });

    socket.connect();
  }

  void subscribeToBooking(String bookingId) {
    socket.emit('subscribe_booking', bookingId);
  }

  void unsubscribeFromBooking(String bookingId) {
    socket.emit('unsubscribe_booking', bookingId);
  }

  void disconnect() {
    socket.disconnect();
  }
}
