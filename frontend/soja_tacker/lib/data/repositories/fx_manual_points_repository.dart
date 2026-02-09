// lib/data/repositories/fx_manual_points_repository.dart


import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/fx/fx_manual_point_create.dart';
import '../models/fx/fx_manual_point_read.dart';
import '../models/fx/fx_manual_point_update.dart';

class FxManualPointsRepository {
  final ApiClient api;
  FxManualPointsRepository(this.api);

  Future<FxManualPointRead> create({
    required int farmId,
    required FxManualPointCreate payload,
  }) async {
    try {
      final res = await api.dio.post(
        '/farms/$farmId/fx/manual-points',
        data: payload.toJson(),
      );
      return FxManualPointRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao criar ponto manual FX');
    }
  }

  Future<List<FxManualPointRead>> list({
    required int farmId,
    int? sourceId,
    String? refMes, // yyyy-mm-dd
    int limit = 2000,
  }) async {
    try {
      final res = await api.dio.get(
        '/farms/$farmId/fx/manual-points',
        queryParameters: {
          if (sourceId != null) 'source_id': sourceId,
          if (refMes != null) 'ref_mes': refMes,
          'limit': limit,
        },
      );
      final list = (res.data as List).cast<dynamic>();
      return list.map((e) => FxManualPointRead.fromJson(e as Map<String, dynamic>)).toList();
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao listar pontos manuais FX');
    }
  }

  Future<FxManualPointRead> getById({
    required int farmId,
    required int pointId,
  }) async {
    try {
      final res = await api.dio.get('/farms/$farmId/fx/manual-points/$pointId');
      return FxManualPointRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao obter ponto manual FX');
    }
  }

  Future<FxManualPointRead> update({
    required int farmId,
    required int pointId,
    required FxManualPointUpdate payload,
  }) async {
    try {
      final res = await api.dio.patch(
        '/farms/$farmId/fx/manual-points/$pointId',
        data: payload.toJson(),
      );
      return FxManualPointRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao atualizar ponto manual FX');
    }
  }

  Future<void> delete({
    required int farmId,
    required int pointId,
  }) async {
    try {
      await api.dio.delete('/farms/$farmId/fx/manual-points/$pointId');
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao excluir ponto manual FX');
    }
  }

  ApiException _asApiException(Object e, {required String fallback}) {
    if (e is ApiException) return e;
    return ApiException(message: fallback, details: e.toString());
  }
}
