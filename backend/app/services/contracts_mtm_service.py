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
from app.models.fx_manual_point import FxManualPoint

from app.models.fx_model_run import FxModelRun
from app.models.fx_model_point import FxModelPoint

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

# CBOT month codes
_CBOT_MONTH_CODE = {
    1: "F",  2: "G",  3: "H",  4: "J",
    5: "K",  6: "M",  7: "N",  8: "Q",
    9: "U", 10: "V", 11: "X", 12: "Z",
}


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


def _ref_mes_month(d: date) -> date:
    """✅ seu padrão: dia 30 do mês."""
    return date(d.year, d.month, 30)


def _parse_ref_mes(s: str | None) -> date | None:
    """✅ valida YYYY-MM-30"""
    if not s:
        return None
    try:
        y, m, dd = map(int, s.split("-"))
        if dd != 30:
            raise ValueError("dia precisa ser 30")
        return date(y, m, dd)
    except Exception:
        raise HTTPException(status_code=400, detail="ref_mes inválido (use YYYY-MM-30)")


def _auto_symbol_for_ref_mes(ref_mes: date) -> str:
    """AUTO -> ZS{MonthCode}{YY}.CBT baseado no mês/ano do ref_mes."""
    code = _CBOT_MONTH_CODE.get(ref_mes.month)
    if not code:
        raise HTTPException(status_code=400, detail="ref_mes inválido para AUTO symbol")
    yy = str(ref_mes.year)[-2:]
    return f"ZS{code}{yy}.CBT"


@dataclass
class _LatestByKey:
    map: dict


@dataclass
class _FxCurveSnap:
    run: FxModelRun
    point: FxModelPoint


