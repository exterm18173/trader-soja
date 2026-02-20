// lib/data/repositories/contracts_mtm_repository.dart
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/contracts_mtm/contracts_mtm_response.dart';

class ContractsMtmRepository {
  final ApiClient api;
  ContractsMtmRepository(this.api);

  /// refMes deve ser "YYYY-MM-30" (padrão do backend).
  Future<ContractsMtmResponse> mtm({
    required int farmId,
    String mode = 'both', // system|manual|both
    bool onlyOpen = true,
    String? refMes, // YYYY-MM-30 (opcional) -> força FX
    String defaultSymbol = 'AUTO',
    int limit = 200,

    // ✅ filtros de trava (backend)
    String? lockTypes,  // "cbot,premium,fx"
    String? lockStates, // "locked,open"

    // ✅ NOVO: contratos sem travas (FIXO_BRL)
    bool noLocks = false,
  }) async {
    try {
      final qp = <String, dynamic>{
        'mode': mode,
        'only_open': onlyOpen,
        'default_symbol': defaultSymbol,
        'limit': limit,
      };

      final rm = refMes?.trim();
      if (rm != null && rm.isNotEmpty) {
        qp['ref_mes'] = rm;
      }

      // ✅ novo param
      if (noLocks) {
        qp['no_locks'] = true;
      } else {
        final lt = (lockTypes ?? '').trim();
        final ls = (lockStates ?? '').trim();

        // ✅ envia filtros apenas quando tiver tipo+estado
        if (lt.isNotEmpty && ls.isNotEmpty) {
          qp['lock_types'] = lt;
          qp['lock_states'] = ls;
        }
      }

      final res = await api.dio.get(
        '/farms/$farmId/contracts-mtm',
        queryParameters: qp,
      );

      return ContractsMtmResponse.fromJson((res.data as Map).cast<String, dynamic>());
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao carregar MTM de contratos');
    }
  }

  ApiException _asApiException(Object e, {required String fallback}) {
    if (e is ApiException) return e;
    return ApiException(message: fallback, details: e.toString());
  }
}
