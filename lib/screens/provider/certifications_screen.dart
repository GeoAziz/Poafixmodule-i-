import 'package:flutter/material.dart';
import '../../services/certification_service.dart';

class CertificationsScreen extends StatefulWidget {
  @override
  _CertificationsScreenState createState() => _CertificationsScreenState();
}

class _CertificationsScreenState extends State<CertificationsScreen> {
  final _certificationService = CertificationService();
  List<Map<String, dynamic>> _certifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCertifications();
  }

  Future<String> _getProviderId() async {
    // Example: fetch from secure storage or context
    // Replace with your actual logic
    return Future.value('provider_id');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.hourglass_empty;
    }
  }

  Future<void> _loadCertifications() async {
    setState(() => _isLoading = true);
    try {
      final certs = await _certificationService.getProviderCertifications(
        await _getProviderId(),
      );
      setState(() => _certifications = certs);
    } catch (e) {
      _showError('Failed to load certifications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Certifications')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _certifications.length,
              itemBuilder: (context, index) {
                return _buildCertificationCard(_certifications[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadCertification,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildCertificationCard(Map<String, dynamic> cert) {
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        title: Text(cert['type'] ?? ''),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Number: ${cert['number'] ?? ''}'),
            Text('Expires: ${cert['expiryDate'] ?? ''}'),
            Text('Status: ${cert['verificationStatus'] ?? ''}'),
          ],
        ),
        trailing: Icon(_getStatusIcon(cert['verificationStatus'] ?? '')),
      ),
    );
  }

  Future<void> _uploadCertification() async {
    // Implementation for document upload
  }
}
