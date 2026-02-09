// lib/data/repositories/fx_spot_repository.dart
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/fx/fx_spot_tick_create.dart';
import '../models/fx/fx_spot_tick_read.dart';

class FxSpotRepository {
  final ApiClient api;
  FxSpotRepository(this.api);

  Future<FxSpotTickRead> createTick({
    required int farmId,
    required FxSpotTickCreate payload,
  }) async {
    try {
      final res = await api.dio.post(
        '/farms/$farmId/fx/spot',
        data: payload.toJson(),
      );
      return FxSpotTickRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao criar tick FX spot');
    }
  }

  Future<List<FxSpotTickRead>> listTicks({
    required int farmId,
    String? fromTs,
    String? toTs,
    String? source,
    int limit = 2000,
  }) async {
    try {
      final res = await api.dio.get(
        '/farms/$farmId/fx/spot',
        queryParameters: {
          if (fromTs != null) 'from_ts': fromTs,
          if (toTs != null) 'to_ts': toTs,
          if (source != null && source.trim().isNotEmpty) 'source': source.trim(),
          'limit': limit,
        },
      );
      final list = (res.data as List).cast<dynamic>();
      return list.map((e) => FxSpotTickRead.fromJson(e as Map<String, dynamic>)).toList();
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao listar ticks FX spot');
    }
  }

  Future<FxSpotTickRead?> latestTick({
    required int farmId,
    String? source,
  }) async {
    try {
      final res = await api.dio.get(
        '/farms/$farmId/fx/spot/latest',
        queryParameters: {
          if (source != null && source.trim().isNotEmpty) 'source': source.trim(),
        },
      );
      if (res.data == null) return null;
      return FxSpotTickRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao carregar último tick FX spot');
    }
  }

  ApiException _asApiException(Object e, {required String fallback}) {
    if (e is ApiException) return e;
    return ApiException(message: fallback, details: e.toString());
  }
}
