import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RecaptchaPage extends StatefulWidget {
  final String siteKey;
  final Function(String) onVerified;

  const RecaptchaPage({
    Key? key,
    required this.siteKey,
    required this.onVerified,
  }) : super(key: key);

  @override
  State<RecaptchaPage> createState() => _RecaptchaPageState();
}

class _RecaptchaPageState extends State<RecaptchaPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadHtmlString('''
        <html>
          <head>
            <script src="https://www.google.com/recaptcha/api.js" async defer></script>
          </head>
          <body>
            <div style="display: flex; justify-content: center; align-items: center; height: 100vh;">
              <div class="g-recaptcha" 
                data-sitekey="${widget.siteKey}"
                data-callback="onVerified">
              </div>
            </div>
            <script>
              function onVerified(token) {
                window.flutter_inappwebview.callHandler('onVerified', token);
              }
            </script>
          </body>
        </html>
      ''')
      ..addJavaScriptChannel(
        'Recaptcha',
        onMessageReceived: (JavaScriptMessage message) {
          widget.onVerified(message.message);
          Navigator.pop(context);
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify you are human'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
