// lib/data/repositories/contracts_repository.dart
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/contracts/contract_create.dart';
import '../models/contracts/contract_read.dart';
import '../models/contracts/contract_update.dart';

class ContractsRepository {
  final ApiClient api;
  ContractsRepository(this.api);

  Future<ContractRead> create({
    required int farmId,
    required ContractCreate payload,
  }) async {
    try {
      final res = await api.dio.post(
        '/farms/$farmId/contracts',
        data: payload.toJson(),
      );
      return ContractRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao criar contrato');
    }
  }

  Future<List<ContractRead>> list({
    required int farmId,
    String? status,
    String? produto,
    String? tipoPrecificacao,
    String? entregaFrom, // yyyy-mm-dd
    String? entregaTo, // yyyy-mm-dd
    String? q,
  }) async {
    try {
      final res = await api.dio.get(
        '/farms/$farmId/contracts',
        queryParameters: {
          if (status != null) 'status': status,
          if (produto != null) 'produto': produto,
          if (tipoPrecificacao != null) 'tipo_precificacao': tipoPrecificacao,
          if (entregaFrom != null) 'entrega_from': entregaFrom,
          if (entregaTo != null) 'entrega_to': entregaTo,
          if (q != null) 'q': q,
        },
      );
      final list = (res.data as List).cast<dynamic>();
      return list.map((e) => ContractRead.fromJson(e as Map<String, dynamic>)).toList();
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao listar contratos');
    }
  }

  Future<ContractRead> getById({
    required int farmId,
    required int contractId,
  }) async {
    try {
      final res = await api.dio.get('/farms/$farmId/contracts/$contractId');
      return ContractRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao obter contrato');
    }
  }

  Future<ContractRead> update({
    required int farmId,
    required int contractId,
    required ContractUpdate payload,
  }) async {
    try {
      final res = await api.dio.patch(
        '/farms/$farmId/contracts/$contractId',
        data: payload.toJson(),
      );
      return ContractRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao atualizar contrato');
    }
  }

  ApiException _asApiException(Object e, {required String fallback}) {
    if (e is ApiException) return e;
    return ApiException(message: fallback, details: e.toString());
  }
}
