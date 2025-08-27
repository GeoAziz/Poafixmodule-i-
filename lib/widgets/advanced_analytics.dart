import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/analytics_service.dart';
import '../services/dynamic_pricing_service.dart';
import 'glass_container.dart';

class AdvancedAnalytics extends StatefulWidget {
  final String providerId;

  const AdvancedAnalytics({super.key, required this.providerId});

  @override
  _AdvancedAnalyticsState createState() => _AdvancedAnalyticsState();
}

class _AdvancedAnalyticsState extends State<AdvancedAnalytics> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final DynamicPricingService _pricingService = DynamicPricingService();

  Map<String, dynamic> _analyticsData = {};
  Map<String, dynamic> _performanceMetrics = {};
  Map<String, dynamic> _bookingAnalytics = {};
  Map<String, dynamic> _pricingMetrics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _analyticsService.getProviderAnalytics(widget.providerId),
        _analyticsService.getPerformanceMetrics(widget.providerId),
        _analyticsService.getBookingAnalytics(widget.providerId),
        _analyticsService.getDynamicPricingMetrics(widget.providerId),
      ]);

      if (mounted) {
        setState(() {
          _analyticsData = futures[0];
          _performanceMetrics = futures[1];
          _bookingAnalytics = futures[2];
          _pricingMetrics = futures[3];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading analytics data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildPerformanceMetrics(),
                  _buildBookingTrends(),
                  _buildPricingAnalytics(),
                  _buildServiceAreaInsights(),
                ],
              ),
            ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Metrics',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricCard(
                'Response Rate',
                '${(_performanceMetrics['responseRate'] ?? 0).toStringAsFixed(1)}%',
                Icons.speed,
                Colors.blue,
              ),
              _buildMetricCard(
                'Completion Rate',
                '${(_performanceMetrics['completionRate'] ?? 0).toStringAsFixed(1)}%',
                Icons.check_circle,
                Colors.green,
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricCard(
                'On-Time Rate',
                '${(_performanceMetrics['onTimeRate'] ?? 0).toStringAsFixed(1)}%',
                Icons.timer,
                Colors.orange,
              ),
              _buildMetricCard(
                'Satisfaction',
                '${(_performanceMetrics['customerSatisfaction'] ?? 0).toStringAsFixed(1)}%',
                Icons.sentiment_satisfied_alt,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingTrends() {
    final trends = _bookingAnalytics['bookingTrends'] ?? [];

    return Card(
      margin: EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Trends',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: trends.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          (entry.value['count'] ?? 0).toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingAnalytics() {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dynamic Pricing',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPriceMetric(
                  'Base Rate',
                  'KES ${_pricingMetrics['baseRate'] ?? 0}',
                  Icons.attach_money,
                ),
                _buildPriceMetric(
                  'Current Multiplier',
                  '${(_pricingMetrics['demandMultiplier'] ?? 1.0).toStringAsFixed(2)}x',
                  Icons.trending_up,
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Price History',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: (_pricingMetrics['priceHistory'] ?? []).length,
                itemBuilder: (context, index) {
                  final historyItem = _pricingMetrics['priceHistory'][index];
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'KES ${historyItem['price']}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            timeago.format(DateTime.parse(historyItem['date'])),
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceAreaInsights() {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Area Insights',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.location_on,
                color: Theme.of(context).primaryColor,
              ),
              title: Text('Most Popular Areas'),
              subtitle: Text(
                (_analyticsData['popularLocations'] ?? []).take(3).join(', '),
              ),
            ),
            ListTile(
              leading: Icon(Icons.map, color: Theme.of(context).primaryColor),
              title: Text('Coverage Area'),
              subtitle: Text('${_analyticsData['coverage'] ?? 0} km²'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        width: MediaQuery.of(context).size.width * 0.4,
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceMetric(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
