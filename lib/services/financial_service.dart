import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/mpesa_transaction.dart';
import '../config/api_config.dart';
import '../services/auth_storage.dart';

class FinancialService {
  final AuthStorage _authStorage = AuthStorage();
  String? _token;
  String? _userId;

  void updateToken(String token) {
    _token = token;
    // Parse JWT token to get user ID
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = json.decode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
        _userId = payload['id'];
        print('Extracted user ID from token: $_userId');
      }
    } catch (e) {
      print('Error parsing JWT token: $e');
    }
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      };

  Future<String?> _getUserId() async {
    if (_userId != null) return _userId;

    final credentials = await _authStorage.getCredentials();
    return credentials['id'] ?? credentials['user_id'];
  }

  Future<List<MpesaTransaction>> getTransactions() async {
    if (_token == null) throw Exception('Not authenticated - no token');
    try {
      final providerId = await _getUserId();
      if (providerId == null) {
        throw Exception('Not authenticated - no user ID');
      }

      print('Fetching transactions for provider: $providerId');
      print('Using token: $_token');

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/transactions?providerId=$providerId'),
        headers: _headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final transactions = (data['data'] as List)
              .map((json) {
                try {
                  return MpesaTransaction.fromJson(json);
                } catch (e) {
                  print('Error parsing transaction: $e');
                  return null;
                }
              })
              .whereType<MpesaTransaction>()
              .toList();

          print('Parsed ${transactions.length} transactions');
          return transactions;
        }
      }
      throw Exception('Failed to load transactions: ${response.statusCode}');
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getEarningsSummary() async {
    if (_token == null) throw Exception('Not authenticated - no token');
    try {
      final providerId = await _getUserId();
      if (providerId == null) {
        throw Exception('Not authenticated - no user ID');
      }

      // Calculate summary from transactions if endpoint is not available
      final transactions = await getTransactions();
      final now = DateTime.now();
      final weekAgo = now.subtract(Duration(days: 7));

      final totalEarnings =
          transactions.fold(0.0, (sum, tx) => sum + tx.amount);
      final weeklyEarnings = transactions
          .where((tx) => tx.timestamp.isAfter(weekAgo))
          .fold(0.0, (sum, tx) => sum + tx.amount);
      final pendingAmount = transactions
          .where((tx) => tx.status == 'pending')
          .fold(0.0, (sum, tx) => sum + tx.amount);

      return {
        'success': true,
        'data': {
          'totalEarnings': totalEarnings,
          'weeklyEarnings': weeklyEarnings,
          'pendingAmount': pendingAmount,
        }
      };
    } catch (e) {
      print('Error calculating summary: $e');
      return {
        'success': false,
        'data': {
          'totalEarnings': 0.0,
          'weeklyEarnings': 0.0,
          'pendingAmount': 0.0,
        }
      };
    }
  }

  Stream<MpesaTransaction> listenToNewTransactions() {
    // Implement WebSocket connection for real-time updates
    // Return stream of new transactions
    return Stream.empty(); // Placeholder
  }
}
