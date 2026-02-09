// lib/viewmodels/alerts/alert_rules_vm.dart
import '../../core/api/api_exception.dart';
import '../../core/auth/farm_context.dart';
import '../../data/models/alerts/alert_rule_create.dart';
import '../../data/models/alerts/alert_rule_read.dart';
import '../../data/models/alerts/alert_rule_update.dart';
import '../../data/repositories/alerts_repository.dart';
import '../base_view_model.dart';

class AlertRulesVM extends BaseViewModel {
  final AlertsRepository _repo;
  final FarmContext _farmContext;

  List<AlertRuleRead> rows = [];

  bool? ativo;
  String? tipo;
  String? q;

  AlertRulesVM(this._repo, this._farmContext);

  void setFilters({bool? ativo, String? tipo, String? q}) {
    this.ativo = ativo;
    this.tipo = tipo;
    this.q = q;
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
      rows = await _repo.listRules(
        farmId: farmId,
        ativo: ativo,
        tipo: tipo,
        q: q,
      );
    } on ApiException catch (e) {
      setError(e);
      rows = [];
    } finally {
      setLoading(false);
    }
  }

  Future<bool> create(AlertRuleCreate payload) async {
    final farmId = _farmContext.farmId;
    if (farmId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _repo.createRule(farmId: farmId, payload: payload);
      await load();
      return true;
    } on ApiException catch (e) {
      setError(e);
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> update(int ruleId, AlertRuleUpdate payload) async {
    final farmId = _farmContext.farmId;
    if (farmId == null) return false;

    setLoading(true);
    clearError();
    try {
      await _repo.updateRule(farmId: farmId, ruleId: ruleId, payload: payload);
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
