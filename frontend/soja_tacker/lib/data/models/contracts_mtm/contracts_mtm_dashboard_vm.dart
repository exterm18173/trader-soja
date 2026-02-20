// lib/data/models/contracts_mtm/contracts_mtm_dashboard_vm.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../repositories/contracts_mtm_repository.dart';
import 'contracts_mtm_response.dart';

enum DashboardViewSide { manual, system }
enum LockVisualState { locked, open }

class LockStatusUi {
  final LockVisualState state;
  final double coveragePct; // 0..1
  final String label; // "Travado" | "Aberto"

  const LockStatusUi({
    required this.state,
    required this.coveragePct,
    required this.label,
  });
}

class ContractsMtmKpis {
  final double tonTotal;
  final double sacasTotal;
  final double usdTotal;
  final double brlTotal; // conforme viewSide
  final double avgUsdPerSaca;
  final double avgBrlPerSaca;

  final double fxLockedPct;
  final double fxUnlockedPct;

  const ContractsMtmKpis({
    required this.tonTotal,
    required this.sacasTotal,
    required this.usdTotal,
    required this.brlTotal,
    required this.avgUsdPerSaca,
    required this.avgBrlPerSaca,
    required this.fxLockedPct,
    required this.fxUnlockedPct,
  });

  String fingerprint({int decimals = 4}) {
    String f(double v) => v.toStringAsFixed(decimals);
    return [
      f(tonTotal),
      f(sacasTotal),
      f(usdTotal),
      f(brlTotal),
      f(avgUsdPerSaca),
      f(avgBrlPerSaca),
      f(fxLockedPct),
      f(fxUnlockedPct),
    ].join('|');
  }
}

class LockAggregates {
  final double ton;
  final double sacas;
  final double usd;
  final double brl;

  const LockAggregates({
    required this.ton,
    required this.sacas,
    required this.usd,
    required this.brl,
  });

  static const zero = LockAggregates(ton: 0, sacas: 0, usd: 0, brl: 0);
}

class LockBreakdown {
  final LockAggregates locked;
  final LockAggregates open;

  const LockBreakdown({
    required this.locked,
    required this.open,
  });

  static const empty = LockBreakdown(
    locked: LockAggregates.zero,
    open: LockAggregates.zero,
  );
}

class ContractsMtmDashboardVM extends ChangeNotifier {
  final ContractsMtmRepository repo;
  ContractsMtmDashboardVM(this.repo);

  bool loading = false;
  Object? error;

  ContractsMtmResponse? data;

  DashboardViewSide viewSide = DashboardViewSide.manual;

  // filtros básicos
  bool onlyOpen = true;
  String mode = 'both';
  String defaultSymbol = 'AUTO';

  /// backend: "YYYY-MM-30" (opcional; força FX)
  String? refMes30;

  // ✅ filtros de trava (locked/open)
  Set<String> lockTypes = {};  // {'cbot','premium','fx'}
  Set<String> lockStates = {}; // {'locked','open'}

  // ✅ NOVO: sem travas (FIXO_BRL)
  bool noLocks = false;

  // realtime polling
  Timer? _pollTimer;
  Duration _pollEvery = const Duration(seconds: 10);
  bool realtimeEnabled = false;

  int updateTick = 0;
  String? _lastFingerprint;

  Future<void> load({required int farmId, bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    } else {
      error = null;
    }

    try {
      final res = await repo.mtm(
        farmId: farmId,
        mode: mode,
        onlyOpen: onlyOpen,
        refMes: refMes30,
        defaultSymbol: defaultSymbol,
        limit: 200,

        // ✅ novo
        noLocks: noLocks,

        // ✅ só manda quando não for noLocks
        lockTypes: (noLocks || lockTypes.isEmpty) ? null : lockTypes.join(','),
        lockStates: (noLocks || lockStates.isEmpty) ? null : lockStates.join(','),
      );

      final newKpis = _calcKpisFrom(res);
      final fp = newKpis.fingerprint();

      if (_lastFingerprint != fp || data == null) {
        data = res;
        _lastFingerprint = fp;
        updateTick++;
        if (silent) notifyListeners();
      }
    } on Exception catch (e) {
      error = e;
      if (silent) notifyListeners();
    } finally {
      if (!silent) {
        loading = false;
        notifyListeners();
      }
    }
  }

