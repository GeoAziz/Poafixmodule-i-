import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/service_request.service.dart';
import '../../models/service_request.dart';

class ServiceHistoryScreen extends StatefulWidget {
  const ServiceHistoryScreen({Key? key}) : super(key: key);

  @override
  _ServiceHistoryScreenState createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  final _serviceRequestService = ServiceRequestService();
  List<ServiceRequest> _requests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  // TODO: Replace this with the actual client identifier as required in your app
  final String clientId = 'your_client_id_here';

  Future<void> _loadRequests() async {
    try {
      setState(() => _isLoading = true);
      // Replace 'clientId' with the actual client identifier as required
      final requests = await _serviceRequestService.getClientRequests(clientId);
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildRequestCard(ServiceRequest request) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(request.serviceType),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('MMM d, y').format(request.scheduledDate)),
            Text('Status: ${request.status.toUpperCase()}'),
            if (request.rejectionReason != null)
              Text('Reason: ${request.rejectionReason}',
                  style: TextStyle(color: Colors.red)),
          ],
        ),
        trailing: Text('\$${request.amount.toStringAsFixed(2)}'),
        onTap: () => _showRequestDetails(request),
      ),
    );
  }

  void _showRequestDetails(ServiceRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Service Request Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Service', request.serviceType),
              _buildDetailRow('Status', request.status.toUpperCase()),
              _buildDetailRow(
                  'Date', DateFormat('MMM d, y').format(request.scheduledDate)),
              _buildDetailRow(
                  'Amount', '\$${request.amount.toStringAsFixed(2)}'),
              if (request.notes?.isNotEmpty ?? false)
                _buildDetailRow('Notes', request.notes!),
              if (request.rejectionReason != null)
                _buildDetailRow('Rejection Reason', request.rejectionReason!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Service History'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      ElevatedButton(
                        onPressed: _loadRequests,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _requests.isEmpty
                  ? Center(child: Text('No service history yet'))
                  : ListView.builder(
                      itemCount: _requests.length,
                      itemBuilder: (context, index) =>
                          _buildRequestCard(_requests[index]),
                    ),
    );
  }
}
