# app/schemas/contracts_mtm.py
from __future__ import annotations

from datetime import date, datetime
from pydantic import BaseModel


class ContractBrief(BaseModel):
    id: int
    produto: str
    tipo_precificacao: str
    data_entrega: date
    status: str
    volume_total_ton: float

    preco_fixo_brl_value: float | None = None
    preco_fixo_brl_unit: str | None = None

    frete_brl_total: float | None = None
    frete_brl_per_ton: float | None = None
    frete_obs: str | None = None

    observacao: str | None = None

    class Config:
        from_attributes = True


class LockCbot(BaseModel):
    locked: bool
    coverage_pct: float
    locked_cents_per_bu: float | None = None
    symbol: str | None = None
    ref_mes: date | None = None


class LockPremium(BaseModel):
    locked: bool
    coverage_pct: float
    premium_value: float | None = None
    premium_unit: str | None = None  # USD_BU | USD_TON


class LockFx(BaseModel):
    locked: bool
    coverage_pct: float
    brl_per_usd: float | None = None
    tipo: str | None = None
    usd_amount: float | None = None


class LocksInfo(BaseModel):
    cbot: LockCbot
    premium: LockPremium
    fx: LockFx


class CbotQuoteBrief(BaseModel):
    symbol: str
    capturado_em: datetime
    cents_per_bu: float
    unit: str = "cents/bu"


class FxQuoteBrief(BaseModel):
    capturado_em: datetime
    ref_mes: date
    brl_per_usd: float
    source: str


class FxManualBrief(BaseModel):
    captured_at: datetime
    ref_mes: date
    brl_per_usd: float
    source: str = "manual"


class QuotesInfo(BaseModel):
    cbot_system: CbotQuoteBrief | None = None
    fx_system: FxQuoteBrief | None = None
    fx_manual: FxManualBrief | None = None


class UsedComponent(BaseModel):
    system: float | None = None
    manual: float | None = None


class ValuationSide(BaseModel):
    system: float | None = None
    manual: float | None = None


class Valuation(BaseModel):
    usd_per_saca: ValuationSide
    brl_per_saca: ValuationSide
    components: dict[str, UsedComponent]


# ✅ Totais (numéricos)
class TotalsSide(BaseModel):
    system: float | None = None
    manual: float | None = None


# ✅ Totais (strings, ex mode)
class TotalsModeSide(BaseModel):
    system: str
    manual: str


class ContractTotals(BaseModel):
    ton_total: float
    sacas_total: float

    usd_total_contract: float | None = None
    brl_total_contract: TotalsSide

    fx_locked_usd_used: TotalsSide
    fx_unlocked_usd_used: TotalsSide
    fx_lock_mode: TotalsModeSide

    fx_locked_usd_pct: TotalsSide
    fx_unlocked_usd_pct: TotalsSide


class ContractMtmRow(BaseModel):
    contract: ContractBrief
    locks: LocksInfo
    quotes: QuotesInfo
    valuation: Valuation
    totals: ContractTotals


class ContractsMtmResponse(BaseModel):
    farm_id: int
    as_of_ts: datetime
    mode: str
    fx_ref_mes: date | None = None
    rows: list[ContractMtmRow]