  // realtime
  void startRealtime({
    required int farmId,
    Duration every = const Duration(seconds: 10),
  }) {
    _pollEvery = every;
    realtimeEnabled = true;

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollEvery, (_) {
      load(farmId: farmId, silent: true);
    });

    notifyListeners();
  }

  void stopRealtime() {
    realtimeEnabled = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    notifyListeners();
  }

  void toggleRealtime({required int farmId}) {
    if (realtimeEnabled) {
      stopRealtime();
    } else {
      startRealtime(farmId: farmId, every: _pollEvery);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // UI setters
  void notifyUi() => notifyListeners();

  void setViewSide(DashboardViewSide s) {
    if (viewSide == s) return;
    viewSide = s;
    _lastFingerprint = kpis.fingerprint();
    notifyListeners();
  }

  // ✅ noLocks toggle (e limpa os outros)
  void setNoLocks(bool v) {
    if (noLocks == v) return;
    noLocks = v;
    if (noLocks) {
      lockTypes.clear();
      lockStates.clear();
    }
    notifyListeners();
  }

  void toggleLockType(String t) {
    if (noLocks) return; // ✅ bloqueia
    if (!(t == 'cbot' || t == 'premium' || t == 'fx')) return;
    if (lockTypes.contains(t)) {
      lockTypes.remove(t);
    } else {
      lockTypes.add(t);
    }
    notifyListeners();
  }

  void toggleLockState(String s) {
    if (noLocks) return; // ✅ bloqueia
    if (!(s == 'locked' || s == 'open')) return;
    if (lockStates.contains(s)) {
      lockStates.remove(s);
    } else {
      lockStates.add(s);
    }
    notifyListeners();
  }

  void clearLockFilters() {
    lockTypes.clear();
    lockStates.clear();
    notifyListeners();
  }

  void clearAllFilters() {
    noLocks = false;
    lockTypes.clear();
    lockStates.clear();
    notifyListeners();
  }

  // errors
  String errMsg(Object? e) {
    if (e is ApiException) return e.message;
    return e?.toString() ?? 'Erro desconhecido';
  }

  // totals selector
  ContractTotalsView? _tv(ContractMtmRow r) => r.totalsView;

  double brlOfRow(ContractMtmRow r) {
    final tv = _tv(r);
    final side = (tv?.brlTotalContract ?? r.totals.brlTotalContract);
    return (viewSide == DashboardViewSide.manual ? side.manual : side.system) ?? 0.0;
  }

  double usdOfRow(ContractMtmRow r) {
    final tv = _tv(r);
    return tv?.usdTotalContract ?? r.totals.usdTotalContract ?? 0.0;
  }

  double tonOfRow(ContractMtmRow r) {
    final tv = _tv(r);
    return tv?.tonTotal ?? r.totals.tonTotal;
  }

  double sacasOfRow(ContractMtmRow r) {
    final tv = _tv(r);
    return tv?.sacasTotal ?? r.totals.sacasTotal;
  }

  // lock UI
  LockStatusUi lockUiFrom({required bool locked, required double coveragePct}) {
    final pct = coveragePct.clamp(0.0, 1.0);
    if (locked || pct >= 0.999) {
      return LockStatusUi(state: LockVisualState.locked, coveragePct: pct, label: 'Travado');
    }
    return LockStatusUi(state: LockVisualState.open, coveragePct: pct, label: 'Aberto');
  }

  LockStatusUi cbotUi(ContractMtmRow r) => lockUiFrom(
        locked: r.locks.cbot.locked,
        coveragePct: r.locks.cbot.coveragePct,
      );

  LockStatusUi premiumUi(ContractMtmRow r) => lockUiFrom(
        locked: r.locks.premium.locked,
        coveragePct: r.locks.premium.coveragePct,
      );

  LockStatusUi fxUi(ContractMtmRow r) => lockUiFrom(
        locked: r.locks.fx.locked,
        coveragePct: r.locks.fx.coveragePct,
      );

  // KPIs
  ContractsMtmKpis get kpis => _calcKpisFrom(data);

  ContractsMtmKpis _calcKpisFrom(ContractsMtmResponse? d) {
    final rows = d?.rows ?? const <ContractMtmRow>[];

    double ton = 0, sacas = 0, usd = 0, brl = 0;

    double usdSum = 0;
    double fxLockedWeighted = 0;
    double fxUnlockedWeighted = 0;

    for (final r in rows) {
      final rowTon = tonOfRow(r);
      final rowSacas = sacasOfRow(r);
      final rowUsd = usdOfRow(r);
      final rowBrl = brlOfRow(r);

      ton += rowTon;
      sacas += rowSacas;
      usd += rowUsd;
      brl += rowBrl;

      final t = r.totals;
      final fxLockedPct =
          (viewSide == DashboardViewSide.manual ? t.fxLockedUsdPct.manual : t.fxLockedUsdPct.system) ?? 0.0;
      final fxUnlockedPct =
          (viewSide == DashboardViewSide.manual ? t.fxUnlockedUsdPct.manual : t.fxUnlockedUsdPct.system) ?? 1.0;

      usdSum += rowUsd;
      fxLockedWeighted += rowUsd * fxLockedPct;
      fxUnlockedWeighted += rowUsd * fxUnlockedPct;
    }

    final avgUsd = sacas <= 0 ? 0.0 : (usd / sacas);
    final avgBrl = sacas <= 0 ? 0.0 : (brl / sacas);

    final fxLocked = usdSum <= 0 ? 0.0 : (fxLockedWeighted / usdSum);
    final fxUnlocked = usdSum <= 0 ? 0.0 : (fxUnlockedWeighted / usdSum);

    return ContractsMtmKpis(
      tonTotal: ton,
      sacasTotal: sacas,
      usdTotal: usd,
      brlTotal: brl,
      avgUsdPerSaca: avgUsd,
      avgBrlPerSaca: avgBrl,
      fxLockedPct: fxLocked.clamp(0.0, 1.0),
      fxUnlockedPct: fxUnlocked.clamp(0.0, 1.0),
    );
  }

  List<ContractMtmRow> get topRowsByBrl {
    final rows = [...(data?.rows ?? const <ContractMtmRow>[])];
    rows.sort((a, b) => brlOfRow(b).compareTo(brlOfRow(a)));
    return rows.take(rows.length > 6 ? 6 : rows.length).toList();
  }

  // breakdown
  LockBreakdown breakdownForCbot() => _breakdownByUi(cbotUi);
  LockBreakdown breakdownForPremium() => _breakdownByUi(premiumUi);
  LockBreakdown breakdownForFx() => _breakdownByUi(fxUi);

  LockBreakdown _breakdownByUi(LockStatusUi Function(ContractMtmRow r) getUi) {
    final rows = data?.rows ?? const <ContractMtmRow>[];

    LockAggregates locked = LockAggregates.zero;
    LockAggregates open = LockAggregates.zero;

    for (final r in rows) {
      final ui = getUi(r);
      final a = LockAggregates(
        ton: tonOfRow(r),
        sacas: sacasOfRow(r),
        usd: usdOfRow(r),
        brl: brlOfRow(r),
      );

      if (ui.state == LockVisualState.locked) {
        locked = _sumAgg(locked, a);
      } else {
        open = _sumAgg(open, a);
      }
    }

    return LockBreakdown(locked: locked, open: open);
  }

  LockAggregates _sumAgg(LockAggregates x, LockAggregates y) {
    return LockAggregates(
      ton: x.ton + y.ton,
      sacas: x.sacas + y.sacas,
      usd: x.usd + y.usd,
      brl: x.brl + y.brl,
    );
  }
}
