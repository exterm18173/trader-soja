// contracts_result_dashboard_vm.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/farm_context.dart';
import '../../data/models/contracts/contract_read.dart';
import '../../data/models/fx/fx_quote_with_check_read.dart';
import '../../data/models/hedges/hedge_cbot_read.dart';
import '../../data/models/hedges/hedge_fx_read.dart';
import '../../data/models/hedges/hedge_premium_read.dart';
import '../../data/repositories/cbot_quotes_repository.dart';
import '../../data/repositories/contracts_repository.dart';
import '../../data/repositories/fx_quotes_repository.dart';
import '../../data/repositories/fx_spot_repository.dart';
import '../../data/repositories/hedges_repository.dart';

enum ContractPricingMode { manual, realtime }

class ContractResultRow {
  final ContractRead contract;

  // locked (hedges)
  final double? lockedUsdPerBu; // bushel (cbot + premium)
  final double? lockedUsdPerSack; // 60kg
  final double? lockedBrlPerSackManual; // usa FX manual (último quote)
  final double? lockedBrlPerSackRealtime; // usa FX spot/latest

  final double lockedCbotTon;
  final double lockedPremiumTon;
  final double lockedFxTon;
  final double volumeTotalTon;

  final FxQuoteWithCheckRead? lastFxQuoteForRefMes;

  final double? realtimeFxBrlPerUsd;
  final double? realtimeCbotUsdPerBu;

  const ContractResultRow({
    required this.contract,
    required this.lockedUsdPerBu,
    required this.lockedUsdPerSack,
    required this.lockedBrlPerSackManual,
    required this.lockedBrlPerSackRealtime,
    required this.lockedCbotTon,
    required this.lockedPremiumTon,
    required this.lockedFxTon,
    required this.volumeTotalTon,
    required this.lastFxQuoteForRefMes,
    required this.realtimeFxBrlPerUsd,
    required this.realtimeCbotUsdPerBu,
  });

  double get pctCbotLocked => volumeTotalTon <= 0 ? 0 : (lockedCbotTon / volumeTotalTon);
  double get pctPremiumLocked => volumeTotalTon <= 0 ? 0 : (lockedPremiumTon / volumeTotalTon);
  double get pctFxLocked => volumeTotalTon <= 0 ? 0 : (lockedFxTon / volumeTotalTon);

  String get refMesKey => _fmtYmd(_monthStart(contract.dataEntrega));
}

class _HedgeAgg {
  double cbotTon = 0;
  double premiumTon = 0;
  double fxTon = 0;

  double cbotUsdPerBuWeighted = 0;
  double premiumUsdPerBuWeighted = 0;
  double fxBrlPerUsdWeighted = 0;

  String? symbol;

  double? get lockedCbotUsdPerBu => cbotTon > 0 ? (cbotUsdPerBuWeighted / cbotTon) : null;
  double? get lockedPremiumUsdPerBu => premiumTon > 0 ? (premiumUsdPerBuWeighted / premiumTon) : null;
  double? get lockedFxBrlPerUsd => fxTon > 0 ? (fxBrlPerUsdWeighted / fxTon) : null;

  double? get lockedUsdPerBu {
    final c = lockedCbotUsdPerBu;
    final p = lockedPremiumUsdPerBu;
    if (c == null && p == null) return null;
    return (c ?? 0) + (p ?? 0);
  }
}

// KPIs simples pro topo
class ContractsDashboardKpis {
  final int contractsCount;
  final double totalTon;
  final double? avgBrlPerSack; // depende do modo (já calculado no getter)
  final double avgPctCbotLocked;
  final double avgPctPremiumLocked;
  final double avgPctFxLocked;

  const ContractsDashboardKpis({
    required this.contractsCount,
    required this.totalTon,
    required this.avgBrlPerSack,
    required this.avgPctCbotLocked,
    required this.avgPctPremiumLocked,
    required this.avgPctFxLocked,
  });
}

class ContractsResultDashboardVM extends ChangeNotifier {
  final FarmContext farmContext;
  final ContractsRepository _contractsRepo;
  final HedgesRepository _hedgesRepo;
  final FxQuotesRepository _fxQuotesRepo;
  final FxSpotRepository _fxSpotRepo;
  final CbotQuotesRepository _cbotRepo;

