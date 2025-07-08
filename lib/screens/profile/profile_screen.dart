import 'package:flutter/material.dart';
import '../../services/auth_storage.dart';
import 'package:image_picker/image_picker.dart'; // Add this import
import 'dart:io';
import '../location/location_picker_screen.dart';
import '../../services/location_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authStorage = AuthStorage();
  final _formKey = GlobalKey<FormState>();
  final _locationService = LocationService(); // Add this line
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  File? _profileImage;
  Map<String, dynamic>? _profileData;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadSavedLocations(); // Add this line
  }

  Future<void> _loadProfileData() async {
    try {
      final credentials = await _authStorage.getCredentials();
      setState(() {
        _profileData = {
          'name': credentials['name'],
          'email': credentials['email'],
          'userType': credentials['userType'],
          'businessName': credentials['business_name'],
          'phoneNumber': credentials['phone_number'],
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final Map<String, dynamic> updates = {
        'name': _profileData!['name'],
        'email': _profileData!['email'],
        'phoneNumber': _profileData!['phoneNumber'],
        'address': _profileData!['address'],
      };

      if (_profileImage != null) {
        // Upload image and get URL
        final imageUrl = await _uploadProfileImage(_profileImage!);
        updates['profileImage'] = imageUrl;
      }

      await _authStorage.updateProfile(updates);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  Future<void> _changePassword() async {
    if (!_validatePasswordForm()) return;

    try {
      await _authStorage.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password changed successfully')),
      );

      // Clear password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change password: $e')),
      );
    }
  }

  bool _validatePasswordForm() {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
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
    final phoneController =
        TextEditingController(text: _profileData?['phoneNumber']);

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
                    final XFile? image =
                        await picker.pickImage(source: ImageSource.gallery);
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
      appBar: AppBar(
        title: Text('Profile'),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileAvatar(), // Add this new section
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
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
            _buildInfoRow('Phone', _profileData?['phoneNumber'] ?? 'Not set'),
            _buildInfoRow('Location', _profileData?['location'] ?? 'Not set'),
            if (_profileData?['userType'] == 'service-provider') ...[
              _buildInfoRow(
                  'Business Name', _profileData?['businessName'] ?? 'Not set'),
              _buildInfoRow(
                  'Service Type', _profileData?['serviceOffered'] ?? 'Not set'),
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
    return Container(
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
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
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
          return Center(
            child: Text('No saved locations yet'),
          );
        }

        return Column(
          children: locations
              .map((location) => ListTile(
                    leading: Icon(Icons.location_on),
                    title: Text(location['name'] ?? ''),
                    subtitle: Text(location['address'] ?? ''),
                    trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _editLocation(location),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  void _addNewLocation() {
    // Show location picker dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Location Name'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Here we'll integrate with Google Places API
                // to allow location selection
                // Navigator.push to a map selection screen
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
              // Save location logic
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editLocation(Map<String, dynamic> location) async {
    final TextEditingController nameController =
        TextEditingController(text: location['name']);
    final TextEditingController addressController =
        TextEditingController(text: location['address']);

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
      final index =
          locations.indexWhere((loc) => loc['name'] == location['name']);
      if (index != -1) {
        locations[index] = {
          ...locations[index],
          ...result,
        };
        await _locationService.saveLocations(locations);
        setState(() {}); // Refresh UI
      }
    }
  }

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _buildActionTile('Edit Profile', Icons.edit, _showEditProfileDialog),
        _buildActionTile(
            'Change Password', Icons.lock, _showChangePasswordDialog),
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
