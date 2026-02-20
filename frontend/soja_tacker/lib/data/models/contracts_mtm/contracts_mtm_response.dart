// lib/data/models/contracts_mtm/contracts_mtm_response.dart
// ignore_for_file: public_member_api_docs

class ContractsMtmResponse {
  final int farmId;
  final DateTime asOfTs;
  final String mode; // system|manual|both
  final DateTime? fxRefMes; // backend: YYYY-MM-30 (date)
  final bool noLocks;

  final List<ContractMtmRow> rows;

  ContractsMtmResponse({
    required this.farmId,
    required this.asOfTs,
    required this.mode,
    required this.fxRefMes,
    required this.noLocks,
    required this.rows,
  });

  factory ContractsMtmResponse.fromJson(Map<String, dynamic> json) {
    return ContractsMtmResponse(
      farmId: (json['farm_id'] as num).toInt(),
      asOfTs: DateTime.parse(json['as_of_ts'] as String),
      mode: (json['mode'] as String?) ?? 'both',
      fxRefMes: json['fx_ref_mes'] == null
          ? null
          : DateTime.parse(json['fx_ref_mes'] as String),

      // ✅ novo (se backend não mandar, fica false)
      noLocks: (json['no_locks'] as bool?) ?? false,

      rows: ((json['rows'] as List?) ?? const [])
          .map(
            (e) => ContractMtmRow.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(),
    );
  }
}

/// ----------------- Row -----------------
class ContractMtmRow {
  final ContractBrief contract;
  final LocksInfo locks;
  final QuotesInfo quotes;
  final Valuation valuation;
  final ContractTotals totals;

  // ✅ novos (podem vir null)
  final ContractTotalsView? totalsView;
  final RowFilterMeta? filterMeta;

  ContractMtmRow({
    required this.contract,
    required this.locks,
    required this.quotes,
    required this.valuation,
    required this.totals,
    required this.totalsView,
    required this.filterMeta,
  });

  factory ContractMtmRow.fromJson(Map<String, dynamic> json) {
    return ContractMtmRow(
      contract: ContractBrief.fromJson(
        (json['contract'] as Map).cast<String, dynamic>(),
      ),
      locks: LocksInfo.fromJson((json['locks'] as Map).cast<String, dynamic>()),
      quotes: QuotesInfo.fromJson(
        (json['quotes'] as Map).cast<String, dynamic>(),
      ),
      valuation: Valuation.fromJson(
        (json['valuation'] as Map).cast<String, dynamic>(),
      ),
      totals: ContractTotals.fromJson(
        (json['totals'] as Map).cast<String, dynamic>(),
      ),
      totalsView: json['totals_view'] == null
          ? null
          : ContractTotalsView.fromJson(
              (json['totals_view'] as Map).cast<String, dynamic>(),
            ),
      filterMeta: json['filter_meta'] == null
          ? null
          : RowFilterMeta.fromJson(
              (json['filter_meta'] as Map).cast<String, dynamic>(),
            ),
    );
  }
}

/// ----------------- ContractBrief -----------------
class ContractBrief {
  final int id;
  final String produto;
  final String tipoPrecificacao; // FIXO_BRL | ...
  final DateTime dataEntrega; // yyyy-mm-dd
  final String status; // ABERTO|...
  final double volumeTotalTon;

  final double? precoFixoBrlValue;
  final String? precoFixoBrlUnit;

  final double? freteBrlTotal;
  final double? freteBrlPerTon;
  final String? freteObs;
  final String? observacao;

  ContractBrief({
    required this.id,
    required this.produto,
    required this.tipoPrecificacao,
    required this.dataEntrega,
    required this.status,
    required this.volumeTotalTon,
    this.precoFixoBrlValue,
    this.precoFixoBrlUnit,
    this.freteBrlTotal,
    this.freteBrlPerTon,
    this.freteObs,
    this.observacao,
  });

  static double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
  static String? _s(dynamic v) => v?.toString();

  factory ContractBrief.fromJson(Map<String, dynamic> json) {
    return ContractBrief(
      id: (json['id'] as num).toInt(),
      produto: (json['produto'] as String?) ?? '',
      tipoPrecificacao: (json['tipo_precificacao'] as String?) ?? '',
      dataEntrega: DateTime.parse(json['data_entrega'] as String),
      status: (json['status'] as String?) ?? '',
      volumeTotalTon: (json['volume_total_ton'] as num?)?.toDouble() ?? 0.0,
      precoFixoBrlValue: _d(json['preco_fixo_brl_value']),
      precoFixoBrlUnit: _s(json['preco_fixo_brl_unit']),
      freteBrlTotal: _d(json['frete_brl_total']),
      freteBrlPerTon: _d(json['frete_brl_per_ton']),
      freteObs: _s(json['frete_obs']),
      observacao: _s(json['observacao']),
    );
  }
}

/// ----------------- Locks -----------------
class LocksInfo {
  final LockCbot cbot;
  final LockPremium premium;
  final LockFx fx;

