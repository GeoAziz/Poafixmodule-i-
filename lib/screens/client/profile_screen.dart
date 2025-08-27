import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animations/animations.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../screens/client/edit_profile_screen.dart';
import '../../services/user_status_service.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  _ClientProfileScreenState createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Future<User?> _userFuture;
  late Future<Map<String, dynamic>?> _statusFuture;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _userFuture = AuthService.getCurrentUser();
    _controller.forward();
    _userFuture.then((user) {
      if (user != null) {
        setState(() {
          _statusFuture = UserStatusService.fetchUserStatus(user.id);
        });
      }
    });
  }

  Future<void> _handleEditProfile(User user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(user: user)),
    );

    if (result != null) {
      setState(() {
        _userFuture = AuthService.getCurrentUser();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Profile'), elevation: 0),
      body: FutureBuilder<User?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading profile: ${snapshot.error}'),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return Center(child: Text('No user data available'));
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildProfileHeader(user),
                SizedBox(height: 16),
                FutureBuilder<Map<String, dynamic>?>(
                  future: _statusFuture,
                  builder: (context, statusSnapshot) {
                    if (statusSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final status = statusSnapshot.data;
                    if (status == null) {
                      return Text('Status unavailable');
                    }
                    String statusText = status['isOnline'] == true
                        ? 'Online'
                        : 'Offline';
                    String lastActiveText = status['lastActive'] != null
                        ? 'Last active: ' +
                              DateTime.parse(
                                status['lastActive'],
                              ).toLocal().toString()
                        : 'Last active: Unknown';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              status['isOnline'] == true
                                  ? Icons.circle
                                  : Icons.circle_outlined,
                              color: status['isOnline'] == true
                                  ? Colors.green
                                  : Colors.grey,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              statusText,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          lastActiveText,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 24),
                _buildInfoSection(user),
                SizedBox(height: 24),
                _buildPreferencesSection(user),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return OpenContainer(
      transitionType: ContainerTransitionType.fade,
      openBuilder: (context, _) =>
          _FullScreenImage(imageUrl: user.profilePicUrl),
      closedBuilder: (context, openContainer) => Stack(
        children: [
          GestureDetector(
            onTap: openContainer,
            child: Hero(
              tag: 'profile-image',
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage: user.profilePicUrl != null
                    ? CachedNetworkImageProvider(user.profilePicUrl!)
                    : null,
                child: user.profilePicUrl == null
                    ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                    : null,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: FloatingActionButton.small(
              onPressed: () => _handleEditProfile(user),
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(Icons.edit),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(User user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Divider(),
            _buildInfoItem(Icons.person, 'Name', user.name),
            _buildInfoItem(Icons.email, 'Email', user.email),
            _buildInfoItem(Icons.phone, 'Phone', user.phoneNumber ?? 'Not set'),
            _buildInfoItem(
              Icons.access_time,
              'Member Since',
              user.createdAt?.toString().split(' ')[0] ?? 'Unknown',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(User user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preferences', style: Theme.of(context).textTheme.titleLarge),
            Divider(),
            _buildInfoItem(
              Icons.notifications,
              'Communication',
              user.preferredCommunication ?? 'Not set',
            ),
            _buildInfoItem(
              Icons.phone_android,
              'Backup Contact',
              user.backupContact ?? 'Not set',
            ),
            _buildInfoItem(
              Icons.schedule,
              'Timezone',
              user.timezone ?? 'Not set',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600])),
              Text(value, style: TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _FullScreenImage extends StatelessWidget {
  final String? imageUrl;

  const _FullScreenImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(
        child: Hero(
          tag: 'profile-image',
          child: imageUrl != null
              ? CachedNetworkImage(imageUrl: imageUrl!)
              : Icon(Icons.person, size: 200, color: Colors.grey[400]),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
