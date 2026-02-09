// lib/viewmodels/farms/farms_vm.dart
import '../../core/api/api_exception.dart';
import '../../core/auth/farm_context.dart';
import '../../data/models/farms/farm_create.dart';
import '../../data/models/farms/farm_membership_read.dart';
import '../../data/models/farms/farm_update.dart';
import '../../data/repositories/farms_repository.dart';
import '../base_view_model.dart';

class FarmsVM extends BaseViewModel {
  final FarmsRepository _repo;
  final FarmContext _farmContext;

  List<FarmMembershipRead> memberships = [];

  FarmsVM(this._repo, this._farmContext);

  int? get selectedFarmId => _farmContext.farmId;

  Future<void> load() async {
    setLoading(true);
    clearError();
    try {
      memberships = await _repo.minhasFazendas();
    } on ApiException catch (e) {
      setError(e);
      memberships = [];
    } finally {
      setLoading(false);
    }
  }

  Future<void> selectFarm(int farmId) async {
    await _farmContext.setFarm(farmId);
    notifyListeners();
  }

  Future<bool> createFarm({required String nome}) async {
    setLoading(true);
    clearError();
    try {
      await _repo.criar(FarmCreate(nome: nome));
      await load();
      return true;
    } on ApiException catch (e) {
      setError(e);
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateFarm({
    required int farmId,
    String? nome,
    bool? ativo,
  }) async {
    setLoading(true);
    clearError();
    try {
      await _repo.atualizar(farmId, FarmUpdate(nome: nome, ativo: ativo));
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
