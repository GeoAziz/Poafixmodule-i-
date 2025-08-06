import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/user_model.dart';
import '../../models/provider_model.dart';
import '../../services/enhanced_proximity_service.dart';
import '../booking/enhanced_booking_screen.dart';

class XComboProviderSearchScreen extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final User user;

  const XComboProviderSearchScreen({
    Key? key,
    required this.serviceId,
    required this.serviceName,
    required this.user,
  }) : super(key: key);

  @override
  _XComboProviderSearchScreenState createState() => _XComboProviderSearchScreenState();
}

class _XComboProviderSearchScreenState extends State<XComboProviderSearchScreen> {
  GoogleMapController? _mapController;
  List<ProviderModel> _providers = [];
  bool _isLoading = true;
  Position? _currentLocation;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() => _isLoading = true);
    try {
      _currentLocation = await Geolocator.getCurrentPosition();
      final providers = await ProximityService.getNearbyProviders(
        serviceId: widget.serviceId,
        latitude: _currentLocation?.latitude,
        longitude: _currentLocation?.longitude,
        radius: 10.0,
      );
      setState(() {
        _providers = providers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading providers: ${e.toString()}')),
      );
    }
  }

  Set<Marker> _buildProviderMarkers() {
    return _providers.map((provider) {
      return Marker(
        markerId: MarkerId(provider.id),
        position: LatLng(provider.latitude, provider.longitude),
        infoWindow: InfoWindow(title: provider.name),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose ${widget.serviceName} Provider'),
        backgroundColor: Color(0xFF6366F1),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top: Map
                Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        _currentLocation?.latitude ?? -1.2921,
                        _currentLocation?.longitude ?? 36.8219,
                      ),
                      zoom: 13,
                    ),
                    markers: _buildProviderMarkers(),
                    onMapCreated: (controller) => _mapController = controller,
                  ),
                ),
                // Bottom: Provider cards
                Expanded(
                  child: ListView.builder(
                    itemCount: _providers.length,
                    itemBuilder: (context, index) {
                      final provider = _providers[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: provider.profileImage != null
                                ? NetworkImage(provider.profileImage!)
                                : null,
                            child: provider.profileImage == null
                                ? Text(provider.name.substring(0, 1).toUpperCase())
                                : null,
                          ),
                          title: Text(provider.name),
                          subtitle: Text(
                            '⭐ ${provider.rating} • ${provider.distance.toStringAsFixed(1)} km away\nKSh ${provider.hourlyRate}/hour',
                          ),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EnhancedBookingScreen(
                                  serviceId: widget.serviceId,
                                  serviceName: widget.serviceName,
                                  user: widget.user,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
