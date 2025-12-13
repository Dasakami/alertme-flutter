import 'package:flutter/foundation.dart';
import 'package:alertme/models/shared_location.dart';
import 'package:alertme/services/api_client.dart';

class SharedLocationService {
  SharedLocationService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  static const String _path = '/api/shared-locations/';

  Future<SharedLocationModel> create({
    required int sharedWithId,
    required int durationMinutes,
  }) async {
    final data = await _api.postJson(_path, body: {
      'shared_with_id': sharedWithId,
      'duration_minutes': durationMinutes,
    });
    return SharedLocationModel.fromJson(data);
  }

  Future<List<SharedLocationModel>> list() async {
    try {
      final data = await _api.getJson(_path);
      final results = (data['results'] as List? ?? data['data'] as List? ?? data as List?) ?? [];
      return results
          .map((e) => SharedLocationModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      debugPrint('SharedLocation list error: $e');
      rethrow;
    }
  }

  Future<SharedLocationModel> revoke(int id) async {
    final data = await _api.postJson('$_path$id/revoke/');
    return SharedLocationModel.fromJson(data);
  }
}
