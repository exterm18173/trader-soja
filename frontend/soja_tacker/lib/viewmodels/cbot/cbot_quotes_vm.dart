// lib/viewmodels/cbot/cbot_quotes_vm.dart
import '../../core/api/api_exception.dart';
import '../../core/auth/farm_context.dart';
import '../../data/models/cbot/cbot_quote_read.dart';
import '../../data/repositories/cbot_quotes_repository.dart';
import '../base_view_model.dart';

class CbotQuotesVM extends BaseViewModel {
  final CbotQuotesRepository _repo;
  final FarmContext _farmContext;

  CbotQuoteRead? latest;
  List<CbotQuoteRead> rows = [];

  String symbol = 'ZS=F';
  int? sourceId;
  int limit = 500;

  CbotQuotesVM(this._repo, this._farmContext);

  Future<void> load({
    String? symbol,
    int? sourceId,
    int? limit,
  }) async {
    final farmId = _farmContext.farmId;
    if (farmId == null) {
      latest = null;
      rows = [];
      notifyListeners();
      return;
    }

    this.symbol = symbol ?? this.symbol;
    this.sourceId = sourceId ?? this.sourceId;
    this.limit = limit ?? this.limit;

    setLoading(true);
    clearError();
    try {
      latest = await _repo.latest(
        farmId: farmId,
        symbol: this.symbol,
        sourceId: this.sourceId,
      );
      rows = await _repo.list(
        farmId: farmId,
        symbol: this.symbol,
        sourceId: this.sourceId,
        limit: this.limit,
      );
    } on ApiException catch (e) {
      setError(e);
      latest = null;
      rows = [];
    } finally {
      setLoading(false);
    }
  }
}
