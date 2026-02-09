// lib/viewmodels/contracts/contracts_vm.dart
import '../../core/api/api_exception.dart';
import '../../core/auth/farm_context.dart';
import '../../data/models/contracts/contract_create.dart';
import '../../data/models/contracts/contract_read.dart';
import '../../data/repositories/contracts_repository.dart';
import '../base_view_model.dart';

class ContractsVM extends BaseViewModel {
  final ContractsRepository _repo;
  final FarmContext _farmContext;

  List<ContractRead> rows = [];

  String? filterStatus;
  String? filterProduto;
  String? filterTipoPrecificacao;
  DateTime? entregaFrom;
  DateTime? entregaTo;
  String? q;

  ContractsVM(this._repo, this._farmContext);

  String _date(DateTime d) => d.toIso8601String().substring(0, 10);

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
        status: filterStatus,
        produto: filterProduto,
        tipoPrecificacao: filterTipoPrecificacao,
        entregaFrom: entregaFrom != null ? _date(entregaFrom!) : null,
        entregaTo: entregaTo != null ? _date(entregaTo!) : null,
        q: q,
      );
    } on ApiException catch (e) {
      setError(e);
      rows = [];
    } finally {
      setLoading(false);
    }
  }

  Future<bool> create(ContractCreate payload) async {
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
}
