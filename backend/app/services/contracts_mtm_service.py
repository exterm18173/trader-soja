# app/services/contracts_mtm_service.py
from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime, timezone
from decimal import Decimal
from typing import Iterable

from fastapi import HTTPException
from sqlalchemy import and_, func
from sqlalchemy.orm import Session

from app.models.contract import Contract
from app.models.hedge_cbot import HedgeCbot
from app.models.hedge_premium import HedgePremium
from app.models.hedge_fx import HedgeFx

from app.models.cbot_quote import CbotQuote
from app.models.fx_quote import FxQuote
from app.models.fx_manual_point import FxManualPoint

from app.schemas.contracts_mtm import (
    ContractBrief,
    ContractsMtmResponse,
    ContractMtmRow,
    LocksInfo,
    LockCbot,
    LockPremium,
    LockFx,
    QuotesInfo,
    CbotQuoteBrief,
    FxQuoteBrief,
    FxManualBrief,
    Valuation,
    ValuationSide,
    UsedComponent,
    ContractTotals,
    TotalsSide,
    TotalsModeSide,
)

# --- Constantes de conversão (SOJA) ---
SOY_BU_KG = 27.2155
SACA_KG = 60.0

BUSHELS_PER_SACA = SACA_KG / SOY_BU_KG
SACAS_PER_TON = 1000.0 / SACA_KG
TON_PER_BU = SOY_BU_KG / 1000.0


def _to_float(v) -> float | None:
    if v is None:
        return None
    if isinstance(v, Decimal):
        return float(v)
    if isinstance(v, (int, float)):
        return float(v)
    try:
        return float(v)
    except Exception:
        return None


def _first_day_month(d: date) -> date:
    return date(d.year, d.month, 1)


def _parse_ref_mes(s: str | None) -> date | None:
    if not s:
        return None
    try:
        y, m, dd = map(int, s.split("-"))
        return date(y, m, dd)
    except Exception:
        raise HTTPException(status_code=400, detail="ref_mes inválido (use YYYY-MM-01)")


@dataclass
class _LatestByKey:
    map: dict


