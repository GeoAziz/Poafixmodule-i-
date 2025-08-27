import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Replace with actual providerId from auth/session
  final String providerId = '689dda4e522262694e34d877';
  Map<String, dynamic>? stats;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      print('Fetching dashboard stats for provider: $providerId');
      final response = await http.get(
        Uri.parse(
          'http://192.168.0.103:5000/api/providers/$providerId/dashboard',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      print('Dashboard stats response status: ${response.statusCode}');
      print('Dashboard stats response body: ${response.body}');
      if (response.statusCode == 200) {
        stats = json.decode(response.body);
        print('Parsed stats: $stats');
      } else {
        error = 'Failed to load stats: ${response.statusCode}';
      }
    } catch (e) {
      error = 'Error fetching stats: $e';
      print(error);
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blueAccent,
        title: Text('Dashboard', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchStats,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/profile.jpg'),
              radius: 20,
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text('Error: $error'))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCard(
                          'Earnings',
                          _formatStat(stats?['earnings'], isCurrency: true),
                          Icons.attach_money,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Jobs Done',
                          _formatStat(stats?['jobsDone']),
                          Icons.work,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Pending',
                          _formatStat(stats?['pendingJobs']),
                          Icons.hourglass_top,
                          Colors.orange,
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Ratings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildStatCard(
                      'Ratings',
                      _formatStat(stats?['ratings'], isRating: true),
                      Icons.star,
                      Colors.amber,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Clients',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildStatCard(
                      'Clients',
                      _formatStat(stats?['clients']),
                      Icons.people,
                      Colors.purple,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Hours',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildStatCard(
                      'Hours',
                      _formatStat(stats?['hours']),
                      Icons.timer,
                      Colors.teal,
                    ),
                    SizedBox(height: 20),
                    // Insights Section (static for now)
                    Text(
                      'Insights',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: LineChart(
                          LineChartData(
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  FlSpot(0, 1),
                                  FlSpot(1, 3),
                                  FlSpot(2, 2),
                                  FlSpot(3, 1.5),
                                  FlSpot(4, 3.5),
                                  FlSpot(5, 2.5),
                                ],
                                isCurved: true,
                                color: Colors.blueAccent,
                                barWidth: 4,
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blueAccent.withOpacity(0.3),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(show: false),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Debug info for diagnostics
                    if (stats != null)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(8),
                        margin: EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Raw Stats: ' + json.encode(stats),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    if (stats == null ||
                        stats!.values.every((v) => v == 0 || v == null))
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'No dashboard data available yet.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {},
        selectedItemColor: Colors.blueAccent,
      ),
    );
  }

  String _formatStat(
    dynamic value, {
    bool isCurrency = false,
    bool isRating = false,
  }) {
    if (value == null) return '-';
    if (isRating) {
      double v = 0;
      try {
        v = value is double ? value : double.parse(value.toString());
      } catch (_) {}
      return v > 0 ? v.toStringAsFixed(2) : 'No ratings';
    }
    if (isCurrency) {
      double v = 0;
      try {
        v = value is double ? value : double.parse(value.toString());
      } catch (_) {}
      return v > 0 ? '[1mKES $v[0m' : 'KES 0';
    }
    if (value is num && value == 0) return '0';
    return value.toString();
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveJobCard(String name, String service, String time) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.person, color: Colors.white),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(service, style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Text(time, style: TextStyle(color: Colors.blueAccent)),
        ],
      ),
    );
  }
}

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: DashboardScreen()),
  );
}
