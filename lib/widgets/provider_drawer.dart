import 'package:flutter/material.dart';
import '../screens/service_provider/jobs_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/finance/financial_management_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/my_service_screen.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';

class ProviderDrawer extends StatelessWidget {
  final String userName;
  final String businessName;
  final String providerId;

  const ProviderDrawer({
    Key? key,
    required this.userName,
    required this.businessName,
    required this.providerId,
  }) : super(key: key);

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close drawer first
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  child: Text(userName[0].toUpperCase()),
                ),
                SizedBox(height: 10),
                Text(
                  userName,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Text(
                  businessName,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.work),
            title: Text('Jobs'),
            onTap: () => _navigateToScreen(
              context,
              JobsScreen(providerId: providerId),
            ),
          ),
          ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text('Calendar'),
            onTap: () => _navigateToScreen(
              context,
              CalendarScreen(),
            ),
          ),
          ListTile(
            leading: Icon(Icons.business),
            title: Text('My Services'),
            onTap: () => _navigateToScreen(
              context,
              MyServiceScreen(),
            ),
          ),
          ListTile(
            leading: Icon(Icons.account_balance_wallet),
            title: Text('Financial Management'),
            onTap: () => _navigateToScreen(
              context,
              FinancialManagementScreen(),
            ),
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () => _navigateToScreen(
              context,
              SettingsScreen(),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
