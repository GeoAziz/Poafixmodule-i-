import 'package:dio/dio.dart';

class AuthLoggingInterceptor extends Interceptor {
  @override
  Future onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    print('🚀 Sending Request');
    print('URL: ${options.path}');
    print('METHOD: ${options.method}');
    print('HEADERS: ${options.headers}');
    print('BODY: ${options.data}');
    return super.onRequest(options, handler);
  }

  @override
  Future onResponse(
      Response response, ResponseInterceptorHandler handler) async {
    print('✅ Received Response');
    print('STATUS CODE: ${response.statusCode}');
    print('DATA: ${response.data}');
    return super.onResponse(response, handler);
  }

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    print('❌ Error Occurred');
    print('MESSAGE: ${err.message}');
    print('RESPONSE: ${err.response?.data}');
    print('STATUS CODE: ${err.response?.statusCode}');
    return super.onError(err, handler);
  }
}
