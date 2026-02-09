// lib/data/repositories/cbot_sources_repository.dart
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/cbot/cbot_source_create.dart';
import '../models/cbot/cbot_source_read.dart';

class CbotSourcesRepository {
  final ApiClient api;
  CbotSourcesRepository(this.api);

  Future<List<CbotSourceRead>> list({bool onlyActive = true}) async {
    try {
      final res = await api.dio.get(
        '/cbot/sources',
        queryParameters: {'only_active': onlyActive},
      );
      final list = (res.data as List).cast<dynamic>();
      return list.map((e) => CbotSourceRead.fromJson(e as Map<String, dynamic>)).toList();
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao listar CBOT Sources');
    }
  }

  Future<CbotSourceRead> create(CbotSourceCreate payload) async {
    try {
      final res = await api.dio.post('/cbot/sources', data: payload.toJson());
      return CbotSourceRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao criar CBOT Source');
    }
  }

  ApiException _asApiException(Object e, {required String fallback}) {
    if (e is ApiException) return e;
    return ApiException(message: fallback, details: e.toString());
  }
}
