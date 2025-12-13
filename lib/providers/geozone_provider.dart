import 'package:flutter/foundation.dart';
import 'package:alertme/models/geozone.dart';
import 'package:alertme/services/geozone_service.dart';

class GeozoneProvider with ChangeNotifier {
  final GeozoneService _service = GeozoneService();
  bool _isLoading = false;
  String? _error;

  List<Geozone> get geozones => _service.geozones;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadGeozones() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.loadGeozones();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Geozone?> createGeozone({
    required String name,
    String? description,
    required String zoneType,
    required double latitude,
    required double longitude,
    required double radius,
    List<List<double>>? polygonCoordinates,
    bool notifyOnEnter = true,
    bool notifyOnExit = true,
    List<int> contactIds = const [],
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final geozone = await _service.createGeozone(
        name: name,
        description: description,
        zoneType: zoneType,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        polygonCoordinates: polygonCoordinates,
        notifyOnEnter: notifyOnEnter,
        notifyOnExit: notifyOnExit,
        contactIds: contactIds,
      );
      _isLoading = false;
      notifyListeners();
      return geozone;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteGeozone(int id) async {
    try {
      await _service.deleteGeozone(id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<GeozoneEvent>> getGeozoneEvents(int geozoneId) async {
    try {
      return await _service.getGeozoneEvents(geozoneId);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }
}