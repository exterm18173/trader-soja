// lib/data/repositories/rates_repository.dart
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/rates/interest_rate_create.dart';
import '../models/rates/interest_rate_read.dart';
import '../models/rates/interest_rate_update.dart';
import '../models/rates/interest_rate_upsert.dart';
import '../models/rates/offset_create.dart';
import '../models/rates/offset_read.dart';

class RatesRepository {
  final ApiClient api;
  RatesRepository(this.api);

  // ---- Interest ----
  Future<InterestRateRead> createInterest({
    required int farmId,
    required InterestRateCreate payload,
  }) async {
    try {
      final res = await api.dio.post(
        '/farms/$farmId/rates/interest',
        data: payload.toJson(),
      );
      return InterestRateRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao criar juros');
    }
  }

  Future<List<InterestRateRead>> listInterest({
    required int farmId,
    String? from, // yyyy-mm-dd
    String? to,   // yyyy-mm-dd
  }) async {
    try {
      final res = await api.dio.get(
        '/farms/$farmId/rates/interest',
        queryParameters: {
          if (from != null) 'from': from,
          if (to != null) 'to': to,
        },
      );
      final list = (res.data as List).cast<dynamic>();
      return list.map((e) => InterestRateRead.fromJson(e as Map<String, dynamic>)).toList();
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao listar juros');
    }
  }

  Future<InterestRateRead?> latestInterest({required int farmId}) async {
    try {
      final res = await api.dio.get('/farms/$farmId/rates/interest/latest');
      if (res.data == null) return null;
      return InterestRateRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao carregar último juros');
    }
  }

  Future<InterestRateRead> updateInterest({
    required int farmId,
    required int rowId,
    required InterestRateUpdate payload,
  }) async {
    try {
      final res = await api.dio.patch(
        '/farms/$farmId/rates/interest/$rowId',
        data: payload.toJson(),
      );
      return InterestRateRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao atualizar juros');
    }
  }

  Future<InterestRateRead> upsertInterest({
    required int farmId,
    required DateTime rateDate,
    required InterestRateUpsert payload,
  }) async {
    final d = rateDate.toIso8601String().substring(0, 10);
    try {
      final res = await api.dio.put(
        '/farms/$farmId/rates/interest/$d',
        data: payload.toJson(),
      );
      return InterestRateRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao salvar juros');
    }
  }

  // ---- Offset ----
  Future<OffsetRead> createOffset({
    required int farmId,
    required OffsetCreate payload,
  }) async {
    try {
      final res = await api.dio.post(
        '/farms/$farmId/rates/offset',
        data: payload.toJson(),
      );
      return OffsetRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao criar offset');
    }
  }

  Future<OffsetRead?> latestOffset({required int farmId}) async {
    try {
      final res = await api.dio.get('/farms/$farmId/rates/offset/latest');
      if (res.data == null) return null;
      return OffsetRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao carregar último offset');
    }
  }

  Future<List<OffsetRead>> offsetHistory({
    required int farmId,
    int limit = 200,
  }) async {
    try {
      final res = await api.dio.get(
        '/farms/$farmId/rates/offset/history',
        queryParameters: {'limit': limit},
      );
      final list = (res.data as List).cast<dynamic>();
      return list.map((e) => OffsetRead.fromJson(e as Map<String, dynamic>)).toList();
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao listar histórico de offset');
    }
  }

  ApiException _asApiException(Object e, {required String fallback}) {
    if (e is ApiException) return e;
    return ApiException(message: fallback, details: e.toString());
  }
}
