// lib/viewmodels/contracts/contract_detail_vm.dart
import '../../core/api/api_exception.dart';
import '../../core/auth/farm_context.dart';
import '../../data/models/contracts/contract_read.dart';
import '../../data/models/contracts/contract_update.dart';
import '../../data/repositories/contracts_repository.dart';
import '../base_view_model.dart';

class ContractDetailVM extends BaseViewModel {
  final ContractsRepository _repo;
  final FarmContext _farmContext;

  int? contractId;
  ContractRead? contract;

  ContractDetailVM(this._repo, this._farmContext);

  void init(int id) => contractId = id;

  Future<void> load() async {
    final farmId = _farmContext.farmId;
    if (farmId == null || contractId == null) {
      contract = null;
      notifyListeners();
      return;
    }

    setLoading(true);
    clearError();
    try {
      contract = await _repo.getById(farmId: farmId, contractId: contractId!);
    } on ApiException catch (e) {
      setError(e);
      contract = null;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> update(ContractUpdate payload) async {
    final farmId = _farmContext.farmId;
    if (farmId == null || contractId == null) return false;

    setLoading(true);
    clearError();
    try {
      contract = await _repo.update(
        farmId: farmId,
        contractId: contractId!,
        payload: payload,
      );
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
