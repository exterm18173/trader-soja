from datetime import datetime, date

from app.schemas.base import SchemaBase


class FxModelPointRead(SchemaBase):
    ref_mes: date
    t_anos: float
    dolar_sint: float
    dolar_desc: float


class FxModelRunRead(SchemaBase):
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
