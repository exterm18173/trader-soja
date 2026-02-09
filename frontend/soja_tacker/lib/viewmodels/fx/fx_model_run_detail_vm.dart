// lib/viewmodels/fx/fx_model_run_detail_vm.dart
import '../../core/api/api_exception.dart';
import '../../core/auth/farm_context.dart';
import '../../data/models/fx/fx_model_run_with_points_read.dart';
import '../../data/repositories/fx_model_repository.dart';
import '../base_view_model.dart';

class FxModelRunDetailVM extends BaseViewModel {
  final FxModelRepository _repo;
  final FarmContext _farmContext;

  int? runId;
  FxModelRunWithPointsRead? data;

  FxModelRunDetailVM(this._repo, this._farmContext);

  void init(int id) => runId = id;

  Future<void> load({bool includePoints = true}) async {
    final farmId = _farmContext.farmId;
    if (farmId == null || runId == null) {
      data = null;
      notifyListeners();
      return;
    }

    setLoading(true);
    clearError();
    try {
      data = await _repo.getRun(
        farmId: farmId,
        runId: runId!,
        includePoints: includePoints,
      );
    } on ApiException catch (e) {
      setError(e);
      data = null;
    } finally {
      setLoading(false);
    }
  }
}
