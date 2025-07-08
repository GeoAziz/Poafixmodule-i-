import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  ApiService() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(milliseconds: 5000);
    _dio.options.receiveTimeout = const Duration(milliseconds: 3000);

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) {
        print('API Error: ${error.message}');
        if (error.response != null) {
          print('Error Response: ${error.response?.data}');
        }
        return handler.next(error);
      },
    ));
  }

  Future<Response> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      print('GET Request to $endpoint with params: $queryParams');
      final response = await _dio.get(endpoint, queryParameters: queryParams);
      print('Response: ${response.data}');
      return response;
    } on DioException catch (e) {
      print('DioError: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Response> post(String endpoint, {dynamic data}) async {
    try {
      print('POST Request to $endpoint with data: $data');
      final response = await _dio.post(endpoint, data: data);
      print('Response: ${response.data}');
      return response;
    } on DioException catch (e) {
      print('DioError: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Response> put(String endpoint, {dynamic data}) async {
    try {
      print('PUT Request to $endpoint with data: $data');
      final response = await _dio.put(endpoint, data: data);
      print('Response: ${response.data}');
      return response;
    } on DioException catch (e) {
      print('DioError: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Response> patch(String endpoint, {dynamic data}) async {
    try {
      print('PATCH Request to $endpoint with data: $data');
      final response = await _dio.patch(endpoint, data: data);
      print('Response: ${response.data}');
      return response;
    } on DioException catch (e) {
      print('DioError: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Response> delete(String endpoint) async {
    try {
      print('DELETE Request to $endpoint');
      final response = await _dio.delete(endpoint);
      print('Response: ${response.data}');
      return response;
    } on DioException catch (e) {
      print('DioError: ${e.response?.data}');
      rethrow;
    }
  }

  Future<void> setAuthToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> clearAuthToken() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }
}