  LocksInfo({required this.cbot, required this.premium, required this.fx});

  factory LocksInfo.fromJson(Map<String, dynamic> json) {
    return LocksInfo(
      cbot: LockCbot.fromJson((json['cbot'] as Map).cast<String, dynamic>()),
      premium: LockPremium.fromJson(
        (json['premium'] as Map).cast<String, dynamic>(),
      ),
      fx: LockFx.fromJson((json['fx'] as Map).cast<String, dynamic>()),
    );
  }
}

class LockCbot {
  final bool locked;
  final double coveragePct; // 0..1
  final double? lockedCentsPerBu;
  final String? symbol;
  final DateTime? refMes;

  LockCbot({
    required this.locked,
    required this.coveragePct,
    required this.lockedCentsPerBu,
    required this.symbol,
    required this.refMes,
  });

  factory LockCbot.fromJson(Map<String, dynamic> json) {
    return LockCbot(
      locked: (json['locked'] as bool?) ?? false,
      coveragePct: (json['coverage_pct'] as num?)?.toDouble() ?? 0.0,
      lockedCentsPerBu: (json['locked_cents_per_bu'] as num?)?.toDouble(),
      symbol: json['symbol']?.toString(),
      refMes: json['ref_mes'] == null
          ? null
          : DateTime.parse(json['ref_mes'] as String),
    );
  }
}

class LockPremium {
  final bool locked;
  final double coveragePct;
  final double? premiumValue;
  final String? premiumUnit;

  LockPremium({
    required this.locked,
    required this.coveragePct,
    required this.premiumValue,
    required this.premiumUnit,
  });

  factory LockPremium.fromJson(Map<String, dynamic> json) {
    return LockPremium(
      locked: (json['locked'] as bool?) ?? false,
      coveragePct: (json['coverage_pct'] as num?)?.toDouble() ?? 0.0,
      premiumValue: (json['premium_value'] as num?)?.toDouble(),
      premiumUnit: json['premium_unit']?.toString(),
    );
  }
}

class LockFx {
  final bool locked;
  final double coveragePct;
  final double? brlPerUsd;
  final String? tipo;
  final double? usdAmount;

  LockFx({
    required this.locked,
    required this.coveragePct,
    required this.brlPerUsd,
    required this.tipo,
    required this.usdAmount,
  });

  factory LockFx.fromJson(Map<String, dynamic> json) {
    return LockFx(
      locked: (json['locked'] as bool?) ?? false,
      coveragePct: (json['coverage_pct'] as num?)?.toDouble() ?? 0.0,
      brlPerUsd: (json['brl_per_usd'] as num?)?.toDouble(),
      tipo: json['tipo']?.toString(),
      usdAmount: (json['usd_amount'] as num?)?.toDouble(),
    );
  }
}

/// ----------------- Quotes -----------------
class QuotesInfo {
  final CbotQuoteBrief? cbotSystem;
  final FxQuoteBrief? fxSystem;
  final FxManualBrief? fxManual;

  QuotesInfo({
    required this.cbotSystem,
    required this.fxSystem,
    required this.fxManual,
  });

  factory QuotesInfo.fromJson(Map<String, dynamic> json) {
    return QuotesInfo(
      cbotSystem: json['cbot_system'] == null
          ? null
          : CbotQuoteBrief.fromJson(
              (json['cbot_system'] as Map).cast<String, dynamic>(),
            ),
      fxSystem: json['fx_system'] == null
          ? null
          : FxQuoteBrief.fromJson(
              (json['fx_system'] as Map).cast<String, dynamic>(),
            ),
      fxManual: json['fx_manual'] == null
          ? null
          : FxManualBrief.fromJson(
              (json['fx_manual'] as Map).cast<String, dynamic>(),
            ),
    );
  }
}

class CbotQuoteBrief {
  final String symbol;
  final DateTime capturadoEm;
  final double centsPerBu;
  final String unit;

  CbotQuoteBrief({
    required this.symbol,
    required this.capturadoEm,
    required this.centsPerBu,
    required this.unit,
  });

  factory CbotQuoteBrief.fromJson(Map<String, dynamic> json) {
    return CbotQuoteBrief(
      symbol: (json['symbol'] as String?) ?? 'ZS=F',
      capturadoEm: DateTime.parse(json['capturado_em'] as String),
      centsPerBu: (json['cents_per_bu'] as num?)?.toDouble() ?? 0.0,
      unit: (json['unit'] as String?) ?? 'cents/bu',
    );
  }
}

class FxQuoteBrief {
  final DateTime? capturadoEm; // ✅ era DateTime
  final DateTime refMes;
  final double brlPerUsd;
  final String source;

