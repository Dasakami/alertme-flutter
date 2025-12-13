import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:alertme/models/sos_event.dart';

class LocationService {
  Future<LocationData?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return _getMockLocation();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return _getMockLocation();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return _getMockLocation();
      }

      final position = await Geolocator.getCurrentPosition();
      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: 'Latitude: ${position.latitude}, Longitude: ${position.longitude}',
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return _getMockLocation();
    }
  }

  LocationData _getMockLocation() {
    return LocationData(
      latitude: 42.8746,
      longitude: 74.5698,
      address: 'Бишкек, Кыргызстан',
    );
  }

  Future<bool> checkPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return false;
    }
  }

  Future<bool> requestPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }
}
