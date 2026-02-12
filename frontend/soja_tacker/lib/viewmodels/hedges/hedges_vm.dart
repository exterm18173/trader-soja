// lib/viewmodels/hedges/hedges_vm.dart
import '../../core/api/api_exception.dart';
import '../../core/auth/farm_context.dart';
import '../../data/models/contracts/contract_read.dart';
import '../../data/models/hedges/hedge_cbot_create.dart';
import '../../data/models/hedges/hedge_cbot_read.dart';
import '../../data/models/hedges/hedge_fx_create.dart';
import '../../data/models/hedges/hedge_fx_read.dart';
import '../../data/models/hedges/hedge_premium_create.dart';
import '../../data/models/hedges/hedge_premium_read.dart';
import '../../data/repositories/contracts_repository.dart';
import '../../data/repositories/hedges_repository.dart';
import '../base_view_model.dart';

class HedgesVM extends BaseViewModel {
  final HedgesRepository _hedgesRepo;
  final ContractsRepository _contractsRepo;
  final FarmContext _farmContext;

  HedgesVM(this._hedgesRepo, this._contractsRepo, this._farmContext);

  // ------- contrato selecionado -------
  List<ContractRead> contracts = [];
  ContractRead? selectedContract;

  int? get contractId => selectedContract?.id;

  // ------- hedges -------
  List<HedgeCbotRead> cbot = [];
  List<HedgePremiumRead> premium = [];
  List<HedgeFxRead> fx = [];

  // ------- carregar contratos -------
  Future<void> loadContracts({String? status}) async {
    final farmId = _farmContext.farmId;
    if (farmId == null) {
      contracts = [];
      selectedContract = null;
      _clearHedges();
      notifyListeners();
      return;
    }

    setLoading(true);
    clearError();
    try {
      // status opcional: "ABERTO" etc. (se quiser filtrar)
      final list = await _contractsRepo.list(farmId: farmId, status: status);
      contracts = list;

      // mantém seleção se ainda existir
      if (selectedContract != null) {
        final keep = contracts.where((c) => c.id == selectedContract!.id).toList();
        selectedContract = keep.isEmpty ? null : keep.first;
      }

      // se não tem seleção e tem itens, seleciona o primeiro
      selectedContract ??= (contracts.isNotEmpty ? contracts.first : null);

      // ao carregar contratos, se já tiver selecionado, carrega hedges
      if (selectedContract != null) {
        await loadAll();
      } else {
        _clearHedges();
      }
    } on ApiException catch (e) {
      setError(e);
      contracts = [];
      selectedContract = null;
      _clearHedges();
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  void selectContract(ContractRead? c) {
    selectedContract = c;
    _clearHedges();
    notifyListeners();
    if (selectedContract != null) {
      loadAll();
    }
  }

  void _clearHedges() {
    cbot = [];
    premium = [];
    fx = [];
  }

  // ------- hedges load -------
  Future<void> loadAll() async {
    final farmId = _farmContext.farmId;
    final cId = contractId;

    if (farmId == null || cId == null) {
      _clearHedges();
      notifyListeners();
      return;
    }

    setLoading(true);
    clearError();
    try {
      final results = await Future.wait([
        _hedgesRepo.listCbot(farmId: farmId, contractId: cId),
        _hedgesRepo.listPremium(farmId: farmId, contractId: cId),
        _hedgesRepo.listFx(farmId: farmId, contractId: cId),
      ]);

      cbot = results[0] as List<HedgeCbotRead>;
      premium = results[1] as List<HedgePremiumRead>;
      fx = results[2] as List<HedgeFxRead>;
    } on ApiException catch (e) {
      setError(e);
      _clearHedges();
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  // ------- creates -------
  Future<bool> createCbot(HedgeCbotCreate payload) async {
    final farmId = _farmContext.farmId;
    final cId = contractId;
    if (farmId == null || cId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _hedgesRepo.createCbot(farmId: farmId, contractId: cId, payload: payload);
      await loadAll();
      return true;
    } on ApiException catch (e) {
      setError(e);
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  Future<bool> createPremium(HedgePremiumCreate payload) async {
    final farmId = _farmContext.farmId;
    final cId = contractId;
    if (farmId == null || cId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _hedgesRepo.createPremium(farmId: farmId, contractId: cId, payload: payload);
      await loadAll();
      return true;
    } on ApiException catch (e) {
      setError(e);
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  Future<bool> createFx(HedgeFxCreate payload) async {
    final farmId = _farmContext.farmId;
    final cId = contractId;
    if (farmId == null || cId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _hedgesRepo.createFx(farmId: farmId, contractId: cId, payload: payload);
      await loadAll();
      return true;
    } on ApiException catch (e) {
      setError(e);
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  // ------- deletes -------
  Future<bool> deleteCbot(int hedgeId) async {
    final farmId = _farmContext.farmId;
    final cId = contractId;
    if (farmId == null || cId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _hedgesRepo.deleteCbot(farmId: farmId, contractId: cId, hedgeId: hedgeId);

      // IMPORTANTE: backend pode ter ajustado FX automaticamente
      await loadAll();
      return true;
    } on ApiException catch (e) {
      setError(e);
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  Future<bool> deletePremium(int hedgeId) async {
    final farmId = _farmContext.farmId;
    final cId = contractId;
    if (farmId == null || cId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _hedgesRepo.deletePremium(farmId: farmId, contractId: cId, hedgeId: hedgeId);

      // backend pode ter ajustado FX automaticamente
      await loadAll();
      return true;
    } on ApiException catch (e) {
      setError(e);
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  Future<bool> deleteFx(int hedgeId) async {
    final farmId = _farmContext.farmId;
    final cId = contractId;
    if (farmId == null || cId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _hedgesRepo.deleteFx(farmId: farmId, contractId: cId, hedgeId: hedgeId);
      await loadAll();
      return true;
    } on ApiException catch (e) {
      setError(e);
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }
}
