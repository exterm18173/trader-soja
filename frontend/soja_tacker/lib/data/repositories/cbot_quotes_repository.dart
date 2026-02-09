// lib/data/repositories/cbot_quotes_repository.dart
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/cbot/cbot_quote_read.dart';

class CbotQuotesRepository {
  final ApiClient api;
  CbotQuotesRepository(this.api);

  Future<CbotQuoteRead?> latest({
    required int farmId,
    String symbol = 'ZS=F',
    int? sourceId,
  }) async {
    try {
      final res = await api.dio.get(
        '/farms/$farmId/cbot/quotes/latest',
        queryParameters: {
          'symbol': symbol,
          if (sourceId != null) 'source_id': sourceId,
        },
      );
      if (res.data == null) return null;
      return CbotQuoteRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao obter latest CBOT');
    }
  }

  Future<List<CbotQuoteRead>> list({
    required int farmId,
    String? symbol,
    int? sourceId,
    String? fromTs,
    String? toTs,
    int limit = 500,
  }) async {
    try {
      final res = await api.dio.get(
        '/farms/$farmId/cbot/quotes',
        queryParameters: {
          if (symbol != null) 'symbol': symbol,
          if (sourceId != null) 'source_id': sourceId,
          if (fromTs != null) 'from_ts': fromTs,
          if (toTs != null) 'to_ts': toTs,
          'limit': limit,
        },
      );
      final list = (res.data as List).cast<dynamic>();
      return list.map((e) => CbotQuoteRead.fromJson(e as Map<String, dynamic>)).toList();
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao listar CBOT Quotes');
    }
  }

  Future<CbotQuoteRead> getById({
    required int farmId,
    required int quoteId,
  }) async {
    try {
      final res = await api.dio.get('/farms/$farmId/cbot/quotes/$quoteId');
      return CbotQuoteRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao obter CBOT Quote');
    }
  }

  ApiException _asApiException(Object e, {required String fallback}) {
    if (e is ApiException) return e;
    return ApiException(message: fallback, details: e.toString());
  }
}