class ContractsMtmService:
    # =========================
    # Public
    # =========================
    def contracts_mtm(
        self,
        db: Session,
        farm_id: int,
        mode: str,
        only_open: bool,
        ref_mes: str | None,
        default_symbol: str,
        limit: int,
    ) -> ContractsMtmResponse:
        forced_ref_mes = _parse_ref_mes(ref_mes)

        q = db.query(Contract).filter(Contract.farm_id == farm_id)
        if only_open:
            q = q.filter(Contract.status == "ABERTO")
        contracts = q.order_by(Contract.id.desc()).limit(limit).all()

        if not contracts:
            return ContractsMtmResponse(
                farm_id=farm_id,
                as_of_ts=datetime.now(timezone.utc),
                mode=mode,
                fx_ref_mes=forced_ref_mes,
                rows=[],
            )

        contract_ids = [c.id for c in contracts]

        last_cbot = self._latest_hedge_cbot_by_contract(db, contract_ids)
        last_prem = self._latest_hedge_premium_by_contract(db, contract_ids)
        last_fx = self._latest_hedge_fx_by_contract(db, contract_ids)

        symbols_needed: set[str] = set()
        refmes_needed: set[date] = set()

        for c in contracts:
            hc = last_cbot.map.get(c.id)
            symbol = (getattr(hc, "symbol", None) or default_symbol).strip()
            symbols_needed.add(symbol)

            rm = forced_ref_mes or _first_day_month(c.data_entrega)
            refmes_needed.add(rm)

        latest_cbot_quote = self._latest_cbot_by_symbol(db, farm_id, symbols_needed)
        latest_fx_system = self._latest_fx_quote_by_ref_mes(db, farm_id, refmes_needed)
        latest_fx_manual = self._latest_fx_manual_by_ref_mes(db, farm_id, refmes_needed)

        as_of_ts = datetime.now(timezone.utc)
        rows: list[ContractMtmRow] = []

        for c in contracts:
            vol_total_ton = max(float(c.volume_total_ton or 0.0), 0.0)

            # ✅ evita "250000.00000000003"
            sacas_total = float(round(vol_total_ton * SACAS_PER_TON, 0))

            hc: HedgeCbot | None = last_cbot.map.get(c.id)
            hp: HedgePremium | None = last_prem.map.get(c.id)
            hf: HedgeFx | None = last_fx.map.get(c.id)

            symbol = (getattr(hc, "symbol", None) or default_symbol).strip()
            rm = forced_ref_mes or _first_day_month(c.data_entrega)

            cq: CbotQuote | None = latest_cbot_quote.map.get(symbol)
            fx_sys: FxQuote | None = latest_fx_system.map.get(rm)
            fx_man: FxManualPoint | None = latest_fx_manual.map.get(rm)

            cbot_cov = self._coverage_pct(getattr(hc, "volume_ton", None), vol_total_ton) if hc else 0.0
            prem_cov = self._coverage_pct(getattr(hp, "volume_ton", None), vol_total_ton) if hp else 0.0
            fx_cov = self._coverage_pct(getattr(hf, "volume_ton", None), vol_total_ton) if hf else 0.0

            quotes = QuotesInfo(
                cbot_system=(
                    CbotQuoteBrief(
                        symbol=symbol,
                        capturado_em=cq.capturado_em,
                        cents_per_bu=self._r(float(cq.price_usd_per_bu), 4),
                    )
                    if cq
                    else None
                ),
                fx_system=(
                    FxQuoteBrief(
                        capturado_em=fx_sys.capturado_em,
                        ref_mes=fx_sys.ref_mes,
                        brl_per_usd=self._r(float(fx_sys.brl_per_usd), 6),  # taxa pode ser 6
                        source=getattr(fx_sys, "source", "system"),
                    )
                    if fx_sys
                    else None
                ),
                fx_manual=(
                    FxManualBrief(
                        captured_at=fx_man.captured_at,
                        ref_mes=fx_man.ref_mes,
                        brl_per_usd=self._r(float(fx_man.fx), 6),
                        source="manual",
                    )
                    if fx_man
                    else None
                ),
            )

            locked_cents_raw = _to_float(getattr(hc, "cbot_usd_per_bu", None)) if hc else None
            quote_cents_hint = _to_float(getattr(cq, "price_usd_per_bu", None))

            locked_cents = (
                self._normalize_cbot_cents(locked_cents_raw, quote_cents_hint)
                if locked_cents_raw is not None
                else None
            )
            live_cents = (
                self._normalize_cbot_cents(quote_cents_hint, quote_cents_hint)
                if quote_cents_hint is not None
                else None
            )

            locks = LocksInfo(
                cbot=LockCbot(
                    locked=hc is not None,
                    coverage_pct=self._r(cbot_cov, 6),
                    locked_cents_per_bu=self._r(locked_cents, 4),
                    symbol=symbol,
                    ref_mes=getattr(hc, "ref_mes", None) if hc else None,
                ),
                premium=LockPremium(
                    locked=hp is not None,
                    coverage_pct=self._r(prem_cov, 6),
                    premium_value=self._r(_to_float(getattr(hp, "premium_value", None)), 6) if hp else None,
                    premium_unit=getattr(hp, "premium_unit", None) if hp else None,
                ),
                fx=LockFx(
                    locked=hf is not None,
                    coverage_pct=self._r(fx_cov, 6),
                    brl_per_usd=self._r(_to_float(getattr(hf, "brl_per_usd", None)), 6) if hf else None,
                    tipo=getattr(hf, "tipo", None) if hf else None,
                    usd_amount=self._r(_to_float(getattr(hf, "usd_amount", None)), 4) if hf else None,
                ),
            )

            # ---- USD/saca efetivo (CBOT+Premium) ----
            locked_usd_per_bu = self._cbot_cents_to_usd_per_bu(locked_cents)
            live_usd_per_bu = self._cbot_cents_to_usd_per_bu(live_cents)

            cbot_effective = self._mix_by_coverage(cbot_cov, locked_usd_per_bu, live_usd_per_bu)

            prem_locked = self._premium_to_usd_per_bu(hp)
            prem_effective = self._mix_by_coverage(prem_cov, prem_locked, 0.0) or 0.0

            usd_per_bu_total = (cbot_effective + prem_effective) if cbot_effective is not None else None
            usd_per_saca = (usd_per_bu_total * BUSHELS_PER_SACA) if usd_per_bu_total is not None else None

            usd_total_contract = (
                (usd_per_saca * sacas_total) if (usd_per_saca is not None and sacas_total > 0) else None
            )

            # ---- FX mix por system/manual, com breakdown separado ----
            fx_locked_rate = _to_float(getattr(hf, "brl_per_usd", None)) if hf else None
            fx_locked_usd_amount = _to_float(getattr(hf, "usd_amount", None)) if hf else None

            fx_sys_live = _to_float(getattr(fx_sys, "brl_per_usd", None))
            fx_man_live = _to_float(getattr(fx_man, "fx", None))

            brl_per_saca_system, lock_usd_sys, unlock_usd_sys, mode_sys = self._fx_brl_per_saca_with_breakdown(
                usd_per_saca=usd_per_saca,
                sacas_total=sacas_total,
                fx_locked_rate=fx_locked_rate,
                fx_locked_usd_amount=fx_locked_usd_amount,
                fx_live_rate=fx_sys_live,
                fx_cov_fallback=fx_cov,
            )
            brl_per_saca_manual, lock_usd_man, unlock_usd_man, mode_man = self._fx_brl_per_saca_with_breakdown(
                usd_per_saca=usd_per_saca,
                sacas_total=sacas_total,
                fx_locked_rate=fx_locked_rate,
                fx_locked_usd_amount=fx_locked_usd_amount,
                fx_live_rate=fx_man_live,
                fx_cov_fallback=fx_cov,
            )

            brl_total_system = (
                (brl_per_saca_system * sacas_total) if (brl_per_saca_system is not None and sacas_total > 0) else None
            )
            brl_total_manual = (
                (brl_per_saca_manual * sacas_total) if (brl_per_saca_manual is not None and sacas_total > 0) else None
            )

            fx_eff_system = self._safe_div(brl_per_saca_system, usd_per_saca)
            fx_eff_manual = self._safe_div(brl_per_saca_manual, usd_per_saca)

            valuation = Valuation(
                usd_per_saca=ValuationSide(
                    system=self._r(usd_per_saca, 4) if mode in ("system", "both") else None,
                    manual=self._r(usd_per_saca, 4) if mode in ("manual", "both") else None,
                ),
                brl_per_saca=ValuationSide(
                    system=self._r(brl_per_saca_system, 4) if mode in ("system", "both") else None,
                    manual=self._r(brl_per_saca_manual, 4) if mode in ("manual", "both") else None,
                ),
                components={
                    "cbot_locked_usd_per_bu": UsedComponent(
                        system=self._r(locked_usd_per_bu, 6),
                        manual=self._r(locked_usd_per_bu, 6),
                    ),
                    "cbot_live_usd_per_bu": UsedComponent(
                        system=self._r(live_usd_per_bu, 6),
                        manual=self._r(live_usd_per_bu, 6),
                    ),
                    "cbot_effective_usd_per_bu": UsedComponent(
                        system=self._r(cbot_effective, 6),
                        manual=self._r(cbot_effective, 6),
                    ),
                    "premium_locked_usd_per_bu": UsedComponent(
                        system=self._r(prem_locked, 6),
                        manual=self._r(prem_locked, 6),
                    ),
                    "premium_effective_usd_per_bu": UsedComponent(
                        system=self._r(prem_effective, 6),
                        manual=self._r(prem_effective, 6),
                    ),
                    "fx_locked_brl_per_usd": UsedComponent(
                        system=self._r(fx_locked_rate, 6),
                        manual=self._r(fx_locked_rate, 6),
                    ),
                    "fx_locked_usd_amount": UsedComponent(
                        system=self._r(fx_locked_usd_amount, 4),
                        manual=self._r(fx_locked_usd_amount, 4),
                    ),
                    "fx_live_brl_per_usd": UsedComponent(
                        system=self._r(fx_sys_live, 6),
                        manual=self._r(fx_man_live, 6),
                    ),
                    "fx_effective_brl_per_usd": UsedComponent(
                        system=self._r(fx_eff_system, 6),
                        manual=self._r(fx_eff_manual, 6),
                    ),
                },
            )

            # ---- Percentuais (sempre, mesmo se BRL for None) ----
            lock_pct_sys = self._safe_pct(lock_usd_sys, usd_total_contract)
            unlock_pct_sys = self._safe_pct(unlock_usd_sys, usd_total_contract)
            lock_pct_man = self._safe_pct(lock_usd_man, usd_total_contract)
            unlock_pct_man = self._safe_pct(unlock_usd_man, usd_total_contract)

            # ✅ totals SEM "gating" por mode (para não virar null sem necessidade)
            totals = ContractTotals(
                ton_total=self._r(vol_total_ton, 4) or 0.0,
                sacas_total=self._r(sacas_total, 0) or 0.0,
                usd_total_contract=self._r(usd_total_contract, 4),
                brl_total_contract=TotalsSide(
                    system=self._r(brl_total_system, 4) if mode in ("system", "both") else None,
                    manual=self._r(brl_total_manual, 4) if mode in ("manual", "both") else None,
                ),
                fx_locked_usd_used=TotalsSide(
                    system=self._r(lock_usd_sys, 4),
                    manual=self._r(lock_usd_man, 4),
                ),
                fx_unlocked_usd_used=TotalsSide(
                    system=self._r(unlock_usd_sys, 4),
                    manual=self._r(unlock_usd_man, 4),
                ),
                fx_lock_mode=TotalsModeSide(
                    system=mode_sys,
                    manual=mode_man,
                ),
                fx_locked_usd_pct=TotalsSide(
                    system=self._r(lock_pct_sys, 6),
                    manual=self._r(lock_pct_man, 6),
                ),
                fx_unlocked_usd_pct=TotalsSide(
                    system=self._r(unlock_pct_sys, 6),
                    manual=self._r(unlock_pct_man, 6),
                ),
            )

            rows.append(
                ContractMtmRow(
                    contract=ContractBrief.from_orm(c),
                    locks=locks,
                    quotes=quotes,
                    valuation=valuation,
                    totals=totals,
                )
            )

        return ContractsMtmResponse(
            farm_id=farm_id,
            as_of_ts=as_of_ts,
            mode=mode,
            fx_ref_mes=forced_ref_mes,
            rows=rows,
        )

    # =========================
    # FX breakdown
    # =========================
    def _fx_brl_per_saca_with_breakdown(
        self,
        usd_per_saca: float | None,
        sacas_total: float,
        fx_locked_rate: float | None,
        fx_locked_usd_amount: float | None,
        fx_live_rate: float | None,
        fx_cov_fallback: float,
    ) -> tuple[float | None, float | None, float | None, str]:
        if usd_per_saca is None or sacas_total <= 0:
            return (None, None, None, "none")

        usd_total = usd_per_saca * sacas_total

        # ✅ Se não há NENHUMA taxa (nem live nem locked), não dá BRL,
        # mas devolve breakdown USD consistente:
        if fx_live_rate is None and fx_locked_rate is None:
            return (None, 0.0, usd_total, "none")

        # ✅ CASO 0: não existe trava FX => 100% live e mode none
        if fx_locked_rate is None and fx_locked_usd_amount is None:
            if fx_live_rate is None:
                return (None, 0.0, usd_total, "none")
            brl_total = usd_total * fx_live_rate
            return (brl_total / sacas_total, 0.0, usd_total, "none")

        # ✅ CASO 1: usd_amount travado
        if fx_locked_usd_amount is not None and fx_locked_rate is not None and usd_total > 0:
            locked_usd = max(0.0, min(fx_locked_usd_amount, usd_total))
            unlocked_usd = usd_total - locked_usd

            live = fx_live_rate if fx_live_rate is not None else fx_locked_rate
            brl_total = (locked_usd * fx_locked_rate) + (unlocked_usd * live)
            return (brl_total / sacas_total, locked_usd, unlocked_usd, "usd_amount")

        # ✅ CASO 2: coverage só faz sentido se tem taxa travada
        if fx_locked_rate is None:
            if fx_live_rate is None:
                return (None, 0.0, usd_total, "none")
            brl_total = usd_total * fx_live_rate
            return (brl_total / sacas_total, 0.0, usd_total, "none")

        fx_eff = self._mix_by_coverage(fx_cov_fallback, fx_locked_rate, fx_live_rate)
        if fx_eff is None:
            # mantém breakdown coerente (sem taxa efetiva não dá BRL)
            return (None, 0.0, usd_total, "none")

        cov = float(max(0.0, min(1.0, fx_cov_fallback)))
        locked_usd = usd_total * cov
        unlocked_usd = usd_total - locked_usd

        return (usd_per_saca * fx_eff, locked_usd, unlocked_usd, "coverage")

    # =========================
    # Helpers
    # =========================
    def _safe_pct(self, part: float | None, total: float | None) -> float | None:
        if part is None or total is None:
            return None
        if abs(total) < 1e-12:
            return None
        return max(0.0, min(1.0, part / total))

    def _r(self, v: float | None, nd: int) -> float | None:
        if v is None:
            return None
        try:
            return round(float(v), nd)
        except Exception:
            return None

    def _safe_div(self, a: float | None, b: float | None) -> float | None:
        if a is None or b is None:
            return None
        if abs(b) < 1e-12:
            return None
        return a / b

    def _mix_by_coverage(self, cov: float, locked: float | None, live: float | None) -> float | None:
        cov = float(cov or 0.0)
        cov = 0.0 if cov < 0 else 1.0 if cov > 1 else cov

        if cov >= 0.999999:
            return locked
        if cov <= 0.000001:
            return live

        if locked is None and live is None:
            return None
        if locked is None:
            return live
        if live is None:
            return locked

        return (cov * locked) + ((1.0 - cov) * live)

    def _cbot_cents_to_usd_per_bu(self, cents_per_bu: float | None) -> float | None:
        if cents_per_bu is None:
            return None
        return float(cents_per_bu) / 100.0

    def _premium_to_usd_per_bu(self, hp: HedgePremium | None) -> float:
        if not hp:
            return 0.0
        v = _to_float(getattr(hp, "premium_value", None))
        unit = (getattr(hp, "premium_unit", None) or "").strip().upper()
        if v is None:
            return 0.0
        if unit == "USD_BU":
            return float(v)
        if unit == "USD_TON":
            return float(v) * TON_PER_BU
        return 0.0

    def _coverage_pct(self, hedge_vol_ton, contract_vol_total_ton: float) -> float:
        hv = _to_float(hedge_vol_ton) or 0.0
        if contract_vol_total_ton <= 0:
            return 0.0
        pct = hv / contract_vol_total_ton
        return float(max(0.0, min(1.0, pct)))

    # normaliza caso algum hedge tenha sido salvo em USD/bu e quote venha em cents/bu (ou vice-versa)
    def _normalize_cbot_cents(self, v_cents: float | None, quote_cents_hint: float | None) -> float | None:
        if v_cents is None:
            return None
        if quote_cents_hint is None:
            return v_cents
        candidates = [v_cents, v_cents * 100.0, v_cents * 1000.0]
        best = min(candidates, key=lambda x: abs(x - quote_cents_hint))
        if quote_cents_hint > 0:
            ratio = best / quote_cents_hint
            if ratio < 0.1 or ratio > 10:
                return v_cents
        return best

    # =========================
    # Queries (latest)
    # =========================
    def _latest_hedge_cbot_by_contract(self, db: Session, contract_ids: list[int]) -> _LatestByKey:
        if not contract_ids:
            return _LatestByKey(map={})
        sub = (
            db.query(HedgeCbot.contract_id.label("contract_id"), func.max(HedgeCbot.executado_em).label("mx"))
            .filter(HedgeCbot.contract_id.in_(contract_ids))
            .group_by(HedgeCbot.contract_id)
            .subquery()
        )
        rows = (
            db.query(HedgeCbot)
            .join(sub, and_(HedgeCbot.contract_id == sub.c.contract_id, HedgeCbot.executado_em == sub.c.mx))
            .all()
        )
        return _LatestByKey(map={r.contract_id: r for r in rows})

    def _latest_hedge_premium_by_contract(self, db: Session, contract_ids: list[int]) -> _LatestByKey:
        if not contract_ids:
            return _LatestByKey(map={})
        sub = (
            db.query(HedgePremium.contract_id.label("contract_id"), func.max(HedgePremium.executado_em).label("mx"))
            .filter(HedgePremium.contract_id.in_(contract_ids))
            .group_by(HedgePremium.contract_id)
            .subquery()
        )
        rows = (
            db.query(HedgePremium)
            .join(sub, and_(HedgePremium.contract_id == sub.c.contract_id, HedgePremium.executado_em == sub.c.mx))
            .all()
        )
        return _LatestByKey(map={r.contract_id: r for r in rows})

    def _latest_hedge_fx_by_contract(self, db: Session, contract_ids: list[int]) -> _LatestByKey:
        if not contract_ids:
            return _LatestByKey(map={})
        sub = (
            db.query(HedgeFx.contract_id.label("contract_id"), func.max(HedgeFx.executado_em).label("mx"))
            .filter(HedgeFx.contract_id.in_(contract_ids))
            .group_by(HedgeFx.contract_id)
            .subquery()
        )
        rows = (
            db.query(HedgeFx)
            .join(sub, and_(HedgeFx.contract_id == sub.c.contract_id, HedgeFx.executado_em == sub.c.mx))
            .all()
        )
        return _LatestByKey(map={r.contract_id: r for r in rows})

    def _latest_cbot_by_symbol(self, db: Session, farm_id: int, symbols: Iterable[str]) -> _LatestByKey:
        symbols = {s.strip() for s in symbols if s and s.strip()}
        if not symbols:
            return _LatestByKey(map={})
        sub = (
            db.query(CbotQuote.symbol.label("symbol"), func.max(CbotQuote.capturado_em).label("mx"))
            .filter(CbotQuote.farm_id == farm_id, CbotQuote.symbol.in_(list(symbols)))
            .group_by(CbotQuote.symbol)
            .subquery()
        )
        rows = (
            db.query(CbotQuote)
            .join(sub, and_(CbotQuote.symbol == sub.c.symbol, CbotQuote.capturado_em == sub.c.mx))
            .filter(CbotQuote.farm_id == farm_id)
            .all()
        )
        return _LatestByKey(map={r.symbol: r for r in rows})

    def _latest_fx_quote_by_ref_mes(self, db: Session, farm_id: int, ref_meses: Iterable[date]) -> _LatestByKey:
        ref_meses = {rm for rm in ref_meses if rm}
        if not ref_meses:
            return _LatestByKey(map={})
        sub = (
            db.query(FxQuote.ref_mes.label("ref_mes"), func.max(FxQuote.capturado_em).label("mx"))
            .filter(FxQuote.farm_id == farm_id, FxQuote.ref_mes.in_(list(ref_meses)))
            .group_by(FxQuote.ref_mes)
            .subquery()
        )
        rows = (
            db.query(FxQuote)
            .join(sub, and_(FxQuote.ref_mes == sub.c.ref_mes, FxQuote.capturado_em == sub.c.mx))
            .filter(FxQuote.farm_id == farm_id)
            .all()
        )
        return _LatestByKey(map={r.ref_mes: r for r in rows})

    def _latest_fx_manual_by_ref_mes(self, db: Session, farm_id: int, ref_meses: Iterable[date]) -> _LatestByKey:
        ref_meses = {rm for rm in ref_meses if rm}
        if not ref_meses:
            return _LatestByKey(map={})
        sub = (
            db.query(FxManualPoint.ref_mes.label("ref_mes"), func.max(FxManualPoint.captured_at).label("mx"))
            .filter(FxManualPoint.farm_id == farm_id, FxManualPoint.ref_mes.in_(list(ref_meses)))
            .group_by(FxManualPoint.ref_mes)
            .subquery()
        )
        rows = (
            db.query(FxManualPoint)
            .join(sub, and_(FxManualPoint.ref_mes == sub.c.ref_mes, FxManualPoint.captured_at == sub.c.mx))
            .filter(FxManualPoint.farm_id == farm_id)
            .all()
        )
        return _LatestByKey(map={r.ref_mes: r for r in rows})
