// lib/viewmodels/hedges/hedges_vm.dart
import '../../core/api/api_exception.dart';
import '../../core/auth/farm_context.dart';
import '../../data/models/hedges/hedge_cbot_create.dart';
import '../../data/models/hedges/hedge_cbot_read.dart';
import '../../data/models/hedges/hedge_fx_create.dart';
import '../../data/models/hedges/hedge_fx_read.dart';
import '../../data/models/hedges/hedge_premium_create.dart';
import '../../data/models/hedges/hedge_premium_read.dart';
import '../../data/repositories/hedges_repository.dart';
import '../base_view_model.dart';

class HedgesVM extends BaseViewModel {
  final HedgesRepository _repo;
  final FarmContext _farmContext;

  int? contractId;

  List<HedgeCbotRead> cbot = [];
  List<HedgePremiumRead> premium = [];
  List<HedgeFxRead> fx = [];

  HedgesVM(this._repo, this._farmContext);

  void init(int contractId) => this.contractId = contractId;

  Future<void> loadAll() async {
    final farmId = _farmContext.farmId;
    if (farmId == null || contractId == null) {
      cbot = [];
      premium = [];
      fx = [];
      notifyListeners();
      return;
    }

    setLoading(true);
    clearError();
    try {
      final c = await _repo.listCbot(farmId: farmId, contractId: contractId!);
      final p = await _repo.listPremium(farmId: farmId, contractId: contractId!);
      final f = await _repo.listFx(farmId: farmId, contractId: contractId!);

      cbot = c;
      premium = p;
      fx = f;
    } on ApiException catch (e) {
      setError(e);
      cbot = [];
      premium = [];
      fx = [];
    } finally {
      setLoading(false);
    }
  }

  Future<bool> createCbot(HedgeCbotCreate payload) async {
    final farmId = _farmContext.farmId;
    if (farmId == null || contractId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _repo.createCbot(farmId: farmId, contractId: contractId!, payload: payload);
      await loadAll();
      return true;
    } on ApiException catch (e) {
      setError(e);
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> createPremium(HedgePremiumCreate payload) async {
    final farmId = _farmContext.farmId;
    if (farmId == null || contractId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _repo.createPremium(farmId: farmId, contractId: contractId!, payload: payload);
      await loadAll();
      return true;
    } on ApiException catch (e) {
      setError(e);
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> createFx(HedgeFxCreate payload) async {
    final farmId = _farmContext.farmId;
    if (farmId == null || contractId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _repo.createFx(farmId: farmId, contractId: contractId!, payload: payload);
      await loadAll();
      return true;
    } on ApiException catch (e) {
      setError(e);
      return false;
    } finally {
      setLoading(false);
    }
  }
}
