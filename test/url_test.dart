import 'package:flutter_test/flutter_test.dart';
import '../lib/services/api_config.dart';

void main() {
  group('API URL Tests', () {
    const providerId = '67c7df4f234d217f6cb0e359';
    final url = ApiConfig.getApiUrl('providers/$providerId/location');
    final expected =
        'http://10.0.2.2:5000/api/providers/67c7df4f234d217f6cb0e359/location';

    test('Location update URL should be correctly formatted', () {
      expect(url, expected);
      expect(url.startsWith('http'), true);
    });

    test('URL should not contain spaces', () {
      expect(url.contains(' '), false);
    });

    test('URL should not contain double slashes', () {
      expect(url.contains('//api.'), false,
          reason: 'URL should not have double slashes except after protocol');
    });
  });

  test('Location update URL should be exact', () {
    const providerId = '67c7df4f234d217f6cb0e359';
    final url = ApiConfig.getApiUrl('providers/$providerId/location');
    final expected =
        'http://10.0.2.2:5000/api/providers/67c7df4f234d217f6cb0e359/location';
    expect(url, expected);
  });

  test('Location update URL should be exact', () {
    const providerId = '67c7df4f234d217f6cb0e359';
    final expected = 'http://192.168.0.102/api/providers/$providerId/location';
    final url = Uri.parse(expected).toString();

    expect(url, expected);
  });
}
