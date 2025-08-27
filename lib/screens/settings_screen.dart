import 'package:flutter/material.dart';
import '../models/provider_settings.dart';
import '../services/settings_service.dart';
import '../widgets/provider_base_screen.dart';
import '../models/user_model.dart'; // Import the correct User class
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  bool _isLoading = true;
  ProviderSettings? _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.getSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() => _isLoading = false);
      _showErrorSnackbar('Failed to load settings');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: _loadSettings,
          textColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProviderBaseScreen(
      user: User(
        id: _settings?.providerId ?? '',
        name: 'Sarah Wanjiku',
        email: 'sarah@example.com',
        userType: 'provider',
      ),
      title: 'Settings',
      body: _isLoading
          ? Center(
              child: SpinKitDoubleBounce(
                color: Theme.of(context).primaryColor,
                size: 50.0,
              ),
            )
          : _settings == null
          ? _buildErrorState()
          : _buildSettingsContent(),
    );
  }

  Widget _buildSettingsContent() {
    return Theme(
      data: Theme.of(context).copyWith(
        cardTheme: CardThemeData(
          elevation: 4,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
            return states.contains(WidgetState.selected)
                ? Theme.of(context).primaryColor
                : Colors.grey;
          }),
        ),
      ),
      child: ListView(
        children: [
          _buildProfileSection(),
          _buildWorkingHoursSection(),
          _buildNotificationsSection(),
          _buildLocationSection(),
          _buildPaymentSection(),
          _buildServiceAreaSection(),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile', style: _headerStyle),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text('Sarah Wanjiku'),
              subtitle: Text('Quick Movers Nairobi'),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  // TODO: Implement edit profile
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add more section building methods...

  TextStyle get _headerStyle => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).primaryColor,
  );

  Widget _buildNotificationsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notifications', style: _headerStyle),
            SwitchListTile(
              title: Text('Booking Requests'),
              value: _settings?.notifications.bookingRequests ?? false,
              onChanged: (value) =>
                  _updateNotificationSetting('bookingRequests', value),
            ),
            SwitchListTile(
              title: Text('Messages'),
              value: _settings?.notifications.messages ?? false,
              onChanged: (value) =>
                  _updateNotificationSetting('messages', value),
            ),
            SwitchListTile(
              title: Text('Updates'),
              value: _settings?.notifications.updates ?? false,
              onChanged: (value) =>
                  _updateNotificationSetting('updates', value),
            ),
            SwitchListTile(
              title: Text('Marketing'),
              value: _settings?.notifications.marketing ?? false,
              onChanged: (value) =>
                  _updateNotificationSetting('marketing', value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingHoursSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Working Hours', style: _headerStyle),
            ..._settings?.workingHours.entries.map(
                  (entry) => _buildDaySchedule(entry.key, entry.value),
                ) ??
                [],
          ],
        ),
      ),
    );
  }

  Widget _buildDaySchedule(String day, WorkingHours hours) {
    return ListTile(
      title: Text(day.capitalize()),
      subtitle: Text('${hours.start} - ${hours.end}'),
      trailing: Switch(
        value: hours.isActive,
        onChanged: (value) => _updateWorkingHours(day, value),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location Settings', style: _headerStyle),
            SwitchListTile(
              title: Text('Location Tracking'),
              value: _settings?.locationTracking.enabled ?? false,
              onChanged: _updateLocationSetting,
            ),
            ListTile(
              title: Text('Accuracy'),
              subtitle: Text(_settings?.locationTracking.accuracy ?? 'high'),
              trailing: PopupMenuButton<String>(
                onSelected: _updateAccuracySetting,
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'high', child: Text('High')),
                  PopupMenuItem(value: 'medium', child: Text('Medium')),
                  PopupMenuItem(value: 'low', child: Text('Low')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Settings', style: _headerStyle),
            SwitchListTile(
              title: Text('M-PESA'),
              value: _settings?.paymentPreferences.mpesa ?? false,
              onChanged: (value) => _updatePaymentSetting('mpesa', value),
            ),
            SwitchListTile(
              title: Text('Cash'),
              value: _settings?.paymentPreferences.cash ?? false,
              onChanged: (value) => _updatePaymentSetting('cash', value),
            ),
            SwitchListTile(
              title: Text('Auto Withdrawal'),
              value: _settings?.paymentPreferences.autoWithdrawal ?? false,
              onChanged: (value) =>
                  _updatePaymentSetting('autoWithdrawal', value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceAreaSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service Area', style: _headerStyle),
            ListTile(
              title: Text('Service Radius'),
              subtitle: Text('${_settings?.serviceArea.radius ?? 0} km'),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: _showRadiusDialog,
              ),
            ),
            ListTile(
              title: Text('Base Location'),
              subtitle: Text(
                _settings?.serviceArea.baseLocation.coordinates.join(', ') ??
                    '',
              ),
              trailing: IconButton(
                icon: Icon(Icons.map),
                onPressed: _showLocationPicker,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Failed to load settings',
            style: GoogleFonts.poppins(fontSize: 18),
          ),
          ElevatedButton(onPressed: _loadSettings, child: Text('Retry')),
        ],
      ),
    );
  }

  Future<void> _updateWorkingHours(String day, bool isActive) async {
    if (_settings == null) return;

    final workingHours = Map<String, WorkingHours>.from(
      _settings!.workingHours,
    );
    final currentHours = workingHours[day]!;

    workingHours[day] = WorkingHours(
      start: currentHours.start,
      end: currentHours.end,
      isActive: isActive,
    );

    final updatedSettings = ProviderSettings(
      providerId: _settings!.providerId,
      workingHours: workingHours,
      notifications: _settings!.notifications,
      locationTracking: _settings!.locationTracking,
      paymentPreferences: _settings!.paymentPreferences,
      serviceArea: _settings!.serviceArea,
    );

    try {
      await _settingsService.updateSettings(updatedSettings);
      setState(() => _settings = updatedSettings);
    } catch (e) {
      _showErrorSnackbar('Failed to update working hours');
    }
  }

  void _showRadiusDialog() {
    // Implement radius editing dialog
    // TODO: Add implementation
  }

  void _showLocationPicker() {
    // Implement location picker
    // TODO: Add implementation
  }

  Future<void> _updateNotificationSetting(String setting, bool value) async {
    if (_settings == null) return;

    final updatedSettings = ProviderSettings(
      providerId: _settings!.providerId,
      workingHours: _settings!.workingHours,
      notifications: NotificationSettings(
        bookingRequests: setting == 'bookingRequests'
            ? value
            : _settings!.notifications.bookingRequests,
        messages: setting == 'messages'
            ? value
            : _settings!.notifications.messages,
        updates: setting == 'updates'
            ? value
            : _settings!.notifications.updates,
        marketing: setting == 'marketing'
            ? value
            : _settings!.notifications.marketing,
        pushEnabled: _settings!.notifications.pushEnabled,
        emailEnabled: _settings!.notifications.emailEnabled,
      ),
      locationTracking: _settings!.locationTracking,
      paymentPreferences: _settings!.paymentPreferences,
      serviceArea: _settings!.serviceArea,
    );

    try {
      await _settingsService.updateSettings(updatedSettings);
      setState(() => _settings = updatedSettings);
    } catch (e) {
      _showErrorSnackbar('Failed to update notification settings');
    }
  }

  Future<void> _updatePaymentSetting(String setting, bool value) async {
    if (_settings == null) return;

    final updatedSettings = ProviderSettings(
      providerId: _settings!.providerId,
      workingHours: _settings!.workingHours,
      notifications: _settings!.notifications,
      locationTracking: _settings!.locationTracking,
      paymentPreferences: PaymentPreferences(
        mpesa: setting == 'mpesa' ? value : _settings!.paymentPreferences.mpesa,
        cash: setting == 'cash' ? value : _settings!.paymentPreferences.cash,
        autoWithdrawal: setting == 'autoWithdrawal'
            ? value
            : _settings!.paymentPreferences.autoWithdrawal,
        minimumWithdrawal: _settings!.paymentPreferences.minimumWithdrawal,
      ),
      serviceArea: _settings!.serviceArea,
    );

    try {
      await _settingsService.updateSettings(updatedSettings);
      setState(() => _settings = updatedSettings);
    } catch (e) {
      _showErrorSnackbar('Failed to update payment settings');
    }
  }

  void _updateLocationSetting(bool value) {
    if (_settings == null) return;
    setState(() {
      _settings = ProviderSettings(
        providerId: _settings!.providerId,
        workingHours: _settings!.workingHours,
        notifications: _settings!.notifications,
        locationTracking: LocationSettings(
          enabled: value,
          accuracy: _settings!.locationTracking.accuracy,
        ),
        paymentPreferences: _settings!.paymentPreferences,
        serviceArea: _settings!.serviceArea,
      );
    });
    _saveSettings();
  }

  void _updateAccuracySetting(String value) {
    if (_settings == null) return;
    setState(() {
      _settings = ProviderSettings(
        providerId: _settings!.providerId,
        workingHours: _settings!.workingHours,
        notifications: _settings!.notifications,
        locationTracking: LocationSettings(
          enabled: _settings!.locationTracking.enabled,
          accuracy: value,
        ),
        paymentPreferences: _settings!.paymentPreferences,
        serviceArea: _settings!.serviceArea,
      );
    });
    _saveSettings();
  }

  Future<void> _saveSettings() async {
    try {
      if (_settings != null) {
        await _settingsService.updateSettings(_settings!);
      }
    } catch (e) {
      _showErrorSnackbar('Failed to save settings');
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
