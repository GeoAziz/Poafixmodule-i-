import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/network_service.dart';
import '../config/api_config.dart';

class NetworkStatusWidget extends StatefulWidget {
  final bool showDetails;
  final VoidCallback? onTap;

  const NetworkStatusWidget({
    super.key,
    this.showDetails = false,
    this.onTap,
  });

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  List<ConnectivityResult>? _connectivity;
  String? _backendUrl;
  bool _isChecking = false;
  final NetworkService _networkService = NetworkService();

  @override
  void initState() {
    super.initState();
    _checkNetworkStatus();
    _listenToConnectivityChanges();
  }

  void _listenToConnectivityChanges() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (mounted) {
        setState(() {
          _connectivity = results;
        });
        if (!results.contains(ConnectivityResult.none)) {
          _checkBackendConnection();
        }
      }
    });
  }

  Future<void> _checkNetworkStatus() async {
    setState(() {
      _isChecking = true;
    });

    try {
      _connectivity = await Connectivity().checkConnectivity();
      if (_connectivity != null && !_connectivity!.contains(ConnectivityResult.none)) {
        await _checkBackendConnection();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _checkBackendConnection() async {
    final url = await _networkService.discoverBackendUrl();
    if (mounted) {
      setState(() {
        _backendUrl = url;
      });
    }
  }

  IconData _getConnectivityIcon() {
    if (_isChecking) return Icons.refresh;
    
    if (_connectivity == null || _connectivity!.contains(ConnectivityResult.none)) {
      return Icons.wifi_off;
    }
    
    if (_connectivity!.contains(ConnectivityResult.wifi)) {
      return Icons.wifi;
    } else if (_connectivity!.contains(ConnectivityResult.mobile)) {
      return Icons.signal_cellular_4_bar;
    } else if (_connectivity!.contains(ConnectivityResult.ethernet)) {
      return Icons.lan;
    }
    
    return Icons.help_outline;
  }

  Color _getStatusColor() {
    if (_isChecking) return Colors.orange;
    if (_connectivity == null || _connectivity!.contains(ConnectivityResult.none)) return Colors.red;
    if (_backendUrl != null) return Colors.green;
    return Colors.orange;
  }

  String _getStatusText() {
    if (_isChecking) return 'Checking...';
    if (_connectivity == null || _connectivity!.contains(ConnectivityResult.none)) return 'No Internet';
    if (_backendUrl != null) return 'Connected';
    return 'Server Unavailable';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showDetails) {
      return GestureDetector(
        onTap: widget.onTap ?? _checkNetworkStatus,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getStatusColor().withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getConnectivityIcon(),
                size: 16,
                color: _getStatusColor(),
              ),
              const SizedBox(width: 6),
              Text(
                _getStatusText(),
                style: TextStyle(
                  color: _getStatusColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getConnectivityIcon(),
                  color: _getStatusColor(),
                ),
                const SizedBox(width: 8),
                Text(
                  'Network Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isChecking)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _checkNetworkStatus,
                    tooltip: 'Refresh network status',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusItem(
              'Internet Connection',
              _connectivity?.toString().split('.').last ?? 'Unknown',
              _connectivity != ConnectivityResult.none,
            ),
            _buildStatusItem(
              'Backend Server',
              _backendUrl ?? 'Not available',
              _backendUrl != null,
            ),
            if (widget.onTap != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.onTap,
                  icon: const Icon(Icons.settings),
                  label: const Text('Network Settings'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, bool isGood) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.check_circle : Icons.error,
            size: 16,
            color: isGood ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isGood ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NetworkDebugScreen extends StatelessWidget {
  const NetworkDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const NetworkStatusWidget(showDetails: true),
            const SizedBox(height: 20),
            FutureBuilder<Map<String, dynamic>>(
              future: ApiConfig.getNetworkStatus(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: ${snapshot.error}'),
                    ),
                  );
                }

                final data = snapshot.data ?? {};
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Network Debug Info',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...data.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text('${entry.key}: ${entry.value}'),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await ApiConfig.refreshConnection();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Network connection refreshed')),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Connection'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
