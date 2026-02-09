// lib/viewmodels/dashboard/usd_exposure_vm.dart
import '../../core/api/api_exception.dart';
import '../../core/auth/farm_context.dart';
import '../../data/models/dashboard/usd_exposure_row.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../base_view_model.dart';

class UsdExposureVM extends BaseViewModel {
  final DashboardRepository _repo;
  final FarmContext _farmContext;

  List<UsdExposureRow> rows = [];

  UsdExposureVM(this._repo, this._farmContext);

  Future<void> load({String? fromMes, String? toMes}) async {
    final farmId = _farmContext.farmId;
    if (farmId == null) {
      rows = [];
      notifyListeners();
      return;
    }

    setLoading(true);
    clearError();
    try {
      final res = await _repo.usdExposure(
        farmId: farmId,
        fromMes: fromMes,
        toMes: toMes,
      );
      rows = res.rows;
    } on ApiException catch (e) {
      setError(e);
      rows = [];
    } finally {
      setLoading(false);
    }
  }
}