  ContractsResultDashboardVM(
    this.farmContext,
    this._contractsRepo,
    this._hedgesRepo,
    this._fxQuotesRepo,
    this._fxSpotRepo,
    this._cbotRepo,
  );

  bool loading = false;
  Object? error;

  ContractPricingMode mode = ContractPricingMode.manual;

  String? statusFilter;
  String search = '';

  List<ContractRead> contracts = [];
  final Map<int, _HedgeAgg> _hedgeAggByContract = {};
  final Map<String, FxQuoteWithCheckRead?> _lastFxQuoteByRefMes = {};

  double? realtimeFxBrlPerUsd;
  double? realtimeCbotUsdPerBu;
  DateTime? realtimeAsOf;

  Timer? _pollTimer;

  int _loadSeq = 0;
  DateTime _lastNotify = DateTime.fromMillisecondsSinceEpoch(0);

  // ----- lifecycle -----
  void startRealtimePolling({Duration every = const Duration(seconds: 10)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(every, (_) => refreshRealtime());
  }

  void stopRealtimePolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    stopRealtimePolling();
    super.dispose();
  }

  // ----- helpers -----
  void _setLoading(bool v) {
    loading = v;
    notifyListeners();
  }

  void _setError(Object? e) {
    error = e;
    notifyListeners();
  }

  String _errMsg(Object? e) {
    if (e is ApiException) return e.message;
    return e?.toString() ?? 'Erro desconhecido';
  }

  // throttle: no máximo 1 notify por 250ms durante loops
  void _notifyThrottled({bool force = false}) {
    final now = DateTime.now();
    if (force || now.difference(_lastNotify).inMilliseconds >= 250) {
      _lastNotify = now;
      notifyListeners();
    }
  }

  // ----- UI actions -----
  void setMode(ContractPricingMode m) {
    if (mode == m) return;
    mode = m;

    if (mode == ContractPricingMode.realtime) {
      startRealtimePolling(every: const Duration(seconds: 10));
      refreshRealtime();
    } else {
      stopRealtimePolling();
    }

    notifyListeners();
  }

  void setStatusFilter(String? v) {
    statusFilter = v;
    notifyListeners();
  }

  void setSearch(String v) {
    search = v;
    notifyListeners();
  }

  // ----- loading -----
  Future<void> load() async {
    final farmId = farmContext.farmId;
    if (farmId == null) return;

    final seq = ++_loadSeq;

    _setLoading(true);
    _setError(null);

    try {
      final list = await _contractsRepo.list(
        farmId: farmId,
        status: statusFilter,
        q: search.trim().isEmpty ? null : search.trim(),
      );
      if (seq != _loadSeq) return;

      contracts = list;

      _hedgeAggByContract.clear();
      _lastFxQuoteByRefMes.clear();

      // 1) hedges por contrato (progressivo, com throttle)
      await _loadHedgesForContracts(farmId, contracts, seq);

      // 2) último FX quote por ref_mes único
      final refMesKeys = contracts
          .map((c) => _fmtYmd(_monthStart(c.dataEntrega)))
          .toSet()
          .toList();

      await _loadLastFxQuotesForRefMes(farmId, refMesKeys, seq);

      // 3) snapshot realtime (best effort)
      await refreshRealtime();
    } on ApiException catch (e) {
      if (seq != _loadSeq) return;
      _setError(e);
    } catch (e) {
      if (seq != _loadSeq) return;
      _setError(e);
    } finally {
      if (seq == _loadSeq) _setLoading(false);
    }
  }

  Future<void> refreshRealtime() async {
    final farmId = farmContext.farmId;
    if (farmId == null) return;

    try {
      final fx = await _fxSpotRepo.latestTick(farmId: farmId, source: null);
      realtimeFxBrlPerUsd = fx?.price;

      final symbol = _pickAnySymbol() ?? 'ZS=F';
      final cbot =
          await _cbotRepo.latest(farmId: farmId, symbol: symbol, sourceId: null);
      realtimeCbotUsdPerBu = cbot?.priceUsdPerBu;

      realtimeAsOf = DateTime.now();
      notifyListeners();
    } catch (_) {
      // best effort
      notifyListeners();
    }
  }

  String? _pickAnySymbol() {
    for (final a in _hedgeAggByContract.values) {
      if (a.symbol != null && a.symbol!.trim().isNotEmpty) return a.symbol;
    }
    return null;
  }

