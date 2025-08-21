import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../screens/notifications/notification_screen.dart' as notification;
import '../screens/follow_us_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/billing_history_screen.dart';
import '../screens/payment_methods_screen.dart';
import '../screens/refer_a_friend_screen.dart';
import '../screens/bookings/bookings_screen.dart';
import '../screens/auth/login_screen.dart';

class ClientSidePanel extends StatelessWidget {
  final User user;
  final BuildContext parentContext;

  const ClientSidePanel({
    Key? key,
    required this.user,
    required this.parentContext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user.name),
            accountEmail: Text(user.email),
            currentAccountPicture: CircleAvatar(child: Icon(Icons.person)),
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
            onTap: () {
              Navigator.push(
                parentContext,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(user: user),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            onTap: () {
              Navigator.push(
                parentContext,
                MaterialPageRoute(
                  builder: (context) =>
                      notification.NotificationsScreen(user: user),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('Bookings'),
            onTap: () {
              Navigator.push(
                parentContext,
                MaterialPageRoute(
                  builder: (context) => BookingsScreen(user: user),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.payment),
            title: Text('Payment Methods'),
            onTap: () {
              Navigator.push(
                parentContext,
                MaterialPageRoute(builder: (context) => PaymentMethodsScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.receipt_long),
            title: Text('Billing History'),
            onTap: () {
              Navigator.push(
                parentContext,
                MaterialPageRoute(builder: (context) => BillingHistoryScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.group_add),
            title: Text('Refer a Friend'),
            onTap: () {
              Navigator.push(
                parentContext,
                MaterialPageRoute(builder: (context) => ReferAFriendScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.follow_the_signs),
            title: Text('Follow Us'),
            onTap: () {
              Navigator.push(
                parentContext,
                MaterialPageRoute(builder: (context) => FollowUsScreen()),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () {
              Navigator.of(parentContext).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
          ListTile(title: Text('App Version: 1.0.0'), onTap: () {}),
        ],
      ),
    );
  }
}
