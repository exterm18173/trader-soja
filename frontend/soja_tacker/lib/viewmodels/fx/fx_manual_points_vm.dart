// lib/viewmodels/fx/fx_manual_points_vm.dart
import '../../core/api/api_exception.dart';
import '../../core/auth/farm_context.dart';
import '../../data/models/fx/fx_manual_point_create.dart';
import '../../data/models/fx/fx_manual_point_read.dart';
import '../../data/models/fx/fx_manual_point_update.dart';
import '../../data/repositories/fx_manual_points_repository.dart';
import '../base_view_model.dart';

class FxManualPointsVM extends BaseViewModel {
  final FxManualPointsRepository _repo;
  final FarmContext _farmContext;

  List<FxManualPointRead> rows = [];

  int? filterSourceId;
  DateTime? filterRefMes; // date
  int limit = 2000;

  FxManualPointsVM(this._repo, this._farmContext);

  String _date(DateTime d) => d.toIso8601String().substring(0, 10);

  Future<void> load({
    int? sourceId,
    DateTime? refMes,
    int? limit,
  }) async {
    final farmId = _farmContext.farmId;
    if (farmId == null) {
      rows = [];
      notifyListeners();
      return;
    }

    filterSourceId = sourceId ?? filterSourceId;
    filterRefMes = refMes ?? filterRefMes;
    this.limit = limit ?? this.limit;

    setLoading(true);
    clearError();
    try {
      rows = await _repo.list(
        farmId: farmId,
        sourceId: filterSourceId,
        refMes: filterRefMes != null ? _date(filterRefMes!) : null,
        limit: this.limit,
      );
    } on ApiException catch (e) {
      setError(e);
      rows = [];
    } finally {
      setLoading(false);
    }
  }

  Future<bool> create({
    required int sourceId,
    required DateTime capturedAt,
    required DateTime refMes,
    required double fx,
  }) async {
    final farmId = _farmContext.farmId;
    if (farmId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _repo.create(
        farmId: farmId,
        payload: FxManualPointCreate(
          sourceId: sourceId,
          capturedAt: capturedAt,
          refMes: refMes,
          fx: fx,
        ),
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

  Future<bool> update({
    required int pointId,
    DateTime? capturedAt,
    DateTime? refMes,
    double? fx,
  }) async {
    final farmId = _farmContext.farmId;
    if (farmId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _repo.update(
        farmId: farmId,
        pointId: pointId,
        payload: FxManualPointUpdate(
          capturedAt: capturedAt,
          refMes: refMes,
          fx: fx,
        ),
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

  Future<bool> delete(int pointId) async {
    final farmId = _farmContext.farmId;
    if (farmId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _repo.delete(farmId: farmId, pointId: pointId);
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