  Future<void> _loadHedgesForContracts(
    int farmId,
    List<ContractRead> list,
    int seq,
  ) async {
    for (final c in list) {
      if (seq != _loadSeq) return;

      final agg = _HedgeAgg();

      final cbot = await _hedgesRepo.listCbot(farmId: farmId, contractId: c.id);
      final prem = await _hedgesRepo.listPremium(farmId: farmId, contractId: c.id);
      final fx = await _hedgesRepo.listFx(farmId: farmId, contractId: c.id);

      _applyCbot(agg, cbot);
      _applyPremium(agg, prem);
      _applyFx(agg, fx);

      _hedgeAggByContract[c.id] = agg;

      _notifyThrottled();
    }
    _notifyThrottled(force: true);
  }

  Future<void> _loadLastFxQuotesForRefMes(
    int farmId,
    List<String> refMesKeys,
    int seq,
  ) async {
    for (final ref in refMesKeys) {
      if (seq != _loadSeq) return;

      final list = await _fxQuotesRepo.list(
        farmId: farmId,
        refMes: ref,
        sourceId: null,
        limit: 200,
      );

      if (list.isEmpty) {
        _lastFxQuoteByRefMes[ref] = null;
        _notifyThrottled();
        continue;
      }

      list.sort((a, b) => a.quote.capturadoEm.compareTo(b.quote.capturadoEm));
      _lastFxQuoteByRefMes[ref] = list.last;

      _notifyThrottled();
    }
    _notifyThrottled(force: true);
  }

  // ----- computed rows -----
  List<ContractResultRow> get rows {
    final farmId = farmContext.farmId;
    if (farmId == null) return const [];

    final out = <ContractResultRow>[];

    for (final c in contracts) {
      final agg = _hedgeAggByContract[c.id];
      final refKey = _fmtYmd(_monthStart(c.dataEntrega));
      final lastFx = _lastFxQuoteByRefMes[refKey];

      final lockedUsdPerBu = agg?.lockedUsdPerBu;
      final lockedUsdPerSack =
          lockedUsdPerBu == null ? null : usdPerBuToUsdPerSack(lockedUsdPerBu);

      final fxManualBrl = lastFx?.quote.brlPerUsd;
      final lockedBrlPerSackManual = (lockedUsdPerSack != null && fxManualBrl != null)
          ? lockedUsdPerSack * fxManualBrl
          : null;

      double? realtimeUsdPerBu;
      if (lockedUsdPerBu != null) {
        realtimeUsdPerBu = lockedUsdPerBu;
      } else {
        final premUsdPerBu = agg?.lockedPremiumUsdPerBu ?? 0;
        final cbotUsdPerBu = realtimeCbotUsdPerBu;
        if (cbotUsdPerBu != null) {
          realtimeUsdPerBu = cbotUsdPerBu + premUsdPerBu;
        }
      }

      final realtimeUsdPerSack =
          realtimeUsdPerBu == null ? null : usdPerBuToUsdPerSack(realtimeUsdPerBu);
      final fxSpot = realtimeFxBrlPerUsd;

      final lockedBrlPerSackRealtime =
          (realtimeUsdPerSack != null && fxSpot != null) ? realtimeUsdPerSack * fxSpot : null;

      out.add(
        ContractResultRow(
          contract: c,
          lockedUsdPerBu: lockedUsdPerBu,
          lockedUsdPerSack: lockedUsdPerSack,
          lockedBrlPerSackManual: lockedBrlPerSackManual,
          lockedBrlPerSackRealtime: lockedBrlPerSackRealtime,
          lockedCbotTon: agg?.cbotTon ?? 0,
          lockedPremiumTon: agg?.premiumTon ?? 0,
          lockedFxTon: agg?.fxTon ?? 0,
          volumeTotalTon: c.volumeTotalTon,
          lastFxQuoteForRefMes: lastFx,
          realtimeFxBrlPerUsd: realtimeFxBrlPerUsd,
          realtimeCbotUsdPerBu: realtimeCbotUsdPerBu,
        ),
      );
    }

    out.sort((a, b) => a.contract.dataEntrega.compareTo(b.contract.dataEntrega));
    return out;
  }

