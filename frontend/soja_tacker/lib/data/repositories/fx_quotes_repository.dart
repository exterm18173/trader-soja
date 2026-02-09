// lib/data/repositories/fx_quotes_repository.dart
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/fx/fx_quote_create.dart';
import '../models/fx/fx_quote_with_check_read.dart';

class FxQuotesRepository {
  final ApiClient api;
  FxQuotesRepository(this.api);

  Future<FxQuoteWithCheckRead> create({
    required int farmId,
    required FxQuoteCreate payload,
  }) async {
    try {
      final res = await api.dio.post(
        '/farms/$farmId/fx/quotes',
        data: payload.toJson(),
      );
      return FxQuoteWithCheckRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao criar FX Quote');
    }
  }

  Future<List<FxQuoteWithCheckRead>> list({
    required int farmId,
    String? refMes, // yyyy-mm-dd
    int? sourceId,
    int limit = 200,
  }) async {
    try {
      final res = await api.dio.get(
        '/farms/$farmId/fx/quotes',
        queryParameters: {
          if (refMes != null) 'ref_mes': refMes,
          if (sourceId != null) 'source_id': sourceId,
          'limit': limit,
        },
      );
      final list = (res.data as List).cast<dynamic>();
      return list
          .map((e) => FxQuoteWithCheckRead.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao listar FX Quotes');
    }
  }

  Future<FxQuoteWithCheckRead> getById({
    required int farmId,
    required int quoteId,
  }) async {
    try {
      final res = await api.dio.get('/farms/$farmId/fx/quotes/$quoteId');
      return FxQuoteWithCheckRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao obter FX Quote');
    }
  }

  ApiException _asApiException(Object e, {required String fallback}) {
    if (e is ApiException) return e;
    return ApiException(message: fallback, details: e.toString());
  }
}
