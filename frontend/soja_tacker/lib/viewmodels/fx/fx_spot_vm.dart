// lib/viewmodels/fx/fx_spot_vm.dart
import '../../core/api/api_exception.dart';
import '../../core/auth/farm_context.dart';
import '../../data/models/fx/fx_spot_tick_create.dart';
import '../../data/models/fx/fx_spot_tick_read.dart';
import '../../data/repositories/fx_spot_repository.dart';
import '../base_view_model.dart';

class FxSpotVM extends BaseViewModel {
  final FxSpotRepository _repo;
  final FarmContext _farmContext;

  FxSpotTickRead? latest;
  List<FxSpotTickRead> rows = [];

  FxSpotVM(this._repo, this._farmContext);

  Future<void> load({String? source, int limit = 2000}) async {
    final farmId = _farmContext.farmId;
    if (farmId == null) {
      latest = null;
      rows = [];
      notifyListeners();
      return;
    }

    setLoading(true);
    clearError();
    try {
      latest = await _repo.latestTick(farmId: farmId, source: source);
      rows = await _repo.listTicks(farmId: farmId, source: source, limit: limit);
    } on ApiException catch (e) {
      setError(e);
      latest = null;
      rows = [];
    } finally {
      setLoading(false);
    }
  }

  Future<bool> create({
    required DateTime ts,
    required double price,
    String source = 'B3',
  }) async {
    final farmId = _farmContext.farmId;
    if (farmId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _repo.createTick(
        farmId: farmId,
        payload: FxSpotTickCreate(ts: ts, price: price, source: source),
      );
      await load(source: source);
      return true;
    } on ApiException catch (e) {
      setError(e);
      return false;
    } finally {
      setLoading(false);
    }
  }
}
