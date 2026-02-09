// lib/data/repositories/alerts_repository.dart
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/alerts/alert_event_read.dart';
import '../models/alerts/alert_event_update.dart';
import '../models/alerts/alert_rule_create.dart';
import '../models/alerts/alert_rule_read.dart';
import '../models/alerts/alert_rule_update.dart';

class AlertsRepository {
  final ApiClient api;
  AlertsRepository(this.api);

  // ---------- RULES ----------
  Future<AlertRuleRead> createRule({
    required int farmId,
    required AlertRuleCreate payload,
  }) async {
    try {
      final res = await api.dio.post(
        '/farms/$farmId/alerts/rules',
        data: payload.toJson(),
      );
      return AlertRuleRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao criar regra de alerta');
    }
  }

  Future<List<AlertRuleRead>> listRules({
    required int farmId,
    bool? ativo,
    String? tipo,
    String? q,
  }) async {
    try {
      final res = await api.dio.get(
        '/farms/$farmId/alerts/rules',
        queryParameters: {
          if (ativo != null) 'ativo': ativo,
          if (tipo != null && tipo.trim().isNotEmpty) 'tipo': tipo.trim(),
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        },
      );
      final list = (res.data as List).cast<dynamic>();
      return list.map((e) => AlertRuleRead.fromJson(e as Map<String, dynamic>)).toList();
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao listar regras de alerta');
    }
  }

  Future<AlertRuleRead> getRule({
    required int farmId,
    required int ruleId,
  }) async {
    try {
      final res = await api.dio.get('/farms/$farmId/alerts/rules/$ruleId');
      return AlertRuleRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao obter regra de alerta');
    }
  }

  Future<AlertRuleRead> updateRule({
    required int farmId,
    required int ruleId,
    required AlertRuleUpdate payload,
  }) async {
    try {
      final res = await api.dio.patch(
        '/farms/$farmId/alerts/rules/$ruleId',
        data: payload.toJson(),
      );
      return AlertRuleRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao atualizar regra de alerta');
    }
  }

  // ---------- EVENTS ----------
  Future<List<AlertEventRead>> listEvents({
    required int farmId,
    bool? read,
    String? severity,
    int limit = 200,
  }) async {
    try {
      final res = await api.dio.get(
        '/farms/$farmId/alerts/events',
        queryParameters: {
          if (read != null) 'read': read,
          if (severity != null && severity.trim().isNotEmpty) 'severity': severity.trim(),
          'limit': limit,
        },
      );
      final list = (res.data as List).cast<dynamic>();
      return list.map((e) => AlertEventRead.fromJson(e as Map<String, dynamic>)).toList();
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao listar eventos de alerta');
    }
  }

  Future<AlertEventRead> getEvent({
    required int farmId,
    required int eventId,
  }) async {
    try {
      final res = await api.dio.get('/farms/$farmId/alerts/events/$eventId');
      return AlertEventRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao obter evento de alerta');
    }
  }

  Future<AlertEventRead> updateEvent({
    required int farmId,
    required int eventId,
    required AlertEventUpdate payload,
  }) async {
    try {
      final res = await api.dio.patch(
        '/farms/$farmId/alerts/events/$eventId',
        data: payload.toJson(),
      );
      return AlertEventRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao atualizar evento de alerta');
    }
  }

  ApiException _asApiException(Object e, {required String fallback}) {
    if (e is ApiException) return e;
    return ApiException(message: fallback, details: e.toString());
  }
}