  FxQuoteBrief({
    required this.capturadoEm,
    required this.refMes,
    required this.brlPerUsd,
    required this.source,
  });

  factory FxQuoteBrief.fromJson(Map<String, dynamic> json) {
    return FxQuoteBrief(
      capturadoEm: json['capturado_em'] == null ? null : DateTime.parse(json['capturado_em'] as String),
      refMes: DateTime.parse(json['ref_mes'] as String),
      brlPerUsd: (json['brl_per_usd'] as num?)?.toDouble() ?? 0.0,
      source: (json['source'] as String?) ?? 'system',
    );
  }
}

class FxManualBrief {
  final DateTime? capturedAt; // ✅ era DateTime
  final DateTime refMes;
  final double brlPerUsd;
  final String source;

  FxManualBrief({
    required this.capturedAt,
    required this.refMes,
    required this.brlPerUsd,
    required this.source,
  });

  factory FxManualBrief.fromJson(Map<String, dynamic> json) {
    return FxManualBrief(
      capturedAt: json['captured_at'] == null ? null : DateTime.parse(json['captured_at'] as String),
      refMes: DateTime.parse(json['ref_mes'] as String),
      brlPerUsd: (json['brl_per_usd'] as num?)?.toDouble() ?? 0.0,
      source: (json['source'] as String?) ?? 'manual',
    );
  }
}


/// ----------------- Valuation -----------------
class Valuation {
  final ValuationSide usdPerSaca;
  final ValuationSide brlPerSaca;
  final Map<String, UsedComponent> components;

  Valuation({
    required this.usdPerSaca,
    required this.brlPerSaca,
    required this.components,
  });

