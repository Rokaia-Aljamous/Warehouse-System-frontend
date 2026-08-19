import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:stock_app/controllers/driver_controller.dart';
import 'package:stock_app/models/driver_task_model.dart';
import 'package:stock_app/utils/constants.dart';
import 'package:stock_app/views/widgets/barcode_scanner_sheet.dart';

class MapScreen extends StatefulWidget {
  final DriverTask task;

  const MapScreen({super.key, required this.task});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  final MapController _mapController = MapController();

  StreamSubscription<Position>? _trackingSubscription;
  Position? _currentPosition;
  Position? _lastSentPosition;
  DateTime? _lastSentAt;

  bool _isLoadingLocation = true;
  bool _isTracking = false;
  bool _isSendingLocation = false;
  bool _isScanning = false;
  bool _taskCompleted = false;
  String? _locationError;
  String? _trackingError;

  LatLng get _destination => LatLng(
    widget.task.destinationLatitude!,
    widget.task.destinationLongitude!,
  );

  LocationSettings get _streamSettings {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 15),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: true,
        showBackgroundLocationIndicator: false,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLocation());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(_stopTracking());
    } else if (state == AppLifecycleState.resumed &&
        !_taskCompleted &&
        _currentPosition != null) {
      _startTracking();
    }
  }

  Future<void> _loadLocation() async {
    await _stopTracking();

    if (mounted) {
      setState(() {
        _isLoadingLocation = true;
        _locationError = null;
        _trackingError = null;
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

      await _acceptPosition(position, forceSend: true);
      if (!mounted) return;

      setState(() => _isLoadingLocation = false);
      _startTracking();
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

  void _startTracking() {
    if (_trackingSubscription != null || _taskCompleted || !mounted) return;

    _trackingSubscription =
        Geolocator.getPositionStream(locationSettings: _streamSettings).listen(
          (position) => unawaited(_acceptPosition(position)),
          onError: (_) {
            if (!mounted) return;
            setState(() {
              _trackingError = 'Live location tracking was interrupted.';
              _isTracking = false;
            });
          },
        );

    setState(() => _isTracking = true);
  }

  Future<void> _acceptPosition(
    Position position, {
    bool forceSend = false,
  }) async {
    if (_taskCompleted || !mounted) return;

    setState(() {
      _currentPosition = position;
      _locationError = null;
    });

    final now = DateTime.now();
    final elapsed = _lastSentAt == null
        ? const Duration(days: 1)
        : now.difference(_lastSentAt!);
    final movedMeters = _lastSentPosition == null
        ? double.infinity
        : Geolocator.distanceBetween(
            _lastSentPosition!.latitude,
            _lastSentPosition!.longitude,
            position.latitude,
            position.longitude,
          );

    final shouldSend =
        forceSend ||
        elapsed >= const Duration(seconds: 15) ||
        movedMeters >= 15;
    if (!shouldSend || _isSendingLocation) return;

    _isSendingLocation = true;
    final success = await context
        .read<DriverController>()
        .updateCurrentLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        );
    _isSendingLocation = false;

    if (!mounted || _taskCompleted) return;
    setState(() {
      if (success) {
        _lastSentAt = now;
        _lastSentPosition = position;
        _trackingError = null;
      } else {
        _trackingError = 'Unable to send the current location to the server.';
      }
    });
  }

  Future<void> _stopTracking() async {
    final subscription = _trackingSubscription;
    _trackingSubscription = null;
    await subscription?.cancel();

    if (mounted && _isTracking) {
      setState(() => _isTracking = false);
    }
  }

  Future<void> _scanAndComplete() async {
    if (_isScanning || _taskCompleted) return;

    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (!mounted || barcode == null || barcode.trim().isEmpty) return;

    setState(() => _isScanning = true);
    final result = await context.read<DriverController>().scanTaskBarcode(
      taskId: widget.task.id,
      barcode: barcode.trim(),
    );

    if (!mounted) return;
    setState(() => _isScanning = false);

    if (result['success'] == true) {
      _taskCompleted = true;
      await _stopTracking();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task completed successfully')),
      );
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ??
              'The scanned barcode does not match this task.',
        ),
      ),
    );
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_trackingSubscription?.cancel());
    _trackingSubscription = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentPosition == null
        ? null
        : LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final visibleError = _locationError ?? _trackingError;

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
          if (visibleError != null)
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
                  visibleError,
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        _isTracking ? Icons.gps_fixed : Icons.gps_off,
                        size: 18,
                        color: _isTracking ? Colors.green : Colors.black45,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        _isTracking
                            ? 'Live location tracking is active'
                            : 'Location tracking is stopped',
                        style: const TextStyle(fontSize: 12),
                      ),
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
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _currentPosition == null || _isScanning
                          ? null
                          : _scanAndComplete,
                      icon: _isScanning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.qr_code_scanner),
                      label: Text(
                        _isScanning ? 'Checking Barcode…' : 'Scan QR/Barcode',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
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
