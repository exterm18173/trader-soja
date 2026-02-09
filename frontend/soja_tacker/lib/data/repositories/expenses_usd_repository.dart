// lib/data/repositories/expenses_usd_repository.dart
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/expenses/expense_usd_create.dart';
import '../models/expenses/expense_usd_read.dart';
import '../models/expenses/expense_usd_update.dart';

class ExpensesUsdRepository {
  final ApiClient api;
  ExpensesUsdRepository(this.api);

  Future<ExpenseUsdRead> create({
    required int farmId,
    required ExpenseUsdCreate payload,
  }) async {
    try {
      final res = await api.dio.post(
        '/farms/$farmId/expenses-usd',
        data: payload.toJson(),
      );
      return ExpenseUsdRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao criar despesa USD');
    }
  }

  Future<List<ExpenseUsdRead>> list({
    required int farmId,
    DateTime? fromMes,
    DateTime? toMes,
    String? categoria,
    int limit = 1000,
  }) async {
    try {
      final res = await api.dio.get(
        '/farms/$farmId/expenses-usd',
        queryParameters: {
          if (fromMes != null) 'from_mes': fromMes.toIso8601String().substring(0, 10),
          if (toMes != null) 'to_mes': toMes.toIso8601String().substring(0, 10),
          if (categoria != null && categoria.trim().isNotEmpty) 'categoria': categoria.trim(),
          'limit': limit,
        },
      );

      final list = (res.data as List).cast<dynamic>();
      return list.map((e) => ExpenseUsdRead.fromJson(e as Map<String, dynamic>)).toList();
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao listar despesas USD');
    }
  }

  Future<ExpenseUsdRead> getById({
    required int farmId,
    required int expenseId,
  }) async {
    try {
      final res = await api.dio.get('/farms/$farmId/expenses-usd/$expenseId');
      return ExpenseUsdRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao obter despesa USD');
    }
  }

  Future<ExpenseUsdRead> update({
    required int farmId,
    required int expenseId,
    required ExpenseUsdUpdate payload,
  }) async {
    try {
      final res = await api.dio.patch(
        '/farms/$farmId/expenses-usd/$expenseId',
        data: payload.toJson(),
      );
      return ExpenseUsdRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao atualizar despesa USD');
    }
  }

  Future<void> delete({
    required int farmId,
    required int expenseId,
  }) async {
    try {
      await api.dio.delete('/farms/$farmId/expenses-usd/$expenseId');
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao excluir despesa USD');
    }
  }

  ApiException _asApiException(Object e, {required String fallback}) {
    if (e is ApiException) return e;
    return ApiException(message: fallback, details: e.toString());
  }
}