  factory Valuation.fromJson(Map<String, dynamic> json) {
    final comps = <String, UsedComponent>{};
    final raw =
        (json['components'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    raw.forEach((k, v) {
      comps[k] = UsedComponent.fromJson((v as Map).cast<String, dynamic>());
    });

    return Valuation(
      usdPerSaca: ValuationSide.fromJson(
        (json['usd_per_saca'] as Map).cast<String, dynamic>(),
      ),
      brlPerSaca: ValuationSide.fromJson(
        (json['brl_per_saca'] as Map).cast<String, dynamic>(),
      ),
      components: comps,
    );
  }
}

class ValuationSide {
  final double? system;
  final double? manual;

  ValuationSide({required this.system, required this.manual});

  factory ValuationSide.fromJson(Map<String, dynamic> json) {
    return ValuationSide(
      system: (json['system'] as num?)?.toDouble(),
      manual: (json['manual'] as num?)?.toDouble(),
    );
  }
}

class UsedComponent {
  final double? system;
  final double? manual;

  UsedComponent({required this.system, required this.manual});

  factory UsedComponent.fromJson(Map<String, dynamic> json) {
    return UsedComponent(
      system: (json['system'] as num?)?.toDouble(),
      manual: (json['manual'] as num?)?.toDouble(),
    );
  }
}

/// ----------------- Totals -----------------
class ContractTotals {
  final double tonTotal;
  final double sacasTotal;
  final double? usdTotalContract;

  final TotalsSide brlTotalContract;
  final TotalsSide fxLockedUsdUsed;
  final TotalsSide fxUnlockedUsdUsed;
  final TotalsModeSide fxLockMode;

  final TotalsSide fxLockedUsdPct;
  final TotalsSide fxUnlockedUsdPct;

  ContractTotals({
    required this.tonTotal,
    required this.sacasTotal,
    required this.usdTotalContract,
    required this.brlTotalContract,
    required this.fxLockedUsdUsed,
    required this.fxUnlockedUsdUsed,
    required this.fxLockMode,
    required this.fxLockedUsdPct,
    required this.fxUnlockedUsdPct,
  });

  factory ContractTotals.fromJson(Map<String, dynamic> json) {
    return ContractTotals(
      tonTotal: (json['ton_total'] as num?)?.toDouble() ?? 0.0,
      sacasTotal: (json['sacas_total'] as num?)?.toDouble() ?? 0.0,
      usdTotalContract: (json['usd_total_contract'] as num?)?.toDouble(),
      brlTotalContract: TotalsSide.fromJson(
        (json['brl_total_contract'] as Map).cast<String, dynamic>(),
      ),
      fxLockedUsdUsed: TotalsSide.fromJson(
        (json['fx_locked_usd_used'] as Map).cast<String, dynamic>(),
      ),
      fxUnlockedUsdUsed: TotalsSide.fromJson(
        (json['fx_unlocked_usd_used'] as Map).cast<String, dynamic>(),
      ),
      fxLockMode: TotalsModeSide.fromJson(
        (json['fx_lock_mode'] as Map).cast<String, dynamic>(),
      ),
      fxLockedUsdPct: TotalsSide.fromJson(
        (json['fx_locked_usd_pct'] as Map).cast<String, dynamic>(),
      ),
      fxUnlockedUsdPct: TotalsSide.fromJson(
        (json['fx_unlocked_usd_pct'] as Map).cast<String, dynamic>(),
      ),
    );
  }
}

class TotalsSide {
  final double? system;
  final double? manual;

  TotalsSide({required this.system, required this.manual});

  factory TotalsSide.fromJson(Map<String, dynamic> json) {
    return TotalsSide(
      system: (json['system'] as num?)?.toDouble(),
      manual: (json['manual'] as num?)?.toDouble(),
    );
  }
}

class TotalsModeSide {
  final String system;
  final String manual;

  TotalsModeSide({required this.system, required this.manual});

  factory TotalsModeSide.fromJson(Map<String, dynamic> json) {
    return TotalsModeSide(
      system: (json['system'] as String?) ?? 'none',
      manual: (json['manual'] as String?) ?? 'none',
    );
  }
}

/// ----------------- TotalsView (novo) -----------------
class ContractTotalsView {
  final double tonTotal;
  final double sacasTotal;
  final double? usdTotalContract;

  final TotalsSide brlTotalContract;
  final TotalsSide fxLockedUsdUsed;
  final TotalsSide fxUnlockedUsdUsed;

  final TotalsSide fxLockedUsdPct;
  final TotalsSide fxUnlockedUsdPct;

  ContractTotalsView({
    required this.tonTotal,
    required this.sacasTotal,
    required this.usdTotalContract,
    required this.brlTotalContract,
    required this.fxLockedUsdUsed,
    required this.fxUnlockedUsdUsed,
    required this.fxLockedUsdPct,
    required this.fxUnlockedUsdPct,
  });

  factory ContractTotalsView.fromJson(Map<String, dynamic> json) {
    return ContractTotalsView(
      tonTotal: (json['ton_total'] as num?)?.toDouble() ?? 0.0,
      sacasTotal: (json['sacas_total'] as num?)?.toDouble() ?? 0.0,
      usdTotalContract: (json['usd_total_contract'] as num?)?.toDouble(),
      brlTotalContract: TotalsSide.fromJson(
        (json['brl_total_contract'] as Map).cast<String, dynamic>(),
      ),
      fxLockedUsdUsed: TotalsSide.fromJson(
        (json['fx_locked_usd_used'] as Map).cast<String, dynamic>(),
      ),
      fxUnlockedUsdUsed: TotalsSide.fromJson(
        (json['fx_unlocked_usd_used'] as Map).cast<String, dynamic>(),
      ),
      fxLockedUsdPct: TotalsSide.fromJson(
        (json['fx_locked_usd_pct'] as Map).cast<String, dynamic>(),
      ),
      fxUnlockedUsdPct: TotalsSide.fromJson(
        (json['fx_unlocked_usd_pct'] as Map).cast<String, dynamic>(),
      ),
    );
  }
}

/// ----------------- FilterMeta (novo) -----------------
class RowFilterMeta {
  final List<String> lockTypes; // cbot|premium|fx
  final List<String> lockStates; // locked|open

  final String stateCbot;
  final String statePremium;
  final String stateFx;

  final double pctCbot;
  final double pctPremium;
  final double pctFx;

  final double lockedPct;
  final double openPct;
  final double slicePct;

  RowFilterMeta({
    required this.lockTypes,
    required this.lockStates,
    required this.stateCbot,
    required this.statePremium,
    required this.stateFx,
    required this.pctCbot,
    required this.pctPremium,
    required this.pctFx,
    required this.lockedPct,
    required this.openPct,
    required this.slicePct,
  });

  factory RowFilterMeta.fromJson(Map<String, dynamic> json) {
    List<String> ls(dynamic v) =>
        (v as List?)?.map((e) => e.toString()).toList() ?? const [];

    double d(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

    return RowFilterMeta(
      lockTypes: ls(json['lock_types']),
      lockStates: ls(json['lock_states']),
      stateCbot: (json['state_cbot'] as String?) ?? 'open',
      statePremium: (json['state_premium'] as String?) ?? 'open',
      stateFx: (json['state_fx'] as String?) ?? 'open',
      pctCbot: d(json['pct_cbot']),
      pctPremium: d(json['pct_premium']),
      pctFx: d(json['pct_fx']),
      lockedPct: d(json['locked_pct']),
      openPct: d(json['open_pct']),
      slicePct: d(json['slice_pct']),
    );
  }
}
