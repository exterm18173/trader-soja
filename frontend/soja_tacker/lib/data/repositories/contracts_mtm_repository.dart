import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/contracts_mtm/contracts_mtm_response.dart';

class ContractsMtmRepository {
  final ApiClient api;
  ContractsMtmRepository(this.api);

  Future<ContractsMtmResponse> mtm({
    required int farmId,
    String mode = 'both', // system|manual|both
    bool onlyOpen = true,
    String? refMes, // YYYY-MM-01 (opcional)
    String defaultSymbol = 'ZS=F',
    int limit = 200,
  }) async {
    try {
      final res = await api.dio.get(
        '/farms/$farmId/contracts-mtm',
        queryParameters: {
          'mode': mode,
          'only_open': onlyOpen,
          if (refMes != null) 'ref_mes': refMes,
          'default_symbol': defaultSymbol,
          'limit': limit,
        },
      );
      return ContractsMtmResponse.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao carregar MTM de contratos');
    }
  }

  ApiException _asApiException(Object e, {required String fallback}) {
    if (e is ApiException) return e;
    return ApiException(message: fallback, details: e.toString());
  }
}
