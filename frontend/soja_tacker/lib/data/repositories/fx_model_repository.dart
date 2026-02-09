// lib/data/repositories/fx_model_repository.dart
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/fx/fx_model_point_read.dart';
import '../models/fx/fx_model_run_read.dart';
import '../models/fx/fx_model_run_with_points_read.dart';

class FxModelRepository {
  final ApiClient api;
  FxModelRepository(this.api);

  Future<List<FxModelRunRead>> listRuns({
    required int farmId,
    String? fromTs,
    String? toTs,
    int limit = 50,
  }) async {
    try {
      final res = await api.dio.get(
        '/farms/$farmId/fx/model/runs',
        queryParameters: {
          if (fromTs != null) 'from_ts': fromTs,
          if (toTs != null) 'to_ts': toTs,
          'limit': limit,
        },
      );
      final list = (res.data as List).cast<dynamic>();
      return list.map((e) => FxModelRunRead.fromJson(e as Map<String, dynamic>)).toList();
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao listar model runs');
    }
  }

  Future<FxModelRunRead?> latestRun({required int farmId}) async {
    try {
      final res = await api.dio.get('/farms/$farmId/fx/model/runs/latest');
      if (res.data == null) return null;
      return FxModelRunRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao obter latest run');
    }
  }

  Future<FxModelRunRead?> nearestRun({
    required int farmId,
    required String ts,
  }) async {
    try {
      final res = await api.dio.get(
        '/farms/$farmId/fx/model/runs/nearest',
        queryParameters: {'ts': ts},
      );
      if (res.data == null) return null;
      return FxModelRunRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao obter nearest run');
    }
  }

  Future<FxModelRunWithPointsRead> getRun({
    required int farmId,
    required int runId,
    bool includePoints = true,
  }) async {
    try {
      final res = await api.dio.get(
        '/farms/$farmId/fx/model/runs/$runId',
        queryParameters: {'include_points': includePoints},
      );
      return FxModelRunWithPointsRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao obter run');
    }
  }

  Future<List<FxModelPointRead>> listPoints({
    required int farmId,
    required int runId,
  }) async {
    try {
      final res = await api.dio.get('/farms/$farmId/fx/model/runs/$runId/points');
      final list = (res.data as List).cast<dynamic>();
      return list.map((e) => FxModelPointRead.fromJson(e as Map<String, dynamic>)).toList();
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao listar points');
    }
  }

  Future<FxModelPointRead?> getPoint({
    required int farmId,
    required int runId,
    required String refMes, // yyyy-mm-dd
  }) async {
    try {
      final res = await api.dio.get('/farms/$farmId/fx/model/runs/$runId/points/$refMes');
      if (res.data == null) return null;
      return FxModelPointRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao obter point');
    }
  }

  ApiException _asApiException(Object e, {required String fallback}) {
    if (e is ApiException) return e;
    return ApiException(message: fallback, details: e.toString());
  }
}
