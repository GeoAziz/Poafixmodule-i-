import 'package:flutter/material.dart';
import '../../services/availability_service.dart';

class AvailabilityScreen extends StatefulWidget {
  @override
  _AvailabilityScreenState createState() => _AvailabilityScreenState();
}

class TimeSlot {
  final String startTime;
  final String endTime;
  bool isAvailable;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
  });
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final _availabilityService = AvailabilityService();
  final Map<String, List<TimeSlot>> _weeklySchedule = {
    'Monday': [],
    'Tuesday': [],
    'Wednesday': [],
    'Thursday': [],
    'Friday': [],
    'Saturday': [],
    'Sunday': [],
  };
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<String> _getProviderId() async {
    // Example: fetch from secure storage or context
    // Replace with your actual logic
    return Future.value('provider_id');
  }

  String _getDayName(int index) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[index];
  }

  void _addTimeSlot(String day) {
    setState(() {
      _weeklySchedule[day]!.add(TimeSlot(startTime: '09:00', endTime: '17:00'));
    });
  }

  void _updateTimeSlot(TimeSlot slot, String day, bool value) {
    setState(() {
      slot.isAvailable = value;
    });
  }

  Future<void> _loadAvailability() async {
    setState(() => _isLoading = true);
    try {
      final schedule = await _availabilityService.getProviderAvailability(
        await _getProviderId(),
      );
      setState(() {
        for (var item in schedule) {
          final day = item['weekDay'] as String;
          _weeklySchedule[day] = [
            TimeSlot(
              startTime: item['startTime'],
              endTime: item['endTime'],
              isAvailable: item['isAvailable'],
            ),
          ];
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading schedule: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Set Availability')),
      body: ListView.builder(
        itemCount: 7,
        itemBuilder: (context, index) {
          final day = _getDayName(index);
          return _buildDaySchedule(day);
        },
      ),
    );
  }

  Widget _buildDaySchedule(String day) {
    return Card(
      margin: EdgeInsets.all(8),
      child: ExpansionTile(
        title: Text(day),
        children: [
          _buildTimeSlots(day),
          ElevatedButton(
            onPressed: () => _addTimeSlot(day),
            child: Text('Add Time Slot'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlots(String day) {
    return Column(
      children: _weeklySchedule[day]!
          .map((slot) => _buildTimeSlotTile(slot, day))
          .toList(),
    );
  }

  Widget _buildTimeSlotTile(TimeSlot slot, String day) {
    return ListTile(
      title: Text('${slot.startTime} - ${slot.endTime}'),
      trailing: Switch(
        value: slot.isAvailable,
        onChanged: (value) => _updateTimeSlot(slot, day, value),
      ),
    );
  }
}
