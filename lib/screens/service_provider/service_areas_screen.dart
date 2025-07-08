import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/provider_services/service_area_service.dart';

class ServiceAreasScreen extends StatefulWidget {
  @override
  _ServiceAreasScreenState createState() => _ServiceAreasScreenState();
}

class _ServiceAreasScreenState extends State<ServiceAreasScreen> {
  GoogleMapController? _mapController;
  Set<Circle> _serviceAreas = {};
  LatLng? _selectedLocation;
  double _radius = 5000; // 5km default radius

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Service Areas')),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(-1.2921, 36.8219), // Nairobi
                zoom: 12,
              ),
              circles: _serviceAreas,
              onMapCreated: (controller) => _mapController = controller,
              onTap: _handleMapTap,
            ),
          ),
          _buildRadiusSlider(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveServiceArea,
        child: Icon(Icons.save),
      ),
    );
  }

  Widget _buildRadiusSlider() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Service Radius: ${(_radius / 1000).toStringAsFixed(1)}km'),
          Slider(
            value: _radius,
            min: 1000,
            max: 20000,
            onChanged: (value) {
              setState(() {
                _radius = value;
                _updateServiceArea();
              });
            },
          ),
        ],
      ),
    );
  }

  void _handleMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _updateServiceArea();
    });
  }

  void _updateServiceArea() {
    if (_selectedLocation == null) return;

    setState(() {
      _serviceAreas = {
        Circle(
          circleId: CircleId('serviceArea'),
          center: _selectedLocation!,
          radius: _radius,
          fillColor: Colors.blue.withOpacity(0.2),
          strokeColor: Colors.blue,
          strokeWidth: 2,
        ),
      };
    });
  }

  Future<void> _saveServiceArea() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a location first')),
      );
      return;
    }

    try {
      await ProviderServiceAreaService().updateServiceArea(
        coordinates: [
          _selectedLocation!.longitude,
          _selectedLocation!.latitude
        ],
        radius: _radius,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Service area updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update service area: $e')),
      );
    }
  }
}
