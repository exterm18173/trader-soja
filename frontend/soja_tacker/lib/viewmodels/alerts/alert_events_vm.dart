// lib/viewmodels/alerts/alert_events_vm.dart
import '../../core/api/api_exception.dart';
import '../../core/auth/farm_context.dart';
import '../../data/models/alerts/alert_event_read.dart';
import '../../data/models/alerts/alert_event_update.dart';
import '../../data/repositories/alerts_repository.dart';
import '../base_view_model.dart';

class AlertEventsVM extends BaseViewModel {
  final AlertsRepository _repo;
  final FarmContext _farmContext;

  List<AlertEventRead> rows = [];

  bool? read;
  String? severity;
  int limit = 200;

  AlertEventsVM(this._repo, this._farmContext);

  void setFilters({bool? read, String? severity, int? limit}) {
    this.read = read;
    this.severity = severity;
    if (limit != null) this.limit = limit;
    notifyListeners();
  }

  Future<void> load() async {
    final farmId = _farmContext.farmId;
    if (farmId == null) {
      rows = [];
      notifyListeners();
      return;
    }

    setLoading(true);
    clearError();
    try {
      rows = await _repo.listEvents(
        farmId: farmId,
        read: read,
        severity: severity,
        limit: limit,
      );
    } on ApiException catch (e) {
      setError(e);
      rows = [];
    } finally {
      setLoading(false);
    }
  }

  Future<bool> markRead(int eventId, bool readValue) async {
    final farmId = _farmContext.farmId;
    if (farmId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _repo.updateEvent(
        farmId: farmId,
        eventId: eventId,
        payload: AlertEventUpdate(read: readValue),
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
