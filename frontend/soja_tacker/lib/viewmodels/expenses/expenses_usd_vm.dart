// lib/viewmodels/expenses/expenses_usd_vm.dart
import '../../core/api/api_exception.dart';
import '../../core/auth/farm_context.dart';
import '../../data/models/expenses/expense_usd_create.dart';
import '../../data/models/expenses/expense_usd_read.dart';
import '../../data/models/expenses/expense_usd_update.dart';
import '../../data/repositories/expenses_usd_repository.dart';
import '../base_view_model.dart';

class ExpensesUsdVM extends BaseViewModel {
  final ExpensesUsdRepository _repo;
  final FarmContext _farmContext;

  List<ExpenseUsdRead> rows = [];

  DateTime? fromMes;
  DateTime? toMes;
  String? categoria;
  int limit = 1000;

  ExpensesUsdVM(this._repo, this._farmContext);

  void setFilters({
    DateTime? fromMes,
    DateTime? toMes,
    String? categoria,
    int? limit,
  }) {
    this.fromMes = fromMes;
    this.toMes = toMes;
    this.categoria = categoria;
    if (limit != null) this.limit = limit;
    notifyListeners();
  }

  Future<void> load() async {
    final farmId = _farmContext.farmId;
    if (farmId == null) {
      rows = [];
      notifyListeners();
      return;
    }

    setLoading(true);
    clearError();
    try {
      rows = await _repo.list(
        farmId: farmId,
        fromMes: fromMes,
        toMes: toMes,
        categoria: categoria,
        limit: limit,
      );
    } on ApiException catch (e) {
      setError(e);
      rows = [];
    } finally {
      setLoading(false);
    }
  }

  Future<bool> create(ExpenseUsdCreate payload) async {
    final farmId = _farmContext.farmId;
    if (farmId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _repo.create(farmId: farmId, payload: payload);
      await load();
      return true;
    } on ApiException catch (e) {
      setError(e);
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> update(int expenseId, ExpenseUsdUpdate payload) async {
    final farmId = _farmContext.farmId;
    if (farmId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _repo.update(farmId: farmId, expenseId: expenseId, payload: payload);
      await load();
      return true;
    } on ApiException catch (e) {
      setError(e);
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> delete(int expenseId) async {
    final farmId = _farmContext.farmId;
    if (farmId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _repo.delete(farmId: farmId, expenseId: expenseId);
      await load();
      return true;
    } on ApiException catch (e) {
      setError(e);
      return false;
    } finally {
      setLoading(false);
    }
  }

  double get totalUsd => rows.fold(0.0, (acc, r) => acc + r.valorUsd);
}
