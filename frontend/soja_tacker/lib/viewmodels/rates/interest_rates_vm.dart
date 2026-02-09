// lib/viewmodels/rates/interest_rates_vm.dart
import '../../core/api/api_exception.dart';
import '../../core/auth/farm_context.dart';
import '../../data/models/rates/interest_rate_create.dart';
import '../../data/models/rates/interest_rate_read.dart';
import '../../data/models/rates/interest_rate_update.dart';
import '../../data/repositories/rates_repository.dart';
import '../base_view_model.dart';

class InterestRatesVM extends BaseViewModel {
  final RatesRepository _repo;
  final FarmContext _farmContext;

  List<InterestRateRead> rows = [];

  InterestRatesVM(this._repo, this._farmContext);

  Future<void> load({String? from, String? to}) async {
    final farmId = _farmContext.farmId;
    if (farmId == null) {
      rows = [];
      notifyListeners();
      return;
    }

    setLoading(true);
    clearError();
    try {
      rows = await _repo.listInterest(farmId: farmId, from: from, to: to);
    } on ApiException catch (e) {
      setError(e);
      rows = [];
    } finally {
      setLoading(false);
    }
  }

  Future<bool> create({
    required DateTime rateDate,
    required double cdiAnnual,
    required double sofrAnnual,
  }) async {
    final farmId = _farmContext.farmId;
    if (farmId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _repo.createInterest(
        farmId: farmId,
        payload: InterestRateCreate(
          rateDate: rateDate,
          cdiAnnual: cdiAnnual,
          sofrAnnual: sofrAnnual,
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
    required int rowId,
    double? cdiAnnual,
    double? sofrAnnual,
  }) async {
    final farmId = _farmContext.farmId;
    if (farmId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _repo.updateInterest(
        farmId: farmId,
        rowId: rowId,
        payload: InterestRateUpdate(
          cdiAnnual: cdiAnnual,
          sofrAnnual: sofrAnnual,
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
}
