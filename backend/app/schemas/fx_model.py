# app/schemas/fx_model.py
from datetime import datetime, date
from pydantic import BaseModel, Field


class FxModelPointRead(BaseModel):
    ref_mes: date
    t_anos: float
    dolar_sint: float
    dolar_desc: float

    class Config:
        from_attributes = True


class FxModelRunRead(BaseModel):
    id: int
    farm_id: int
    as_of_ts: datetime
    spot_usdbrl: float
    cdi_annual: float
    sofr_annual: float
    offset_value: float
    coupon_annual: float
    desconto_pct: float
    model_version: str
    source: str

    class Config:
        from_attributes = True


class FxModelRunWithPointsRead(FxModelRunRead):
    points: list[FxModelPointRead] = Field(default_factory=list)
