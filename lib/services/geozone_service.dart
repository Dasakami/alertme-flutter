import 'package:flutter/foundation.dart';
import 'package:alertme/models/geozone.dart';
import 'package:alertme/services/api_client.dart';

class GeozoneService {
  GeozoneService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  static const String _zonesPath = '/api/geozones/';
  static const String _eventsPath = '/api/geozone-events/';

  Future<List<Geozone>> listGeozones() async {
    try {
      final data = await _api.getJson(_zonesPath);
      final results = (data['results'] as List? ?? data['data'] as List? ?? data as List?) ?? [];
      return results
          .map((e) => Geozone.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      debugPrint('listGeozones error: $e');
      rethrow;
    }
  }

  Future<Geozone> createGeozone({
    required String name,
    String? description,
    required String zoneType,
    double? latitude,
    double? longitude,
    double? radius,
    List<List<double>>? polygonCoordinates,
    bool notifyOnEnter = false,
    bool notifyOnExit = false,
    bool isActive = true,
    List<int> contactIds = const [],
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'description': description,
      'zone_type': zoneType,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'polygon_coordinates': polygonCoordinates,
      'notify_on_enter': notifyOnEnter,
      'notify_on_exit': notifyOnExit,
      'is_active': isActive,
      'contact_ids': contactIds,
    }..removeWhere((key, value) => value == null);
    final data = await _api.postJson(_zonesPath, body: body);
    return Geozone.fromJson(data);
  }

  Future<Geozone> updateGeozone(int id, Map<String, dynamic> updates) async {
    final data = await _api.putJson('$_zonesPath$id/', body: updates);
    return Geozone.fromJson(data);
  }

  Future<void> deleteGeozone(int id) async {
    await _api.delete('$_zonesPath$id/');
  }

  Future<List<GeozoneEvent>> listEvents({int? geozoneId}) async {
    try {
      final data = await _api.getJson(_eventsPath, query: geozoneId != null ? {'geozone': geozoneId} : null);
      final results = (data['results'] as List? ?? data['data'] as List? ?? data as List?) ?? [];
      return results
          .map((e) => GeozoneEvent.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      debugPrint('listEvents error: $e');
      rethrow;
    }
  }
}