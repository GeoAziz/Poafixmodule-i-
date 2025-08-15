import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/image_helper.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _backupContactController;
  String? _profileImageBase64;
  String? _selectedCommunication;
  String? _selectedTimezone;
  bool _isLoading = false;

  final List<String> _communicationOptions = ['SMS', 'Email', 'Both'];
  List<String> _timezones = [];

  @override
  void initState() {
    super.initState();
    _initializeTimezones();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _backupContactController =
        TextEditingController(text: widget.user.backupContact);
    _selectedCommunication = widget.user.preferredCommunication ?? 'Both';
    _selectedTimezone = widget.user.timezone ?? 'UTC';
  }

  void _initializeTimezones() {
    tz.initializeTimeZones();
    _timezones = tz.timeZoneDatabase.locations.keys.toList()..sort();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updateData = {
        'name': _nameController.text,
        'phoneNumber': _phoneController.text,
        'backupContact': _backupContactController.text,
        'preferredCommunication': _selectedCommunication,
        'timezone': _selectedTimezone,
        if (_profileImageBase64 != null) 'profilePicture': _profileImageBase64,
      };

      final result = await AuthService.updateProfile(
        widget.user.id,
        updateData,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, result['user']);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        actions: [
          if (_isLoading)
            Center(child: CircularProgressIndicator(color: Colors.white))
          else
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _updateProfile,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildProfileImagePicker(),
              SizedBox(height: 24),
              _buildFormFields(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: widget.user.profilePicUrl != null
                ? NetworkImage(widget.user.profilePicUrl!)
                : null,
            child: widget.user.profilePicUrl == null
                ? Icon(Icons.person, size: 60)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: Icon(Icons.camera_alt, color: Colors.white),
                onPressed: () async {
                  final imageBase64 = await ImageHelper.pickAndProcessImage();
                  if (imageBase64 != null) {
                    setState(() => _profileImageBase64 = imageBase64);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Name is required' : null,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Phone number is required' : null,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _backupContactController,
          decoration: InputDecoration(
            labelText: 'Backup Contact',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedCommunication,
          decoration: InputDecoration(
            labelText: 'Preferred Communication',
            border: OutlineInputBorder(),
          ),
          items: _communicationOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() => _selectedCommunication = newValue);
          },
        ),
        SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedTimezone,
          decoration: InputDecoration(
            labelText: 'Timezone',
            border: OutlineInputBorder(),
          ),
          items: _timezones.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() => _selectedTimezone = newValue);
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _backupContactController.dispose();
    super.dispose();
  }
}
