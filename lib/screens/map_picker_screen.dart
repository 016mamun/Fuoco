import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(23.8103, 90.4125); // Default to Dhaka
  String _address = "Locating...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _isLoading = false;
    });
    
    _mapController.move(_currentPosition, 15);
    _getAddressFromLatLng(_currentPosition);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      // Using Nominatim API (Free, no key required)
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1',
      );
      
      final response = await http.get(
        url,
        headers: {'User-Agent': 'FuocoApp'}, // Required by Nominatim policy
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _address = data['display_name'] ?? "Address not found";
        });
      }
    } catch (e) {
      setState(() {
        _address = "Error finding address";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFA500),
        elevation: 0,
        title: const Text('Pick Location', style: TextStyle(color: Colors.white, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 15,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  _currentPosition = position.center;
                }
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _getAddressFromLatLng(_currentPosition);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.fuoco',
              ),
            ],
          ),
          // Center Marker
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 35),
              child: Icon(
                Icons.location_on,
                size: 50,
                color: Color(0xFFFFA500),
              ),
            ),
          ),
          // Loading Indicator
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFFFFA500))),
          
          // Address Panel
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA500).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, color: Color(0xFFFFA500), size: 20),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          _address,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'address': _address,
                          'lat': _currentPosition.latitude,
                          'lng': _currentPosition.longitude,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFA500),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirm Delivery Location',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Current Location Button
          Positioned(
            right: 20,
            bottom: 180,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location, color: Color(0xFFFFA500)),
            ),
          ),
        ],
      ),
    );
  }
}
