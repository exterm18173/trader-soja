// lib/viewmodels/fx/fx_model_runs_vm.dart
import '../../core/api/api_exception.dart';
import '../../core/auth/farm_context.dart';
import '../../data/models/fx/fx_model_run_read.dart';
import '../../data/repositories/fx_model_repository.dart';
import '../base_view_model.dart';

class FxModelRunsVM extends BaseViewModel {
  final FxModelRepository _repo;
  final FarmContext _farmContext;

  List<FxModelRunRead> rows = [];
  FxModelRunRead? latest;

  int limit = 50;

  FxModelRunsVM(this._repo, this._farmContext);

  Future<void> load({int? limit}) async {
    final farmId = _farmContext.farmId;
    if (farmId == null) {
      rows = [];
      latest = null;
      notifyListeners();
      return;
    }

    this.limit = limit ?? this.limit;

    setLoading(true);
    clearError();
    try {
      latest = await _repo.latestRun(farmId: farmId);
      rows = await _repo.listRuns(farmId: farmId, limit: this.limit);
    } on ApiException catch (e) {
      setError(e);
      rows = [];
      latest = null;
    } finally {
      setLoading(false);
    }
  }
}
