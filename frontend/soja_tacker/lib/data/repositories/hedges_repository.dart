// lib/data/repositories/hedges_repository.dart
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/hedges/hedge_cbot_create.dart';
import '../models/hedges/hedge_cbot_read.dart';
import '../models/hedges/hedge_premium_create.dart';
import '../models/hedges/hedge_premium_read.dart';
import '../models/hedges/hedge_fx_create.dart';
import '../models/hedges/hedge_fx_read.dart';

class HedgesRepository {
  final ApiClient api;
  HedgesRepository(this.api);

  // ---------- CBOT ----------
  Future<HedgeCbotRead> createCbot({
    required int farmId,
    required int contractId,
    required HedgeCbotCreate payload,
  }) async {
    try {
      final res = await api.dio.post(
        '/farms/$farmId/contracts/$contractId/hedges/cbot',
        data: payload.toJson(),
      );
      return HedgeCbotRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao criar hedge CBOT');
    }
  }

  Future<List<HedgeCbotRead>> listCbot({
    required int farmId,
    required int contractId,
  }) async {
    try {
      final res = await api.dio.get(
        '/farms/$farmId/contracts/$contractId/hedges/cbot',
      );
      final list = (res.data as List).cast<dynamic>();
      return list.map((e) => HedgeCbotRead.fromJson(e as Map<String, dynamic>)).toList();
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao listar hedges CBOT');
    }
  }

  // ---------- PREMIUM ----------
  Future<HedgePremiumRead> createPremium({
    required int farmId,
    required int contractId,
    required HedgePremiumCreate payload,
  }) async {
    try {
      final res = await api.dio.post(
        '/farms/$farmId/contracts/$contractId/hedges/premium',
        data: payload.toJson(),
      );
      return HedgePremiumRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao criar hedge Premium');
    }
  }

  Future<List<HedgePremiumRead>> listPremium({
    required int farmId,
    required int contractId,
  }) async {
    try {
      final res = await api.dio.get(
        '/farms/$farmId/contracts/$contractId/hedges/premium',
      );
      final list = (res.data as List).cast<dynamic>();
      return list.map((e) => HedgePremiumRead.fromJson(e as Map<String, dynamic>)).toList();
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao listar hedges Premium');
    }
  }

  // ---------- FX ----------
  Future<HedgeFxRead> createFx({
    required int farmId,
    required int contractId,
    required HedgeFxCreate payload,
  }) async {
    try {
      final res = await api.dio.post(
        '/farms/$farmId/contracts/$contractId/hedges/fx',
        data: payload.toJson(),
      );
      return HedgeFxRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao criar hedge FX');
    }
  }

  Future<List<HedgeFxRead>> listFx({
    required int farmId,
    required int contractId,
  }) async {
    try {
      final res = await api.dio.get(
        '/farms/$farmId/contracts/$contractId/hedges/fx',
      );
      final list = (res.data as List).cast<dynamic>();
      return list.map((e) => HedgeFxRead.fromJson(e as Map<String, dynamic>)).toList();
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao listar hedges FX');
    }
  }

  ApiException _asApiException(Object e, {required String fallback}) {
    if (e is ApiException) return e;
    return ApiException(message: fallback, details: e.toString());
  }
}
