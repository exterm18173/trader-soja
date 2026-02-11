import '../../core/api/api_exception.dart';
import '../../core/auth/farm_context.dart';
import '../../data/models/contracts/contract_create.dart';
import '../../data/models/contracts/contract_read.dart';
import '../../data/models/contracts/contract_update.dart';
import '../../data/repositories/contracts_repository.dart';
import '../base_view_model.dart';

class ContractsVM extends BaseViewModel {
  final ContractsRepository _repo;
  final FarmContext _farmContext;

  List<ContractRead> rows = [];

  // detail cache
  final Map<int, ContractRead> byId = {};

  String? filterStatus;
  String? filterProduto;
  String? filterTipoPrecificacao;
  DateTime? entregaFrom;
  DateTime? entregaTo;
  String? q;

  ContractsVM(this._repo, this._farmContext);

  String _date(DateTime d) => d.toIso8601String().substring(0, 10);

  int? get _farmId => _farmContext.farmId;

  Future<void> load() async {
    final farmId = _farmId;
    if (farmId == null) {
      rows = [];
      byId.clear();
      notifyListeners();
      return;
    }

    setLoading(true);
    clearError();
    try {
      rows = await _repo.list(
        farmId: farmId,
        status: filterStatus,
        produto: filterProduto,
        tipoPrecificacao: filterTipoPrecificacao,
        entregaFrom: entregaFrom != null ? _date(entregaFrom!) : null,
        entregaTo: entregaTo != null ? _date(entregaTo!) : null,
        q: q,
      );

      for (final c in rows) {
        byId[c.id] = c;
      }
    } on ApiException catch (e) {
      setError(e);
      rows = [];
      byId.clear();
    } finally {
      setLoading(false);
    }
  }

  Future<ContractRead?> getOne(int contractId, {bool force = false}) async {
    final farmId = _farmId;
    if (farmId == null) return null;

    if (!force && byId.containsKey(contractId)) return byId[contractId];

    setLoading(true);
    clearError();
    try {
      final c = await _repo.get(farmId: farmId, contractId: contractId);
      byId[contractId] = c;

      final idx = rows.indexWhere((e) => e.id == contractId);
      if (idx >= 0) rows[idx] = c;

      notifyListeners();
      return c;
    } on ApiException catch (e) {
      setError(e);
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> create(ContractCreate payload) async {
    final farmId = _farmId;
    if (farmId == null) return false;

    setLoading(true);
    clearError();
    try {
      final created = await _repo.create(farmId: farmId, payload: payload);
      byId[created.id] = created;
      await load();
      return true;
    } on ApiException catch (e) {
      setError(e);
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> update(int contractId, ContractUpdate payload) async {
    final farmId = _farmId;
    if (farmId == null) return false;

    setLoading(true);
    clearError();
    try {
      final updated = await _repo.update(
        farmId: farmId,
        contractId: contractId,
        payload: payload,
      );
      byId[contractId] = updated;

      final idx = rows.indexWhere((e) => e.id == contractId);
      if (idx >= 0) rows[idx] = updated;

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      setError(e);
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> delete(int contractId) async {
    final farmId = _farmId;
    if (farmId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _repo.delete(farmId: farmId, contractId: contractId);
      byId.remove(contractId);
      rows.removeWhere((e) => e.id == contractId);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      setError(e);
      return false;
    } finally {
      setLoading(false);
    }
  }
}
