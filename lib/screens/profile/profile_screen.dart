import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../location/location_picker_screen.dart';
import '../../services/location_service.dart';
// ...existing code...

class ProfileScreen extends StatefulWidget {
  final User user; // Accept user argument

  const ProfileScreen({super.key, required this.user});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationService = LocationService();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  File? _profileImage;
  Map<String, dynamic>? _profileData;
  final Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadSavedLocations(); // Add this line
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Replace with your actual backend URL and token logic
      final token = widget.user.token ?? '';
      final response = await http.get(
        Uri.parse('http://192.168.0.103:5000/api/profile/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _profileData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        print('Error loading profile: ${response.body}');
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final token = widget.user.token ?? '';
      final Map<String, dynamic> updates = {
        'name': _profileData!['name'],
        'email': _profileData!['email'],
        'phoneNumber': _profileData!['phoneNumber'],
        'address': _profileData!['address'],
      };
      if (_profileImage != null) {
        // Upload image and get URL (implement backend upload logic)
        final imageUrl = await _uploadProfileImage(_profileImage!);
        updates['profilePicUrl'] = imageUrl;
      }
      final response = await http.put(
        Uri.parse('http://192.168.0.103:5000/api/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updates),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
        await _loadProfileData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _changePassword() async {
    if (!_validatePasswordForm()) return;
    setState(() => _isLoading = true);
    try {
      final token = widget.user.token ?? '';
      final response = await http.post(
        Uri.parse('http://192.168.0.103:5000/api/auth/password-reset/request'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'currentPassword': _currentPasswordController.text,
          'newPassword': _newPasswordController.text,
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password changed successfully')),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change password: ${response.body}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to change password: $e')));
    }
    setState(() => _isLoading = false);
  }

  bool _validatePasswordForm() {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Passwords do not match')));
      return false;
    }

    // Check password strength
    final password = _newPasswordController.text;
    if (password.length < 8 ||
        !password.contains(RegExp(r'[A-Z]')) ||
        !password.contains(RegExp(r'[a-z]')) ||
        !password.contains(RegExp(r'[0-9]'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password must be at least 8 characters long and contain uppercase, lowercase, and numbers',
          ),
        ),
      );
      return false;
    }

    return true;
  }

  Future<String> _uploadProfileImage(File image) async {
    // TODO: Implement image upload logic here
    // This should upload the image to your storage service and return the URL
    return 'https://example.com/placeholder-image.jpg';
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _profileData?['name']);
    final emailController = TextEditingController(text: _profileData?['email']);
    final phoneController = TextEditingController(
      text: _profileData?['phoneNumber'],
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Name is required' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Email is required' : null,
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'Phone'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Phone is required' : null,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      setState(() {
                        _profileImage = File(image.path);
                      });
                    }
                  },
                  child: Text('Change Profile Picture'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                setState(() {
                  _profileData!['name'] = nameController.text;
                  _profileData!['email'] = emailController.text;
                  _profileData!['phoneNumber'] = phoneController.text;
                });
                await _updateProfile();
                Navigator.pop(context);
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Current Password'),
              ),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'New Password'),
              ),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Confirm New Password'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _changePassword();
              Navigator.pop(context);
            },
            child: Text('Change'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile'), automaticallyImplyLeading: true),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileAvatar(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoSection(),
                        const SizedBox(height: 24),
                        _buildStatsSection(),
                        const SizedBox(height: 24),
                        _buildLocationSection(),
                        const SizedBox(height: 24),
                        _buildActionsSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              (_profileData?['name'] ?? 'U')[0].toUpperCase(),
              style: TextStyle(
                fontSize: 40,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            _profileData?['name'] ?? 'User',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            _profileData?['email'] ?? '',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    String phone = '';
    String location = '';
    String businessName = '';
    String serviceType = '';
    try {
      if (_profileData != null) {
        final pd = _profileData!;
        phone = pd['phoneNumber'] is String
            ? pd['phoneNumber']
            : (pd['phoneNumber'] != null ? pd['phoneNumber'].toString() : '');
        if (pd['location'] is String) {
          location = pd['location'];
        } else if (pd['location'] is Map) {
          location = pd['location']['address'] ?? '';
        } else if (pd['location'] != null) {
          location = pd['location'].toString();
        }
        businessName = pd['businessName'] is String
            ? pd['businessName']
            : (pd['businessName'] != null ? pd['businessName'].toString() : '');
        serviceType = pd['serviceOffered'] is String
            ? pd['serviceOffered']
            : (pd['serviceOffered'] != null
                  ? pd['serviceOffered'].toString()
                  : '');
      }
    } catch (e) {
      // fallback to empty strings
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Phone', phone.isNotEmpty ? phone : 'Not set'),
            _buildInfoRow(
              'Location',
              location.isNotEmpty ? location : 'Not set',
            ),
            if (_profileData?['userType'] == 'service-provider') ...[
              _buildInfoRow(
                'Business Name',
                businessName.isNotEmpty ? businessName : 'Not set',
              ),
              _buildInfoRow(
                'Service Type',
                serviceType.isNotEmpty ? serviceType : 'Not set',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatCard('Total Bookings', '${_stats['totalBookings'] ?? 0}'),
          _buildStatCard('Active', '${_stats['activeBookings'] ?? 0}'),
          _buildStatCard('Saved Places', '${_stats['savedLocations'] ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Card(
      child: Container(
        width: 120,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved Locations',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: Icon(Icons.add_location_alt),
                  onPressed: _addNewLocation,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSavedLocations(),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedLocations() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _locationService.getSavedLocations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error loading locations: ${snapshot.error}');
        }

        final locations = snapshot.data ?? [];

        if (locations.isEmpty) {
          return Center(child: Text('No saved locations yet'));
        }

        return Column(
          children: locations
              .map(
                (location) => ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text(location['name'] ?? ''),
                  subtitle: Text(location['address'] ?? ''),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _editLocation(location),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  void _addNewLocation() {
    final locationNameController = TextEditingController();
    final addressController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: locationNameController,
              decoration: InputDecoration(labelText: 'Location Name'),
            ),
            TextField(
              controller: addressController,
              decoration: InputDecoration(labelText: 'Address'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Integrate with map picker if needed
              },
              child: Text('Pick Location on Map'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final token = widget.user.token ?? '';
              final response = await http.post(
                Uri.parse('http://192.168.0.103:5000/api/location/update'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: json.encode({
                  'name': locationNameController.text,
                  'address': addressController.text,
                }),
              );
              if (response.statusCode == 200) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Location saved successfully')),
                );
                await _loadSavedLocations();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to save location: ${response.body}'),
                  ),
                );
              }
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editLocation(Map<String, dynamic> location) async {
    final TextEditingController nameController = TextEditingController(
      text: location['name'],
    );
    final TextEditingController addressController = TextEditingController(
      text: location['address'],
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${location['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Location Name'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationPickerScreen(
                      locationName: nameController.text,
                      initialLocation:
                          null, // You can pass current coordinates if available
                    ),
                  ),
                );
                if (result != null) {
                  Navigator.pop(context, {
                    ...result,
                    'name': nameController.text,
                  });
                }
              },
              child: Text('Pick Location on Map'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'name': nameController.text,
                'address': addressController.text,
              });
            },
            child: Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      // Update the location in storage and state
      final locations = await _locationService.getSavedLocations();
      final index = locations.indexWhere(
        (loc) => loc['name'] == location['name'],
      );
      if (index != -1) {
        locations[index] = {...locations[index], ...result};
        await _locationService.saveLocations(locations);
        setState(() {}); // Refresh UI
      }
    }
  }

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildActionTile('Edit Profile', Icons.edit, _showEditProfileDialog),
        _buildActionTile(
          'Change Password',
          Icons.lock,
          _showChangePasswordDialog,
        ),
        _buildActionTile('Notifications', Icons.notifications, () {
          // TODO: Implement notifications settings
        }),
      ],
    );
  }

  Widget _buildActionTile(String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(label),
      trailing: Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  // Add this method
  Future<void> _loadSavedLocations() async {
    try {
      final locations = await _locationService.getSavedLocations();
      setState(() {
        _stats['savedLocations'] = locations.length;
      });
    } catch (e) {
      print('Error loading saved locations: $e');
    }
  }
}
