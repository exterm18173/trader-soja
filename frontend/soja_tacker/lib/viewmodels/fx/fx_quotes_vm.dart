// lib/viewmodels/fx/fx_quotes_vm.dart
import '../../core/api/api_exception.dart';
import '../../core/auth/farm_context.dart';
import '../../data/models/fx/fx_quote_create.dart';
import '../../data/models/fx/fx_quote_with_check_read.dart';
import '../../data/repositories/fx_quotes_repository.dart';
import '../base_view_model.dart';

class FxQuotesVM extends BaseViewModel {
  final FxQuotesRepository _repo;
  final FarmContext _farmContext;

  List<FxQuoteWithCheckRead> rows = [];

  int? filterSourceId;
  DateTime? filterRefMes;
  int limit = 200;

  FxQuotesVM(this._repo, this._farmContext);

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
    required DateTime capturadoEm,
    required DateTime refMes,
    required double brlPerUsd,
    String? observacao,
  }) async {
    final farmId = _farmContext.farmId;
    if (farmId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _repo.create(
        farmId: farmId,
        payload: FxQuoteCreate(
          sourceId: sourceId,
          capturadoEm: capturadoEm,
          refMes: refMes,
          brlPerUsd: brlPerUsd,
          observacao: observacao,
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
