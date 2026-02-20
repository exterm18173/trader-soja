# app/schemas/contracts_mtm.py
from __future__ import annotations

from datetime import date, datetime
from typing import Literal

from pydantic import BaseModel

LockState = Literal["locked", "open"]
LockType = Literal["cbot", "premium", "fx"]


class ContractBrief(BaseModel):
    id: int
    produto: str
    tipo_precificacao: str  # mude pra str | None se no banco puder ser NULL
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
    # ✅ precisa aceitar None (service pode mandar None em alguns cenários)
    capturado_em: datetime | None = None
    ref_mes: date
    brl_per_usd: float
    source: str


class FxManualBrief(BaseModel):
    # ✅ precisa aceitar None (por segurança)
    captured_at: datetime | None = None
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


class TotalsSide(BaseModel):
    system: float | None = None
    manual: float | None = None


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


class RowFilterMeta(BaseModel):
    lock_types: list[LockType] = []
    lock_states: list[LockState] = []

    state_cbot: LockState
    state_premium: LockState
    state_fx: LockState

    pct_cbot: float
    pct_premium: float
    pct_fx: float

    locked_pct: float   # min(pcts)
    open_pct: float     # 1 - max(pcts)

    slice_pct: float


class ContractTotalsView(BaseModel):
    ton_total: float
    sacas_total: float

    usd_total_contract: float | None = None
    brl_total_contract: TotalsSide

    fx_locked_usd_used: TotalsSide
    fx_unlocked_usd_used: TotalsSide

    fx_locked_usd_pct: TotalsSide
    fx_unlocked_usd_pct: TotalsSide


class ContractMtmRow(BaseModel):
    contract: ContractBrief
    locks: LocksInfo
    quotes: QuotesInfo
    valuation: Valuation
    totals: ContractTotals

    totals_view: ContractTotalsView | None = None
    filter_meta: RowFilterMeta | None = None


class ContractsMtmResponse(BaseModel):
    farm_id: int
    as_of_ts: datetime
    mode: str
    fx_ref_mes: date | None = None

    # ✅ opcional, mas ajuda o front a refletir o estado do filtro
    no_locks: bool = False

    rows: list[ContractMtmRow]
