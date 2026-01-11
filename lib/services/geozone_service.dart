import 'package:flutter/foundation.dart';
import 'package:alertme/models/geozone.dart';
import 'package:alertme/services/api_client.dart';

class GeozoneService {
  final ApiClient _api = ApiClient();
  List<Geozone> _geozones = [];

  List<Geozone> get geozones => List.unmodifiable(_geozones);

  Future<void> loadGeozones() async {
    try {
      final data = await _api.getJson('/geozones/', auth: true);
      
      List<dynamic> results; 
      if (data is List) {
        results = data as List<dynamic>;
      } else if (data['results'] is List) {
        results = data['results'] as List<dynamic>;
      } else if (data['data'] is List) {
        results = data['data'] as List<dynamic>;
      } else {
        results = [];
      }
      
      _geozones = results
          .map((e) => Geozone.fromJson(e as Map<String, dynamic>))
          .toList();
          
      debugPrint('✅ Загружено ${_geozones.length} геозон');
    } catch (e) {
      debugPrint('❌ Ошибка загрузки геозон: $e');
      _geozones = [];
      rethrow;
    }
  }

  Future<Geozone> createGeozone({
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
    try {
      final body = {
        'name': name,
        'description': description,
        'zone_type': zoneType,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'polygon_coordinates': polygonCoordinates,
        'notify_on_enter': notifyOnEnter,
        'notify_on_exit': notifyOnExit,
        'contact_ids': contactIds,
      };

      final data = await _api.postJson('/geozones/', body: body, auth: true);
      final geozone = Geozone.fromJson(data);
      _geozones.add(geozone);
      
      debugPrint('✅ Геозона создана: ${geozone.name}');
      return geozone;
    } catch (e) {
      debugPrint('❌ Ошибка создания геозоны: $e');
      rethrow;
    }
  }

  Future<Geozone> updateGeozone(int id, Map<String, dynamic> updates) async {
    try {
      final data = await _api.putJson('/geozones/$id/', body: updates, auth: true);
      final updated = Geozone.fromJson(data);
      
      final index = _geozones.indexWhere((g) => g.id == id);
      if (index != -1) {
        _geozones[index] = updated;
      }
      
      debugPrint('✅ Геозона обновлена: ${updated.name}');
      return updated;
    } catch (e) {
      debugPrint('❌ Ошибка обновления геозоны: $e');
      rethrow;
    }
  }

  Future<void> deleteGeozone(int id) async {
    try {
      await _api.delete('/geozones/$id/', auth: true);
      _geozones.removeWhere((g) => g.id == id);
      debugPrint('✅ Геозона удалена: $id');
    } catch (e) {
      debugPrint('❌ Ошибка удаления геозоны: $e');
      rethrow;
    }
  }

  Future<List<GeozoneEvent>> getGeozoneEvents(int geozoneId) async {
    try {
      final data = await _api.getJson('/geozones/$geozoneId/events/', auth: true);
      
      List<dynamic> results; 
      if (data is List) {
        results = data as List<dynamic>;
      } else if (data['results'] is List) {
        results = data['results'] as List<dynamic>;
      } else if (data['data'] is List) {
        results = data['data'] as List<dynamic>;
      } else {
        results = [];
      }
      
      return results
          .map((e) => GeozoneEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Ошибка загрузки событий: $e');
      return [];
    }
  }

  Geozone? getGeozoneById(int id) {
    try {
      return _geozones.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearCache() => _geozones = [];
}