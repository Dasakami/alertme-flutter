import 'package:flutter/foundation.dart';
import 'package:alertme/models/location_history.dart';
import 'package:alertme/services/api_client.dart';

class LocationHistoryService {
  LocationHistoryService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  static const String _path = '/api/location-history/';

  Future<List<LocationHistoryEntry>> list({DateTime? from, DateTime? to}) async {
    try {
      final query = <String, String>{};
      if (from != null) query['from'] = from.toIso8601String();
      if (to != null) query['to'] = to.toIso8601String();
      final data = await _api.getJson(_path, query: query.isEmpty ? null : query);
      final results = (data['results'] as List? ?? data['data'] as List? ?? data as List?) ?? [];
      return results
          .map((e) => LocationHistoryEntry.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      debugPrint('LocationHistory list error: $e');
      rethrow;
    }
  }

  Future<LocationHistoryEntry> create(LocationHistoryEntry entry) async {
    final data = await _api.postJson(_path, body: entry.toJson());
    return LocationHistoryEntry.fromJson(data);
  }
}
