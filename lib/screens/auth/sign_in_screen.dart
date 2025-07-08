import 'dart:convert';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:poafix/screens/service_provider/service_provider_screen.dart'
    as provider;
import 'package:poafix/screens/home/home_screen.dart';
import 'package:poafix/services/auth_service.dart';
import '../../constants/service_types.dart';
import '../../models/user_model.dart'; // Update import
import '../../services/image_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool isServiceProvider = false; // Changed from isClient for clarity
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final AuthService authService = AuthService();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final businessNameController = TextEditingController();
  final businessAddressController = TextEditingController();
  final serviceOfferedController = TextEditingController();
  late TextEditingController _backupContactController;
  String? _selectedCommunication;
  String? _selectedTimezone;

  bool _passwordVisible = false;

  // Update service types to match backend validation
  final List<Map<String, String>> _serviceTypes = ServiceType.all;
  String? _selectedServiceType;

  Map<String, String> _fieldErrors = {};

  String? _profileImageBase64;

  final List<String> _communicationOptions = ['SMS', 'Email', 'Both'];
  final List<String> _timezones = [
    'UTC',
    'Africa/Nairobi',
    'Africa/Lagos',
    'Africa/Cairo'
  ];

  @override
  void initState() {
    super.initState();
    _backupContactController = TextEditingController();
    _selectedCommunication = 'Both'; // Default value
    _selectedTimezone = 'UTC'; // Default value
  }

  Widget _buildServiceTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedServiceType,
      decoration: InputDecoration(
        labelText: 'Service Type',
        border: OutlineInputBorder(),
      ),
      items: _serviceTypes.map((service) {
        return DropdownMenuItem<String>(
          value: service['value'],
          child: Text(service['display']!),
        );
      }).toList(),
      validator: (value) =>
          value == null ? 'Please select a service type' : null,
      onChanged: (newValue) {
        setState(() {
          _selectedServiceType = newValue;
        });
      },
    );
  }

  Widget _buildProfileImagePicker() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            child: _profileImageBase64 != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.memory(
                      base64Decode(_profileImageBase64!.split(',')[1]),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(Icons.person, size: 50, color: Colors.grey[400]),
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
                icon: Icon(Icons.camera_alt, color: Colors.white, size: 20),
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

  Future<void> _handleNavigation(Map<String, dynamic> authData) async {
    try {
      // Extract user data with proper fallbacks
      final userData =
          authData['provider'] ?? authData['user'] ?? authData['client'];

      if (userData == null) {
        throw Exception('Invalid response: missing user data');
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login successful!')),
      );

      // For service providers, ensure we have the correct data mapping
      if (isServiceProvider) {
        final providerData = {
          'userName': userData['name'] ?? userData['businessName'] ?? '',
          'userId': userData['id'] ?? userData['_id'] ?? '',
          'businessName': userData['businessName'] ?? '',
          'serviceType':
              userData['serviceType'] ?? userData['serviceOffered'] ?? '',
        };

        print('Navigating to ServiceProviderScreen with data: $providerData');

        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => provider.ServiceProviderScreen(
              userName: providerData['userName']!,
              userId: providerData['userId']!,
              businessName: providerData['businessName']!,
              serviceType: providerData['serviceType']!,
            ),
          ),
        );
      } else {
        // Client navigation remains unchanged
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              user: User.fromJson(userData),
            ),
          ),
        );
      }
    } catch (e) {
      print('Navigation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error navigating: ${e.toString()}')),
      );
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> locationData = {
        'type': 'Point',
        'coordinates': <double>[36.8219, -1.2921]
      };

      final response = await authService.signUpWithEmail(
        name: nameController.text,
        email: emailController.text.trim(),
        password: passwordController.text,
        phoneNumber: phoneController.text,
        address: addressController.text,
        location: locationData,
        profilePicture: _profileImageBase64,
        backupContact: _backupContactController.text,
        preferredCommunication: _selectedCommunication,
        timezone: _selectedTimezone,
        isProvider: isServiceProvider,
        businessName: isServiceProvider ? businessNameController.text : null,
        serviceType: isServiceProvider ? _selectedServiceType : null,
      );

      if (response['success'] == true) {
        // Extract data properly from the response
        final userData =
            isServiceProvider ? response['provider'] : response['user'];

        if (userData == null) {
          throw Exception('Invalid response: missing user data');
        }

        await AuthService.saveAuthData({
          'token': response['token'],
          'userType': isServiceProvider ? 'service-provider' : 'client',
          'user': userData,
        });

        if (!mounted) return;

        if (isServiceProvider) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => provider.ServiceProviderScreen(
                userName: userData['name'] ?? '',
                userId: userData['id'] ?? '',
                businessName: userData['businessName'] ?? '',
                serviceType: userData['serviceType'] ?? 'general',
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                user: User.fromJson(userData),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error during signup: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildCommunicationPreference() {
    return DropdownButtonFormField<String>(
      value: _selectedCommunication,
      decoration: const InputDecoration(
        labelText: 'Communication Preference',
        border: OutlineInputBorder(),
      ),
      items: _communicationOptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCommunication = value),
      validator: (value) => value == null ? 'Please select a preference' : null,
    );
  }

  Widget _buildTimezoneSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedTimezone,
      decoration: const InputDecoration(
        labelText: 'Timezone',
        border: OutlineInputBorder(),
      ),
      items: _timezones.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedTimezone = value),
      validator: (value) => value == null ? 'Please select a timezone' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              _buildProfileImagePicker(), // Add this at the top
              const SizedBox(height: 20),
              // User Type Switch
              SwitchListTile(
                title: Text(isServiceProvider ? 'Service Provider' : 'Client'),
                value: isServiceProvider,
                onChanged: (value) => setState(() => isServiceProvider = value),
              ),

              // Common Fields
              buildTextField(nameController, 'Name'),
              buildTextField(
                  emailController, 'Email', TextInputType.emailAddress),
              buildPasswordField(),
              buildTextField(
                  phoneController, 'Phone Number', TextInputType.phone),
              buildTextField(addressController,
                  isServiceProvider ? 'Business Address' : 'Address'),

              // Service Provider Specific Fields
              if (isServiceProvider) ...[
                buildTextField(businessNameController, 'Business Name'),
                SizedBox(height: 16),
                buildTextField(
                    businessAddressController, // Changed from addressController
                    'Business Address',
                    TextInputType.streetAddress,
                    'Enter your business location'),
                SizedBox(height: 16),
                _buildServiceTypeDropdown(),
                SizedBox(height: 16),
              ],

              const SizedBox(height: 16),
              _buildCommunicationPreference(),
              const SizedBox(height: 16),
              _buildTimezoneSelector(),
              const SizedBox(height: 16),
              buildTextField(_backupContactController, 'Backup Contact',
                  TextInputType.phone, 'Alternative phone number'),

              SizedBox(height: 20),

              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _handleSignup,
                  child: Text('Sign Up'),
                ),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                ),
                child: Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String label,
      [TextInputType type = TextInputType.text, String? hintText]) {
    // Convert label to field name format
    String fieldName = label.toLowerCase().replaceAll(' ', '');
    bool isRequired = isServiceProvider
        ? true
        : // All fields required for service provider
        !label.startsWith('Business'); // Optional for clients

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hintText,
        errorText: _fieldErrors[fieldName],
        border: OutlineInputBorder(),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
      ),
      keyboardType: type,
      onChanged: (_) {
        // Clear error when user types
        if (_fieldErrors.containsKey(fieldName)) {
          setState(() {
            _fieldErrors.remove(fieldName);
          });
        }
      },
      validator: (value) {
        if (isRequired && (value?.isEmpty ?? true)) {
          return 'Please enter $label';
        }
        if (label == 'Phone Number' && !_isValidPhoneNumber(value!)) {
          return 'Please enter a valid phone number';
        }
        return null;
      },
    );
  }

  bool _isValidPhoneNumber(String phone) {
    // Simple validation - can be made more complex
    return phone.length >= 10 && phone.length <= 15;
  }

  Widget buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      obscureText: !_passwordVisible,
      decoration: InputDecoration(
        labelText: 'Password',
        suffixIcon: IconButton(
          icon:
              Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
        ),
      ),
      validator: (value) => value == null || value.length < 6
          ? 'Password must be at least 6 characters'
          : null,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    addressController.dispose();
    businessNameController.dispose();
    businessAddressController.dispose();
    serviceOfferedController.dispose();
    _backupContactController.dispose();
    super.dispose();
  }
}
