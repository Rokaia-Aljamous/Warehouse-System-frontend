import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:stock_app/controllers/driver_controller.dart';
import 'package:stock_app/models/driver_task_model.dart';
import 'package:stock_app/utils/constants.dart';

class MapScreen extends StatefulWidget {
  final DriverTask task;

  const MapScreen({super.key, required this.task});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  String? _locationError;

  LatLng get _destination => LatLng(
    widget.task.destinationLatitude!,
    widget.task.destinationLongitude!,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLocation());
  }

  Future<void> _loadLocation() async {
    final driverController = context.read<DriverController>();
    if (mounted) {
      setState(() {
        _isLoadingLocation = true;
        _locationError = null;
      });
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const _DriverLocationException(
          'Turn on location services to show your current position.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw const _DriverLocationException(
          'Location permission is required to start the route.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        throw const _DriverLocationException(
          'Location permission is permanently denied. Enable it from settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      await driverController.updateCurrentLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;
      _focusRoute();
    } on _DriverLocationException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
        _locationError = error.message;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
        _locationError = 'Unable to read your current location.';
      });
    }
  }

  void _focusRoute() {
    final current = _currentPosition;
    if (current == null) return;

    final center = LatLng(
      (current.latitude + _destination.latitude) / 2,
      (current.longitude + _destination.longitude) / 2,
    );
    final distance = Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      _destination.latitude,
      _destination.longitude,
    );
    final zoom = distance < 1000
        ? 15.0
        : distance < 5000
        ? 13.0
        : distance < 20000
        ? 11.0
        : 8.0;

    _mapController.move(center, zoom);
  }

  String get _distanceLabel {
    final current = _currentPosition;
    if (current == null) return 'Current location unavailable';
    final meters = Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      _destination.latitude,
      _destination.longitude,
    );
    if (meters < 1000) return '${meters.round()} m from destination';
    return '${(meters / 1000).toStringAsFixed(1)} km from destination';
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentPosition == null
        ? null
        : LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _destination, initialZoom: 15),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.stock_app',
              ),
              if (current != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [current, _destination],
                      strokeWidth: 4,
                      color: const Color(0xFF2196F3),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (current != null)
                    Marker(
                      point: current,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  Marker(
                    point: _destination,
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.location_pin,
                      color: Color(0xFFF3A523),
                      size: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 14,
            right: 14,
            child: Row(
              children: [
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.navy),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _isLoadingLocation
                          ? 'Reading your location…'
                          : _distanceLabel,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_locationError != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 72,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _locationError!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.displayName,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFFF3A523),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(widget.task.displayLocation)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoadingLocation ? null : _loadLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Refresh My Location'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        side: const BorderSide(color: AppColors.navy),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverLocationException implements Exception {
  final String message;
  const _DriverLocationException(this.message);
}
