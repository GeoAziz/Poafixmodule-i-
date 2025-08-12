import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ProviderMapWidget extends StatelessWidget {
  final List<Map<String, dynamic>> providers;
  final Function(int)? onMarkerTap;
  final double initialLat;
  final double initialLng;

  const ProviderMapWidget({
    Key? key,
    required this.providers,
    this.onMarkerTap,
    required this.initialLat,
    required this.initialLng,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {};
    for (int i = 0; i < providers.length; i++) {
      final provider = providers[i];
      final location = provider['location'];
      if (location != null &&
          location['coordinates'] != null &&
          location['coordinates'].length == 2) {
        final lng = location['coordinates'][0];
        final lat = location['coordinates'][1];
        markers.add(
          Marker(
            markerId:
                MarkerId(provider['_id'] ?? provider['id'] ?? i.toString()),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: provider['businessName'] ?? provider['name'] ?? 'Provider',
              snippet: provider['serviceType'] ?? '',
            ),
            onTap: () {
              if (onMarkerTap != null) onMarkerTap!(i);
            },
          ),
        );
      }
    }
    return Container(
      height: 220,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(initialLat, initialLng),
          zoom: 13,
        ),
        markers: markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
      ),
    );
  }
}
