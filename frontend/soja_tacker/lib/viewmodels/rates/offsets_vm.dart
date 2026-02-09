// lib/viewmodels/rates/offsets_vm.dart
import '../../core/api/api_exception.dart';
import '../../core/auth/farm_context.dart';
import '../../data/models/rates/offset_create.dart';
import '../../data/models/rates/offset_read.dart';
import '../../data/repositories/rates_repository.dart';
import '../base_view_model.dart';

class OffsetsVM extends BaseViewModel {
  final RatesRepository _repo;
  final FarmContext _farmContext;

  OffsetRead? latest;
  List<OffsetRead> history = [];

  OffsetsVM(this._repo, this._farmContext);

  Future<void> load({int limit = 200}) async {
    final farmId = _farmContext.farmId;
    if (farmId == null) {
      latest = null;
      history = [];
      notifyListeners();
      return;
    }

    setLoading(true);
    clearError();
    try {
      latest = await _repo.latestOffset(farmId: farmId);
      history = await _repo.offsetHistory(farmId: farmId, limit: limit);
    } on ApiException catch (e) {
      setError(e);
      latest = null;
      history = [];
    } finally {
      setLoading(false);
    }
  }

  Future<bool> create({
    required double offsetValue,
    String? note,
  }) async {
    final farmId = _farmContext.farmId;
    if (farmId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _repo.createOffset(
        farmId: farmId,
        payload: OffsetCreate(offsetValue: offsetValue, note: note),
      );
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
