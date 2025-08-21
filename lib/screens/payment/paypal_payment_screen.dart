import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';

class PaypalPaymentScreen extends StatefulWidget {
  final String approvalUrl;
  final String bookingId;
  final double amount;
  final String paymentId;

  const PaypalPaymentScreen({
    Key? key,
    required this.approvalUrl,
    required this.bookingId,
    required this.amount,
    required this.paymentId,
  }) : super(key: key);

  @override
  State<PaypalPaymentScreen> createState() => _PaypalPaymentScreenState();
}

class _PaypalPaymentScreenState extends State<PaypalPaymentScreen> {
  late final WebViewController _controller;
  // Removed polling timer
  bool _isLoading = true;
  bool _isSuccess = false;

  // Helper to check PayPal success URL
  bool _isPayPalSuccessUrl(String url) {
    return url.contains('/paypal/success');
  }

  // Helper to check PayPal cancel URL
  bool _isPayPalCancelUrl(String url) {
    return url.contains('/paypal/cancel');
  }

  @override
  void initState() {
    super.initState();
    print('[PayPal] Initializing WebView with URL: ${widget.approvalUrl}');
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('[PayPal] Page started loading: $url');
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            print('[PayPal] Page finished loading: $url');
            setState(() => _isLoading = false);
            // Check for success page
            if (_isSuccess) return;
            if (_isPayPalSuccessUrl(url)) {
              final uri = Uri.parse(url);
              final token = uri.queryParameters['token'];
              final payerId = uri.queryParameters['PayerID'];
              print(
                '[PayPal] Success URL params - token: $token, PayerID: $payerId',
              );
              if (token != null && payerId != null) {
                _handlePaymentCompletion(token, payerId);
              }
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            print('[PayPal] Navigation request to: ${request.url}');
            // Always intercept PayPal success/cancel URLs and load them in WebView
            if (_isPayPalSuccessUrl(request.url)) {
              return NavigationDecision.navigate;
            }
            if (_isPayPalCancelUrl(request.url)) {
              Navigator.of(context).pop(false);
              return NavigationDecision.prevent;
            }
            // Prevent external browser for custom schemes
            if (request.url.startsWith('poafix://')) {
              final uri = Uri.parse(request.url);
              if (uri.path == '/payment/success') {
                final token = uri.queryParameters['token'];
                final payerId = uri.queryParameters['PayerID'];
                if (token != null && payerId != null) {
                  _handlePaymentCompletion(token, payerId);
                }
                return NavigationDecision.prevent;
              }
              return NavigationDecision.prevent;
            }
            // Default: allow navigation in WebView
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'PaymentChannel',
        onMessageReceived: (message) async {
          print('[PayPal] Received message from JS: ${message.message}');
          if (!_isSuccess) {
            try {
              final data = jsonDecode(message.message);
              if (data['token'] != null && data['PayerID'] != null) {
                _handlePaymentCompletion(data['token'], data['PayerID']);
              } else {
                print(
                  '[PayPal] Invalid message data received: ${message.message}',
                );
              }
            } catch (e) {
              print('[PayPal] Error processing JS message: $e');
            }
          }
        },
      )
      ..loadRequest(Uri.parse(widget.approvalUrl));
  }

  Future<void> _handlePaymentCompletion(String token, String payerId) async {
    if (_isSuccess) return; // Prevent multiple executions
    _isSuccess = true;
    try {
      print(
        '[PayPal] Handling payment completion: token=$token, payerId=$payerId',
      );
      if (!mounted) return;
      // Notify backend
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/payments/paypal/complete'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token,
          'PayerID': payerId,
          'bookingId': widget.bookingId,
          'paymentId': widget.paymentId,
          'amount': widget.amount,
        }),
      );
      print(
        '[PayPal] Backend response: ${response.statusCode} ${response.body}',
      );
      // Immediately close WebView and navigate to notifications screen for smooth UX
      if (!mounted) return;
      Navigator.of(context).pop(); // Close WebView
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/notifications', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment completed successfully!')),
      );
    } catch (e) {
      print('[PayPal] Error in payment completion: $e');
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error completing payment: $e')));
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/notifications', (route) => false);
    }
  }

  @override
  void dispose() {
    // Removed polling timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSuccess) return true;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Cancel Payment?'),
            content: Text('Are you sure you want to cancel this payment?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Yes'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('PayPal Payment'),
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () async {
              if (_isSuccess) {
                Navigator.of(context).pop();
                return;
              }
              final shouldClose = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Cancel Payment?'),
                  content: Text(
                    'Are you sure you want to cancel this payment?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Yes'),
                    ),
                  ],
                ),
              );
              if (shouldClose == true) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: Colors.white.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading...'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
