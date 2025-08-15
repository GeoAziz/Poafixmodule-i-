import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/api_config.dart';
import '../../services/websocket_service.dart';

class FinancialManagementScreen extends StatefulWidget {
  const FinancialManagementScreen({super.key});

  @override
  _FinancialManagementScreenState createState() =>
      _FinancialManagementScreenState();
}

class _FinancialManagementScreenState extends State<FinancialManagementScreen> {
  final _storage = const FlutterSecureStorage();
  final _webSocketService = WebSocketService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic> _summary = {};
  String? _error;
  DateTimeRange? _selectedDateRange;
  String _selectedFilter = 'all'; // all, completed, pending

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupWebSocketListener();
  }

  Future<void> _loadData() async {
    try {
  final token = await _storage.read(key: 'auth_token');
      final userId = await _storage.read(key: 'userId');

      if (token == null) {
        print('No token found, attempting to decode from storage...');
        throw Exception('Authentication token missing');
      }

      // Get ID directly from stored userId
      if (userId == null) {
        print('No userId found, attempting to extract from token...');
        final parts = token.split('.');
        if (parts.length != 3) throw Exception('Invalid token format');

        final payload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        );

        final tokenUserId = payload['id'];
        if (tokenUserId == null) throw Exception('No user ID in token');

        // Store userId for future use
        await _storage.write(key: 'userId', value: tokenUserId);

        print('Extracted and stored userId: $tokenUserId');
      }

      final effectiveUserId = userId ??
          json.decode(utf8.decode(base64Url
              .decode(base64Url.normalize(token.split('.')[1]))))['id'];

      print('Loading financial data with userId: $effectiveUserId');

      await Future.wait([
        _loadTransactions(token, effectiveUserId),
        _loadSummary(token, effectiveUserId),
      ]);
    } catch (e) {
      print('Error loading financial data: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTransactions(String token, String userId) async {
    try {
      final queryParams = <String, String>{
        'providerId': userId,
        if (_selectedDateRange != null) ...{
          'startDate': _selectedDateRange!.start.toIso8601String(),
          'endDate': _selectedDateRange!.end.toIso8601String(),
        },
        if (_selectedFilter != 'all') 'status': _selectedFilter,
      };

      final url = Uri.parse('${ApiConfig.baseUrl}/api/transactions').replace(
        queryParameters: queryParams,
      );

      print('Fetching transactions from: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Provider-ID': userId,
          'User-Type': 'service-provider',
        },
      );

      print('Transaction response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _transactions = List<Map<String, dynamic>>.from(data['data'] ?? [])
            ..sort((a, b) => DateTime.parse(b['timestamp'] ?? b['createdAt'])
                .compareTo(DateTime.parse(a['timestamp'] ?? a['createdAt'])));
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch transactions: ${response.body}');
      }
    } catch (e) {
      print('Error loading transactions: $e');
      rethrow;
    }
  }

  Future<void> _loadSummary(String token, String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/transactions/summary'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Provider-ID': userId,
          'User-Type': 'service-provider',
        },
      );

      print('Summary response: ${response.statusCode}');
      print('Summary body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _summary = data['data'] ??
              {
                'totalEarnings': 0.0,
                'pendingAmount': 0.0,
                'todayEarnings': 0.0,
              };
        });
      } else {
        throw Exception('Failed to fetch summary: ${response.body}');
      }
    } catch (e) {
      print('Error loading summary: $e');
      rethrow;
    }
  }

  void _setupWebSocketListener() {
    _webSocketService.socket.on('transaction_updated', (data) async {
      await _loadData();
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(Duration(days: 30)),
            end: DateTime.now(),
          ),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _loadData();
    }
  }

  @override
  void dispose() {
    _webSocketService.socket.off('transaction_updated');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Financial Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedFilter = value);
              _loadData();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'all', child: Text('All Transactions')),
              PopupMenuItem(value: 'completed', child: Text('Completed')),
              PopupMenuItem(value: 'pending', child: Text('Pending')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_selectedDateRange != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Chip(
                  label: Text(
                    '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}',
                  ),
                  onDeleted: () {
                    setState(() => _selectedDateRange = null);
                    _loadData();
                  },
                ),
              ),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                children: [
                  _buildSummaryCard(
                    'Total Earnings',
                    'KES ${_formatAmount(_summary['totalEarnings'] ?? 0)}',
                    Colors.green,
                    Icons.monetization_on,
                  ),
                  _buildSummaryCard(
                    'Pending',
                    'KES ${_formatAmount(_summary['pendingAmount'] ?? 0)}',
                    Colors.orange,
                    Icons.pending,
                  ),
                  _buildSummaryCard(
                    'Today',
                    'KES ${_formatAmount(_summary['todayEarnings'] ?? 0)}',
                    Colors.blue,
                    Icons.today,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Error: $_error',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.red),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadData,
                                  child: Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _buildTransactionsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.all(8),
        children: [
          _buildSummaryCard(
            'Total Earnings',
            'KES ${_formatAmount(_summary['totalEarnings'] ?? 0)}',
            Colors.green,
            Icons.monetization_on,
          ),
          _buildSummaryCard(
            'Pending',
            'KES ${_formatAmount(_summary['pendingAmount'] ?? 0)}',
            Colors.orange,
            Icons.pending,
          ),
          _buildSummaryCard(
            'Today',
            'KES ${_formatAmount(_summary['todayEarnings'] ?? 0)}',
            Colors.blue,
            Icons.today,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String amount, Color color, IconData icon) {
    return Card(
      color: color.withOpacity(0.1),
      child: Container(
        width: 160,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        color: color.withOpacity(0.8),
                        fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    return amount.toStringAsFixed(2);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return Center(
        child: Text('No transactions found'),
      );
    }

    return ListView.builder(
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        final amount = transaction['amount'] ?? 0.0;
        final status = transaction['status'] ?? 'pending';
        final date = DateTime.parse(
            transaction['timestamp'] ?? transaction['createdAt']);

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Icon(
              status == 'completed' ? Icons.check_circle : Icons.pending,
              color: status == 'completed' ? Colors.green : Colors.orange,
            ),
            title: Text(
              transaction['description'] ??
                  'Payment from ${transaction['clientName'] ?? 'Client'}',
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ref: ${transaction['mpesaReference'] ?? 'N/A'}'),
                Text(
                  'Date: ${_formatDateTime(date)}',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            trailing: Text(
              'KES ${_formatAmount(amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: status == 'completed' ? Colors.green : Colors.orange,
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}
