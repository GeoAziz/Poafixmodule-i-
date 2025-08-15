import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_count_provider.dart';

class AppRoot extends StatelessWidget {
  final Widget child;
  const AppRoot({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationCountProvider(),
      child: child,
    );
  }
}
