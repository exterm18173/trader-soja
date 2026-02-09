# app/schemas/fx_quotes.py
from datetime import datetime, date
from pydantic import BaseModel, Field


class FxQuoteCreate(BaseModel):
    source_id: int
    capturado_em: datetime
    ref_mes: date  # ideal YYYY-MM-01
    brl_per_usd: float = Field(gt=0)
    observacao: str | None = None


class FxQuoteRead(BaseModel):
    id: int
    farm_id: int
    source_id: int
    created_by_user_id: int | None
    capturado_em: datetime
    ref_mes: date
    brl_per_usd: float
    observacao: str | None

    class Config:
        from_attributes = True


class FxQuoteCheckRead(BaseModel):
    id: int
    quote_id: int
    farm_id: int
    manual_point_id: int | None
    model_run_id: int
    model_point_id: int
    ref_mes: date
    fx_manual: float
    fx_model: float
    delta_abs: float
    delta_pct: float

    class Config:
        from_attributes = True


class FxQuoteWithCheckRead(BaseModel):
    quote: FxQuoteRead
    check: FxQuoteCheckRead