  // KPIs (já usando rows do modo atual)
  ContractsDashboardKpis get kpis {
    final r = rows;
    if (r.isEmpty) {
      return const ContractsDashboardKpis(
        contractsCount: 0,
        totalTon: 0,
        avgBrlPerSack: null,
        avgPctCbotLocked: 0,
        avgPctPremiumLocked: 0,
        avgPctFxLocked: 0,
      );
    }

    double totalTon = 0;
    double sumPctC = 0, sumPctP = 0, sumPctF = 0;
    double sumBrl = 0;
    int brlCount = 0;

    for (final x in r) {
      totalTon += x.volumeTotalTon;
      sumPctC += x.pctCbotLocked;
      sumPctP += x.pctPremiumLocked;
      sumPctF += x.pctFxLocked;

      final brl = mode == ContractPricingMode.manual
          ? x.lockedBrlPerSackManual
          : x.lockedBrlPerSackRealtime;

      if (brl != null) {
        sumBrl += brl;
        brlCount++;
      }
    }

    return ContractsDashboardKpis(
      contractsCount: r.length,
      totalTon: totalTon,
      avgBrlPerSack: brlCount == 0 ? null : (sumBrl / brlCount),
      avgPctCbotLocked: sumPctC / r.length,
      avgPctPremiumLocked: sumPctP / r.length,
      avgPctFxLocked: sumPctF / r.length,
    );
  }

  // ----- hedge aggregation -----
  void _applyCbot(_HedgeAgg agg, List<HedgeCbotRead> list) {
    for (final h in list) {
      agg.cbotTon += h.volumeTon;
      agg.cbotUsdPerBuWeighted += h.cbotUsdPerBu * h.volumeTon;
      if (h.symbol != null && h.symbol!.trim().isNotEmpty) {
        agg.symbol ??= h.symbol;
      }
    }
  }

  void _applyPremium(_HedgeAgg agg, List<HedgePremiumRead> list) {
    for (final h in list) {
      final premUsdPerBu = premiumToUsdPerBu(h.premiumValue, h.premiumUnit);
      agg.premiumTon += h.volumeTon;
      agg.premiumUsdPerBuWeighted += premUsdPerBu * h.volumeTon;
    }
  }

  void _applyFx(_HedgeAgg agg, List<HedgeFxRead> list) {
    for (final h in list) {
      agg.fxTon += h.volumeTon;
      agg.fxBrlPerUsdWeighted += h.brlPerUsd * h.volumeTon;
    }
  }

  // ----- formatting -----
  String manualInfoFor(ContractResultRow r) {
    final q = r.lastFxQuoteForRefMes;
    if (q == null) return 'Sem lançamento';
    final dt = q.quote.capturadoEm.toLocal();
    final d =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final err = q.check.deltaPct.toStringAsFixed(2);
    return 'FX ${q.quote.brlPerUsd.toStringAsFixed(4)} • $d • erro $err%';
  }

  String realtimeInfo() {
    final fx = realtimeFxBrlPerUsd;
    final cbot = realtimeCbotUsdPerBu;
    final asOf = realtimeAsOf;
    final t = asOf == null
        ? ''
        : '${asOf.hour.toString().padLeft(2, '0')}:${asOf.minute.toString().padLeft(2, '0')}:${asOf.second.toString().padLeft(2, '0')}';
    return 'CBOT ${cbot?.toStringAsFixed(4) ?? '—'} USD/bu • FX ${fx?.toStringAsFixed(4) ?? '—'} BRL/USD • ${t.isEmpty ? '' : 'as_of $t'}';
  }

  String errorText() => _errMsg(error);
}

// ---------- pricing helpers ----------
const double _SOY_BU_KG = 27.2155;
const double _SACK_KG = 60.0;
const double _KG_PER_TON = 1000.0;

double usdPerBuToUsdPerSack(double usdPerBu) {
  final sacksPerBu = _SACK_KG / _SOY_BU_KG;
  return usdPerBu * sacksPerBu;
}

double premiumToUsdPerBu(double premiumValue, String premiumUnit) {
  final u = premiumUnit.trim().toUpperCase();
  if (u == 'USD_BU' || u == 'USD/BU') return premiumValue;
  if (u == 'USD_TON' || u == 'USD/TON') {
    final tonPerBu = _SOY_BU_KG / _KG_PER_TON;
    return premiumValue * tonPerBu;
  }
  return premiumValue;
}

DateTime _monthStart(DateTime d) => DateTime(d.year, d.month, 1);

String _fmtYmd(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
