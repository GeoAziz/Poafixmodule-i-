import 'package:flutter/widgets.dart';
import '../models/user_model.dart';
import 'api_config.dart';

class AppLifecycleHandler extends StatefulWidget {
  final User user;
  final Widget childWidget;
  const AppLifecycleHandler({
    required this.user,
    required this.childWidget,
    Key? key,
  }) : super(key: key);

  @override
  State<AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends State<AppLifecycleHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sendHeartbeat(); // Send on initial open
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sendHeartbeat();
    }
  }

  void _sendHeartbeat() async {
    // Wait until ApiConfig._baseUrl is set before sending heartbeat
    int retries = 0;
    while (ApiConfig.currentBaseUrl == null && retries < 10) {
      print('[AppLifecycleHandler] Waiting for ApiConfig.currentBaseUrl...');
      await Future.delayed(const Duration(milliseconds: 200));
      retries++;
    }
    print(
      '[AppLifecycleHandler] currentBaseUrl after wait: ${ApiConfig.currentBaseUrl}',
    );
    if (ApiConfig.currentBaseUrl == null) {
      debugPrint(
        '❌ ApiConfig.currentBaseUrl is still null after waiting. Heartbeat not sent.',
      );
      return;
    }
    await ApiConfig.updateLastActive(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    return widget.childWidget;
  }
}
