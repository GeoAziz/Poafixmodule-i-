import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/mpesa_transaction.dart';
import '../../services/financial_service.dart';
import '../../widgets/transaction_card.dart';
import '../../widgets/earnings_chart.dart';
import '../../widgets/no_records_view.dart';

class FinancialManagementScreen extends StatefulWidget {
  @override
  _FinancialManagementScreenState createState() =>
      _FinancialManagementScreenState();
}

class _FinancialManagementScreenState extends State<FinancialManagementScreen>
    with SingleTickerProviderStateMixin {
  final FinancialService _financialService = FinancialService();
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  late TabController _tabController;
  List<MpesaTransaction> _transactions = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;

  double _totalEarnings = 0;
  double _weeklyEarnings = 0;
  double _pendingAmount = 0;
  List<double> _weeklyData = List.filled(7, 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (await _verifyCredentials()) {
      _loadData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please log in to view financial data'),
            action: SnackBarAction(
              label: 'Login',
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ),
        );
      }
    }
  }

  Future<bool> _verifyCredentials() async {
    try {
  final token = await _storage.read(key: 'auth_token');
      final userId =
          await _storage.read(key: 'id'); // Changed from 'userId' to 'id'
      final userType = await _storage.read(key: 'userType');

      print('Raw credentials from storage:');
      print('Token: $token');
      print('UserID: $userId');
      print('UserType: $userType');

      if (token == null || userType != 'service-provider') {
        return false;
      }

      // Update the financial service with the token
      _financialService.updateToken(token);
      return true;
    } catch (e) {
      print('Error reading credentials: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (!await _verifyCredentials()) {
        throw Exception('Not authenticated');
      }

      final transactions = await _financialService.getTransactions();
      final summary = await _financialService.getEarningsSummary();

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _summary = summary;
          _totalEarnings =
              ((summary['data'] ?? {})['totalEarnings'] ?? 0).toDouble();
          _weeklyEarnings =
              ((summary['data'] ?? {})['weeklyEarnings'] ?? 0).toDouble();
          _pendingAmount =
              ((summary['data'] ?? {})['pendingAmount'] ?? 0).toDouble();
          _weeklyData = _calculateWeeklyData(transactions);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        if (e.toString().contains('Not authenticated')) {
          // Clear stored credentials as they might be invalid
          await _storage.deleteAll();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Session expired. Please log in again'),
              action: SnackBarAction(
                label: 'Login',
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading financial data')),
          );
        }
      }
    }
  }

  List<double> _calculateWeeklyData(List<MpesaTransaction> transactions) {
    final List<double> data = List.filled(7, 0);
    final now = DateTime.now();

    for (var transaction in transactions) {
      final difference = now.difference(transaction.timestamp).inDays;
      if (difference < 7) {
        data[difference] += transaction.amount;
      }
    }

    return data.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Financial Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Transactions'),
            Tab(text: 'M-PESA'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTransactionsTab(),
          _buildMpesaTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEarningsSummary(),
            SizedBox(height: 20),
            _buildEarningsChart(),
            SizedBox(height: 20),
            _buildQuickStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/no_transactions.png', height: 200),
            SizedBox(height: 20),
            Text(
              'No Transactions Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Your transactions will appear here',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          return TransactionCard(
            amount: transaction.amount.toString(),
            date: transaction.timestamp.toString(),
            clientName: transaction.clientName,
            serviceType: transaction.serviceType,
            status: transaction.status,
            mpesaReference: transaction.mpesaReference,
          );
        },
      ),
    );
  }

  Widget _buildMpesaTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'M-PESA Details',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text('Connected Number: +254 712 345 678'),
                  Text('Account Status: Active'),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          _buildMpesaTransactionsList(),
        ],
      ),
    );
  }

  Widget _buildEarningsSummary() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Earnings',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            Text(
              'KES ${_totalEarnings.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildEarningItem(
                    'This Week', 'KES ${_weeklyEarnings.toStringAsFixed(2)}'),
                _buildEarningItem(
                    'Pending', 'KES ${_pendingAmount.toStringAsFixed(2)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningItem(String label, String amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.grey)),
        Text(amount, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMpesaTransactionsList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_transactions.isEmpty) {
      return NoRecordsView(
        message: 'No M-PESA Transactions',
        submessage:
            'Your M-PESA transactions will appear here once payments are made',
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          child: ListTile(
            title: Text(
              'Payment from ${transaction.clientName}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              DateFormat('dd MMM yyyy, hh:mm a').format(transaction.timestamp),
              style: GoogleFonts.poppins(),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'KES ${transaction.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  transaction.mpesaReference,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEarningsChart() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return EarningsChart(
      weeklyData: _weeklyData,
      maxY: _weeklyData.reduce((a, b) => a > b ? a : b) * 1.2,
    );
  }

  Widget _buildQuickStats() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    final completedTransactions =
        _transactions.where((t) => t.status == 'completed').length;
    final totalTransactions = _transactions.length;
    final completionRate = totalTransactions > 0
        ? (completedTransactions / totalTransactions * 100).toStringAsFixed(1)
        : '0';

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      physics: NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          'Total Jobs',
          totalTransactions.toString(),
          Icons.work,
          Colors.blue,
        ),
        _buildStatCard(
          'This Month',
          'KES ${_totalEarnings.toStringAsFixed(0)}',
          Icons.calendar_today,
          Colors.green,
        ),
        _buildStatCard(
          'Pending Jobs',
          (_transactions.where((t) => t.status == 'pending').length).toString(),
          Icons.pending,
          Colors.orange,
        ),
        _buildStatCard(
          'Completion Rate',
          '$completionRate%',
          Icons.check_circle,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
