from datetime import datetime, date

from app.schemas.base import SchemaBase


class FxQuoteCreate(SchemaBase):
    source_name: str = "AMAGGI"
    capturado_em: datetime
    ref_mes: date  # usar YYYY-MM-01
    brl_per_usd: float
    observacao: str | None = None


class FxQuoteCheckRead(SchemaBase):
    model_run_id: int | None
    script_brl_per_usd: float
    diff_abs: float
    diff_pct: float
    calculo_em: datetime


class FxQuoteRead(SchemaBase):
    id: int
    farm_id: int
    source_id: int
    created_by_user_id: int
    capturado_em: datetime
    ref_mes: date
    brl_per_usd: float
    observacao: str | None


class FxQuoteWithCheckRead(SchemaBase):
    quote: FxQuoteRead
    check: FxQuoteCheckRead
