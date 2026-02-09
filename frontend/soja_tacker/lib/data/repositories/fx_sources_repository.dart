// lib/data/repositories/fx_sources_repository.dart
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/fx/fx_source_create.dart';
import '../models/fx/fx_source_read.dart';

class FxSourcesRepository {
  final ApiClient api;
  FxSourcesRepository(this.api);

  Future<List<FxSourceRead>> list({bool onlyActive = true}) async {
    try {
      final res = await api.dio.get(
        '/fx/sources',
        queryParameters: {'only_active': onlyActive},
      );
      final list = (res.data as List).cast<dynamic>();
      return list.map((e) => FxSourceRead.fromJson(e as Map<String, dynamic>)).toList();
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao listar fontes FX');
    }
  }

  Future<FxSourceRead> create(FxSourceCreate payload) async {
    try {
      final res = await api.dio.post('/fx/sources', data: payload.toJson());
      return FxSourceRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao criar fonte FX');
    }
  }

  ApiException _asApiException(Object e, {required String fallback}) {
    if (e is ApiException) return e;
    return ApiException(message: fallback, details: e.toString());
  }
}