class ContractsMtmService:
    # =========================
    # FIXO_BRL helpers
    # =========================
    def _frete_brl_total(self, c: Contract) -> float:
        """Resolve frete total em BRL (se existir)."""
        ft = _to_float(getattr(c, "frete_brl_total", None))
        if ft is not None:
            return float(ft)

        fpt = _to_float(getattr(c, "frete_brl_per_ton", None))
        if fpt is not None:
            ton = float(c.volume_total_ton or 0.0)
            return float(fpt) * ton

        return 0.0

    def _brl_fixo_per_saca(self, c: Contract) -> float | None:
        """Preço fixo em BRL por saca. Espera normalmente BRL/sc."""
        v = _to_float(getattr(c, "preco_fixo_brl_value", None))
        u = (getattr(c, "preco_fixo_brl_unit", None) or "").strip().upper()
        if v is None:
            return None

        if u in ("BRL/SC", "BRL/SACA", "BRL_SC"):
            return float(v)

        # suporte opcional se aparecer:
        if u in ("BRL/TON", "BRL_TON"):
            return float(v) / float(SACAS_PER_TON)

        # fallback: assume por saca
        return float(v)

    # =========================
    # Main
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
        q = q.filter(Contract.produto == "SOJA")

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

        # ✅ CBOT precisa do par (symbol, ref_mes)
        cbot_pairs_needed: set[tuple[str, date]] = set()

        # ✅ FX continua por ref_mes (agora dia 30)
        refmes_needed: set[date] = set()

        for c in contracts:
            # ✅ FIXO_BRL: não precisa de CBOT/FX/PREMIO
            tipo = (getattr(c, "tipo_precificacao", None) or "").strip().upper()
            if tipo == "FIXO_BRL":
                continue

            hc = last_cbot.map.get(c.id)

            rm_fx = forced_ref_mes or _ref_mes_month(c.data_entrega)
            refmes_needed.add(rm_fx)

            rm_cbot = getattr(hc, "ref_mes", None) if hc else None
            rm_cbot = _ref_mes_month(rm_cbot) if rm_cbot else rm_fx

            symbol = (getattr(hc, "symbol", None) or default_symbol or "").strip()
            if symbol.upper() == "AUTO":
                symbol = _auto_symbol_for_ref_mes(rm_cbot)

            if symbol and rm_cbot:
                cbot_pairs_needed.add((symbol, rm_cbot))

        latest_cbot_quote = self._latest_cbot_by_symbol_ref_mes(db, farm_id, cbot_pairs_needed)
        latest_fx_curve = self._latest_fx_curve_by_ref_mes(db, farm_id, refmes_needed)
        latest_fx_manual = self._latest_fx_manual_by_ref_mes(db, farm_id, refmes_needed)

        as_of_ts = datetime.now(timezone.utc)
        rows: list[ContractMtmRow] = []

        for c in contracts:
            vol_total_ton = max(float(c.volume_total_ton or 0.0), 0.0)
            sacas_total = float(round(vol_total_ton * SACAS_PER_TON, 0))

            tipo = (getattr(c, "tipo_precificacao", None) or "").strip().upper()

            # -------------------------
            # ✅ FIXO_BRL: retorna só BRL (nada de USD/CBOT/FX/PREMIO)
            # -------------------------
            if tipo == "FIXO_BRL":
                brl_sc = self._brl_fixo_per_saca(c)
                frete_total = self._frete_brl_total(c)

                brl_total = None
                if brl_sc is not None and sacas_total > 0:
                    brl_total = (brl_sc * sacas_total) + frete_total

                rows.append(
                    ContractMtmRow(
                        contract=ContractBrief.from_orm(c),
                        locks=LocksInfo(
                            cbot=LockCbot(
                                locked=False,
                                coverage_pct=0.0,
                                locked_cents_per_bu=None,
                                symbol=None,
                                ref_mes=None,
                            ),
                            premium=LockPremium(
                                locked=False,
                                coverage_pct=0.0,
                                premium_value=None,
                                premium_unit=None,
                            ),
                            fx=LockFx(
                                locked=False,
                                coverage_pct=0.0,
                                brl_per_usd=None,
                                tipo=None,
                                usd_amount=None,
                            ),
                        ),
                        quotes=QuotesInfo(
                            cbot_system=None,
                            fx_system=None,
                            fx_manual=None,
                        ),
                        valuation=Valuation(
                            usd_per_saca=ValuationSide(system=None, manual=None),
                            brl_per_saca=ValuationSide(
                                system=self._r(brl_sc, 4),
                                manual=None,
                            ),
                            components={},  # ✅ sem componentes USD
                        ),
                        totals=ContractTotals(
                            ton_total=self._r(vol_total_ton, 4) or 0.0,
                            sacas_total=self._r(sacas_total, 0) or 0.0,
                            usd_total_contract=None,
                            brl_total_contract=TotalsSide(
                                system=self._r(brl_total, 4),
                                manual=None,
                            ),
                            fx_locked_usd_used=TotalsSide(system=None, manual=None),
                            fx_unlocked_usd_used=TotalsSide(system=None, manual=None),
                            fx_lock_mode=TotalsModeSide(system="none", manual="none"),
                            fx_locked_usd_pct=TotalsSide(system=None, manual=None),
                            fx_unlocked_usd_pct=TotalsSide(system=None, manual=None),
                        ),
                    )
                )
                continue

            # -------------------------
            # MTM normal (CBOT/PREMIO/FX)
            # -------------------------
            hc: HedgeCbot | None = last_cbot.map.get(c.id)
            hp: HedgePremium | None = last_prem.map.get(c.id)
            hf: HedgeFx | None = last_fx.map.get(c.id)

            rm_fx = forced_ref_mes or _ref_mes_month(c.data_entrega)

            rm_cbot = getattr(hc, "ref_mes", None) if hc else None
            rm_cbot = _ref_mes_month(rm_cbot) if rm_cbot else rm_fx

            symbol = (getattr(hc, "symbol", None) or default_symbol or "").strip()
            if symbol.upper() == "AUTO":
                symbol = _auto_symbol_for_ref_mes(rm_cbot)

            cq: CbotQuote | None = latest_cbot_quote.map.get((symbol, rm_cbot))

            fx_snap: _FxCurveSnap | None = latest_fx_curve.map.get(rm_fx)
            fx_man: FxManualPoint | None = latest_fx_manual.map.get(rm_fx)

            # -------------------------
            # Coverage
            # -------------------------
            cbot_cov = self._coverage_pct(getattr(hc, "volume_ton", None), vol_total_ton) if hc else 0.0
            prem_cov = self._coverage_pct(getattr(hp, "volume_ton", None), vol_total_ton) if hp else 0.0
            fx_cov = self._coverage_pct(getattr(hf, "volume_ton", None), vol_total_ton) if hf else 0.0

            # -------------------------
            # Quotes
            # -------------------------
            cq_cents = _to_float(getattr(cq, "price_usd_per_bu", None))

            fx_sys_rate = _to_float(getattr(fx_snap.point, "dolar_sint", None)) if fx_snap else None
            fx_sys_ts = getattr(fx_snap.run, "as_of_ts", None) if fx_snap else None
            fx_sys_source = f"{fx_snap.run.source}:{fx_snap.run.model_version}" if fx_snap else None

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
                        capturado_em=fx_sys_ts,
                        ref_mes=rm_fx,
                        brl_per_usd=self._r(fx_sys_rate, 6),
                        source=fx_sys_source or "curve_model",
                    )
                    if (fx_sys_rate is not None and fx_sys_ts is not None)
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

            # -------------------------
            # Locks
            # -------------------------
            locked_cents_raw = _to_float(getattr(hc, "cbot_usd_per_bu", None)) if hc else None
            quote_cents_hint = cq_cents

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
                    coverage_pct=self._r(cbot_cov, 6) or 0.0,
                    locked_cents_per_bu=self._r(locked_cents, 4),
                    symbol=symbol,
                    ref_mes=getattr(hc, "ref_mes", None) if hc else None,
                ),
                premium=LockPremium(
                    locked=hp is not None,
                    coverage_pct=self._r(prem_cov, 6) or 0.0,
                    premium_value=self._r(_to_float(getattr(hp, "premium_value", None)), 6) if hp else None,
                    premium_unit=getattr(hp, "premium_unit", None) if hp else None,
                ),
                fx=LockFx(
                    locked=hf is not None,
                    coverage_pct=self._r(fx_cov, 6) or 0.0,
                    brl_per_usd=self._r(_to_float(getattr(hf, "brl_per_usd", None)), 6) if hf else None,
                    tipo=getattr(hf, "tipo", None) if hf else None,
                    usd_amount=self._r(_to_float(getattr(hf, "usd_amount", None)), 4) if hf else None,
                ),
            )

            # -------------------------
            # USD/saca efetivo (CBOT + Premium)
            # -------------------------
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

            # -------------------------
            # FX mix system/manual
            # -------------------------
            fx_locked_rate = _to_float(getattr(hf, "brl_per_usd", None)) if hf else None
            fx_locked_usd_amount = _to_float(getattr(hf, "usd_amount", None)) if hf else None

            fx_sys_live = fx_sys_rate
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

            lock_pct_sys = self._safe_pct(lock_usd_sys, usd_total_contract)
            unlock_pct_sys = self._safe_pct(unlock_usd_sys, usd_total_contract)
            lock_pct_man = self._safe_pct(lock_usd_man, usd_total_contract)
            unlock_pct_man = self._safe_pct(unlock_usd_man, usd_total_contract)

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
                fx_lock_mode=TotalsModeSide(system=mode_sys, manual=mode_man),
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
    # FX breakdown (igual ao seu)
    # =========================
    def _fx_brl_per_saca_with_breakdown(
        self,
        usd_per_saca,
        sacas_total,
        fx_locked_rate,
        fx_locked_usd_amount,
        fx_live_rate,
        fx_cov_fallback,
    ):
        if usd_per_saca is None or sacas_total <= 0:
            return (None, None, None, "none")

        usd_total = usd_per_saca * sacas_total

        if fx_live_rate is None and fx_locked_rate is None:
            return (None, 0.0, usd_total, "none")

        if fx_locked_rate is None and fx_locked_usd_amount is None:
            if fx_live_rate is None:
                return (None, 0.0, usd_total, "none")
            brl_total = usd_total * fx_live_rate
            return (brl_total / sacas_total, 0.0, usd_total, "none")

        if fx_locked_usd_amount is not None and fx_locked_rate is not None and usd_total > 0:
            locked_usd = max(0.0, min(fx_locked_usd_amount, usd_total))
            unlocked_usd = usd_total - locked_usd

            live = fx_live_rate if fx_live_rate is not None else fx_locked_rate
            brl_total = (locked_usd * fx_locked_rate) + (unlocked_usd * live)
            return (brl_total / sacas_total, locked_usd, unlocked_usd, "usd_amount")

        if fx_locked_rate is None:
            if fx_live_rate is None:
                return (None, 0.0, usd_total, "none")
            brl_total = usd_total * fx_live_rate
            return (brl_total / sacas_total, 0.0, usd_total, "none")

        fx_eff = self._mix_by_coverage(fx_cov_fallback, fx_locked_rate, fx_live_rate)
        if fx_eff is None:
            return (None, 0.0, usd_total, "none")

        cov = float(max(0.0, min(1.0, fx_cov_fallback)))
        locked_usd = usd_total * cov
        unlocked_usd = usd_total - locked_usd

        return (usd_per_saca * fx_eff, locked_usd, unlocked_usd, "coverage")

    # =========================
    # Helpers
    # =========================
    def _safe_pct(self, part, total):
        if part is None or total is None:
            return None
        if abs(total) < 1e-12:
            return None
        return max(0.0, min(1.0, part / total))

    def _r(self, v, nd):
        if v is None:
            return None
        try:
            return round(float(v), nd)
        except Exception:
            return None

    def _safe_div(self, a, b):
        if a is None or b is None:
            return None
        if abs(b) < 1e-12:
            return None
        return a / b

    def _mix_by_coverage(self, cov, locked, live):
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

    def _cbot_cents_to_usd_per_bu(self, cents_per_bu):
        if cents_per_bu is None:
            return None
        return float(cents_per_bu) / 100.0

    def _premium_to_usd_per_bu(self, hp):
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

    def _normalize_cbot_cents(self, v, quote_cents_hint):
        if v is None:
            return None
        if quote_cents_hint is None:
            if v < 50:
                return v * 100.0
            return v
        if quote_cents_hint > 100 and v < 50:
            return v * 100.0
        return v

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

    def _latest_cbot_by_symbol_ref_mes(self, db: Session, farm_id: int, pairs: set[tuple[str, date]]) -> _LatestByKey:
        pairs = {(s.strip(), rm) for (s, rm) in pairs if s and s.strip() and rm}
        if not pairs:
            return _LatestByKey(map={})

        symbols = sorted({s for (s, _) in pairs})
        ref_meses = sorted({rm for (_, rm) in pairs})

        ranked = (
            db.query(
                CbotQuote.id.label("id"),
                func.row_number()
                .over(
                    partition_by=(CbotQuote.symbol, CbotQuote.ref_mes),
                    order_by=(CbotQuote.capturado_em.desc(), CbotQuote.id.desc()),
                )
                .label("rn"),
            )
            .filter(
                CbotQuote.farm_id == farm_id,
                CbotQuote.symbol.in_(symbols),
                CbotQuote.ref_mes.in_(ref_meses),
            )
            .subquery()
        )

        rows = (
            db.query(CbotQuote)
            .join(ranked, CbotQuote.id == ranked.c.id)
            .filter(ranked.c.rn == 1)
            .all()
        )

        wanted = set(pairs)
        return _LatestByKey(map={(r.symbol, r.ref_mes): r for r in rows if (r.symbol, r.ref_mes) in wanted})

    def _latest_fx_curve_by_ref_mes(self, db: Session, farm_id: int, ref_meses: Iterable[date]) -> _LatestByKey:
        ref_meses = {rm for rm in ref_meses if rm}
        if not ref_meses:
            return _LatestByKey(map={})

        ranked = (
            db.query(
                FxModelPoint.id.label("point_id"),
                FxModelPoint.ref_mes.label("ref_mes"),
                func.row_number()
                .over(
                    partition_by=FxModelPoint.ref_mes,
                    order_by=(FxModelRun.as_of_ts.desc(), FxModelRun.id.desc(), FxModelPoint.id.desc()),
                )
                .label("rn"),
            )
            .join(FxModelRun, FxModelRun.id == FxModelPoint.run_id)
            .filter(FxModelRun.farm_id == farm_id, FxModelPoint.ref_mes.in_(list(ref_meses)))
            .subquery()
        )

        rows = (
            db.query(FxModelRun, FxModelPoint)
            .join(FxModelPoint, FxModelPoint.run_id == FxModelRun.id)
            .join(ranked, FxModelPoint.id == ranked.c.point_id)
            .filter(ranked.c.rn == 1)
            .all()
        )

        m: dict[date, _FxCurveSnap] = {}
        for run, point in rows:
            m[point.ref_mes] = _FxCurveSnap(run=run, point=point)

        return _LatestByKey(map=m)

    def _latest_fx_manual_by_ref_mes(self, db: Session, farm_id: int, ref_meses: Iterable[date]) -> _LatestByKey:
        ref_meses = {rm for rm in ref_meses if rm}
        if not ref_meses:
            return _LatestByKey(map={})

        ranked = (
            db.query(
                FxManualPoint.id.label("id"),
                func.row_number()
                .over(
                    partition_by=FxManualPoint.ref_mes,
                    order_by=(FxManualPoint.captured_at.desc(), FxManualPoint.id.desc()),
                )
                .label("rn"),
            )
            .filter(FxManualPoint.farm_id == farm_id, FxManualPoint.ref_mes.in_(list(ref_meses)))
            .subquery()
        )

        rows = (
            db.query(FxManualPoint)
            .join(ranked, FxManualPoint.id == ranked.c.id)
            .filter(ranked.c.rn == 1)
            .all()
        )
        return _LatestByKey(map={r.ref_mes: r for r in rows})
