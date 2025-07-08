import 'dart:io';

class DbConfig {
  static String get mongoUrl {
    if (Platform.isAndroid) {
      return 'mongodb://10.0.2.2:27017/home_service_db?directConnection=true';
    }
    return 'mongodb://127.0.0.1:27017/home_service_db?directConnection=true';
  }

  static const int connectionTimeout = 30000; // 30 seconds
  static const int maxRetries = 5;
  static const int socketTimeout = 30000; // 30 seconds

  static Map<String, dynamic> get options => {
        'connectTimeoutMS': connectionTimeout,
        'socketTimeoutMS': socketTimeout,
        'serverSelectionTimeoutMS': connectionTimeout,
        'retryWrites': true,
        'directConnection': true
      };
}
