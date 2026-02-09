import 'package:flutter/foundation.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/farm_context.dart';

import '../../data/repositories/dashboard_repository.dart';
import '../../data/models/dashboard/usd_exposure_response.dart';

// ==== AJUSTE AQUI: imports dos seus repos e models reais ====
import '../../data/repositories/fx_spot_repository.dart';
import '../../data/repositories/cbot_quotes_repository.dart';
import '../../data/repositories/rates_repository.dart';
import '../../data/repositories/alerts_repository.dart';



class DashboardVM extends ChangeNotifier {
  final FarmContext farmCtx;
  final DashboardRepository dashboardRepo;

  // ==== AJUSTE AQUI: repos reais ====
final FxSpotRepository fxSpotRepo;
final CbotQuotesRepository cbotRepo;
final RatesRepository ratesRepo;
final AlertsRepository alertsRepo;

  DashboardVM(
    this.farmCtx,
    this.dashboardRepo,
    this.fxSpotRepo,
    this.cbotRepo,
    this.ratesRepo,
    this.alertsRepo,
  );

  bool loading = false;
  ApiException? error;

  // Filtro
  DateTime? fromMes; // sempre dia 1
  DateTime? toMes;   // sempre dia 1

  // Dados principais
  UsdExposureResponse? exposure;

  // KPIs (tipos abaixo ficam como dynamic até você plugar seus models)
  dynamic fxSpotLatest;
  dynamic cbotLatest;
  dynamic interestLatest;
  dynamic offsetLatest;

  int unreadAlertsCount = 0;
  List<dynamic> alertsPreview = const [];

  bool get hasData =>
      exposure != null ||
      fxSpotLatest != null ||
      cbotLatest != null ||
      interestLatest != null ||
      offsetLatest != null ||
      alertsPreview.isNotEmpty;

  String _fmtYmd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  DateTime _mes(DateTime d) => DateTime(d.year, d.month, 1);

  void _setLoading(bool v) {
    loading = v;
    notifyListeners();
  }

  void _setError(ApiException e) {
    error = e;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  /// Default: últimos 12 meses (competência)
  void ensureDefaultRange() {
    if (fromMes != null && toMes != null) return;
    final now = DateTime.now();
    final to = DateTime(now.year, now.month, 1);
    final from = DateTime(now.year, now.month - 11, 1);
    fromMes = from;
    toMes = to;
  }

  Future<void> load({bool force = false}) async {
    final farmId = farmCtx.farmId;
    if (farmId == null) return;

    ensureDefaultRange();
    final from = fromMes!;
    final to = toMes!;

    _setLoading(true);
    error = null;

    try {
      // 1) principal: usd exposure
      final usdFuture = dashboardRepo.usdExposure(
        farmId: farmId,
        fromMes: _fmtYmd(from),
        toMes: _fmtYmd(to),
      );

      // 2) demais KPIs/listas (opcionais) - plugar quando quiser
      final fxSpotFuture = fxSpotRepo.latestTick(farmId: farmId);
   final cbotFuture = cbotRepo.latest(farmId: farmId, symbol: "ZS=F");
   final interestFuture = ratesRepo.latestInterest(farmId: farmId);
final offsetFuture = ratesRepo.latestOffset(farmId: farmId);
final unreadAlertsFuture = alertsRepo.listEvents(farmId: farmId, read: false, limit: 50);
    final previewAlertsFuture = alertsRepo.listEvents(farmId: farmId, limit: 10);

      exposure = await usdFuture;

      // ===== Descomente quando plugar repos reais =====
    final results = await Future.wait([
       usdFuture,
      fxSpotFuture,
         cbotFuture,
         interestFuture,
        offsetFuture,
      unreadAlertsFuture,
         previewAlertsFuture,
       ]);
       exposure = results[0] as UsdExposureResponse;
       fxSpotLatest = results[1];
       cbotLatest = results[2];
       interestLatest = results[3];
       offsetLatest = results[4];
       final unread = results[5] as List<dynamic>;
       unreadAlertsCount = unread.length;
       alertsPreview = (results[6] as List<dynamic>);

      _setLoading(false);
    } on ApiException catch (e) {
      _setLoading(false);
      _setError(e);
    } catch (e) {
      _setLoading(false);
      _setError(ApiException(message: 'Erro ao carregar dashboard', details: e.toString()));
    }
  }

  void setRange({required DateTime from, required DateTime to}) {
    final a = _mes(from);
    final b = _mes(to);
    if (a.isAfter(b)) {
      fromMes = b;
      toMes = a;
    } else {
      fromMes = a;
      toMes = b;
    }
    load(force: true);
  }
}
