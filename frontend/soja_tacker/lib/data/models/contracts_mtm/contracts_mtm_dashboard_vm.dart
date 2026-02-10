// lib/data/models/contracts_mtm/contracts_mtm_dashboard_vm.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../repositories/contracts_mtm_repository.dart';
import 'contracts_mtm_response.dart';

enum DashboardViewSide { manual, system }

enum LockVisualState { locked, partial, open }

class LockStatusUi {
  final LockVisualState state;
  final double coveragePct; // 0..1
  final String label; // "Travado", "Parcial", "Aberto"

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

  // Exposição FX (ponderada por USD)
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

  // ✅ fingerprint simples pros cards (tolerância evita “piscar” por ruído)
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
  final LockAggregates partial;
  final LockAggregates open;

  const LockBreakdown({
    required this.locked,
    required this.partial,
    required this.open,
  });

  static const empty = LockBreakdown(
    locked: LockAggregates.zero,
    partial: LockAggregates.zero,
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
  String defaultSymbol = 'ZS=F';
  String? refMes; // YYYY-MM-01

  // --- realtime polling ---
  Timer? _pollTimer;
  Duration _pollEvery = const Duration(seconds: 10);
  bool realtimeEnabled = false;

  // “tick” que pode ser usado pra animar / observar atualizações
  int updateTick = 0;

  String? _lastFingerprint; // detecta mudança real (evita notify “à toa”)

  Future<void> load({required int farmId, bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    } else {
      // no silent você pode manter a UI sem “loading bar” se quiser
      error = null;
    }

    try {
      final res = await repo.mtm(
        farmId: farmId,
        mode: mode,
        onlyOpen: onlyOpen,
        refMes: refMes,
        defaultSymbol: defaultSymbol,
        limit: 200,
      );

      // compute kpis com base no res (sem depender de data atual)
      final newKpis = _calcKpisFrom(res);
      final fp = newKpis.fingerprint();

      // ✅ só aplica se mudou
      if (_lastFingerprint != fp || data == null) {
        data = res;
        _lastFingerprint = fp;
        updateTick++; // força widgets “verem” a mudança (se quiser)
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

  void startRealtime({required int farmId, Duration every = const Duration(seconds: 10)}) {
    _pollEvery = every;
    realtimeEnabled = true;

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollEvery, (_) {
      // ✅ silent pra não ficar piscando loading toda hora
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

  void setViewSide(DashboardViewSide s) {
    if (viewSide == s) return;
    viewSide = s;

    // muda o lado => muda fingerprint => atualiza “estado” pros flashes
    _lastFingerprint = kpis.fingerprint();
    notifyListeners();
  }

  String errMsg(Object? e) {
    if (e is ApiException) return e.message;
    return e?.toString() ?? 'Erro desconhecido';
  }

  // ---------- Helpers ----------
  double brlOfRow(ContractMtmRow r) {
    final b = r.totals.brlTotalContract;
    return (viewSide == DashboardViewSide.manual ? b.manual : b.system) ?? 0.0;
  }

  double usdOfRow(ContractMtmRow r) => r.totals.usdTotalContract ?? 0.0;

  double _usdOfRow(ContractMtmRow r) => usdOfRow(r);
  double _brlOfRow(ContractMtmRow r) => brlOfRow(r);

  // status visual por lock
  LockStatusUi lockUiFrom({required bool locked, required double coveragePct}) {
    final pct = coveragePct.clamp(0.0, 1.0);
    if (locked || pct >= 0.999) {
      return LockStatusUi(state: LockVisualState.locked, coveragePct: pct, label: 'Travado');
    }
    if (pct > 0.0) {
      return LockStatusUi(state: LockVisualState.partial, coveragePct: pct, label: 'Parcial');
    }
    return const LockStatusUi(state: LockVisualState.open, coveragePct: 0.0, label: 'Aberto');
  }

  LockStatusUi cbotUi(ContractMtmRow r) =>
      lockUiFrom(locked: r.locks.cbot.locked, coveragePct: r.locks.cbot.coveragePct);

  LockStatusUi premiumUi(ContractMtmRow r) =>
      lockUiFrom(locked: r.locks.premium.locked, coveragePct: r.locks.premium.coveragePct);

  LockStatusUi fxUi(ContractMtmRow r) =>
      lockUiFrom(locked: r.locks.fx.locked, coveragePct: r.locks.fx.coveragePct);

  // ---------- KPIs agregados ----------
  ContractsMtmKpis get kpis => data == null ? _calcKpisFrom(null) : _calcKpisFrom(data);

  ContractsMtmKpis _calcKpisFrom(ContractsMtmResponse? d) {
    final rows = d?.rows ?? const <ContractMtmRow>[];

    double ton = 0, sacas = 0, usd = 0, brl = 0;

    // FX exposição ponderada por USD
    double usdSum = 0;
    double fxLockedWeighted = 0;
    double fxUnlockedWeighted = 0;

    for (final r in rows) {
      final t = r.totals;
      final rowTon = t.tonTotal;
      final rowSacas = t.sacasTotal;
      final rowUsd = _usdOfRow(r);
      final rowBrl = _brlOfRow(r);

      ton += rowTon;
      sacas += rowSacas;
      usd += rowUsd;
      brl += rowBrl;

      final fxLockedPct = (t.fxLockedUsdPct == null)
          ? 0.0
          : (viewSide == DashboardViewSide.manual ? t.fxLockedUsdPct!.manual : t.fxLockedUsdPct!.system) ?? 0.0;
      final fxUnlockedPct = (t.fxUnlockedUsdPct == null)
          ? 1.0
          : (viewSide == DashboardViewSide.manual ? t.fxUnlockedUsdPct!.manual : t.fxUnlockedUsdPct!.system) ?? 1.0;

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

  // ---------- Distribuição do valor por contrato (top 6) ----------
  List<ContractMtmRow> get topRowsByBrl {
    final rows = [...(data?.rows ?? const <ContractMtmRow>[])];
    rows.sort((a, b) => brlOfRow(b).compareTo(brlOfRow(a)));
    return rows.take(rows.length > 6 ? 6 : rows.length).toList();
  }

  // ---------- Breakdown por tipo de trava ----------
  LockBreakdown breakdownForCbot() => _breakdownByUi((r) => cbotUi(r));
  LockBreakdown breakdownForPremium() => _breakdownByUi((r) => premiumUi(r));
  LockBreakdown breakdownForFx() => _breakdownByUi((r) => fxUi(r));

  LockBreakdown _breakdownByUi(LockStatusUi Function(ContractMtmRow r) getUi) {
    final rows = data?.rows ?? const <ContractMtmRow>[];

    LockAggregates locked = LockAggregates.zero;
    LockAggregates partial = LockAggregates.zero;
    LockAggregates open = LockAggregates.zero;

    for (final r in rows) {
      final ui = getUi(r);
      final t = r.totals;
      final a = LockAggregates(
        ton: t.tonTotal,
        sacas: t.sacasTotal,
        usd: _usdOfRow(r),
        brl: _brlOfRow(r),
      );

      if (ui.state == LockVisualState.locked) {
        locked = _sumAgg(locked, a);
      } else if (ui.state == LockVisualState.partial) {
        partial = _sumAgg(partial, a);
      } else {
        open = _sumAgg(open, a);
      }
    }

    return LockBreakdown(locked: locked, partial: partial, open: open);
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
