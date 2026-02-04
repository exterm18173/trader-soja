from datetime import datetime, date
from pydantic import BaseModel


class HedgeCbotCreate(BaseModel):
    executado_em: datetime
    volume_input_value: float
    volume_input_unit: str  # TON|SACA
    volume_ton: float
    cbot_usd_per_bu: float
    ref_mes: date | None = None
    symbol: str | None = None
    observacao: str | None = None


class HedgePremiumCreate(BaseModel):
    executado_em: datetime
    volume_input_value: float
    volume_input_unit: str
    volume_ton: float
    premium_value: float
    premium_unit: str  # USD_BU|USD_TON
    base_local: str | None = None
    observacao: str | None = None


class HedgeFxCreate(BaseModel):
    executado_em: datetime
    usd_amount: float
    brl_per_usd: float
    ref_mes: date | None = None
    tipo: str = "CURVA_SCRIPT"
    observacao: str | None = None


class HedgeCbotRead(BaseModel):
    id: int
    contract_id: int
    executed_by_user_id: int
    executado_em: datetime
    volume_input_value: float
    volume_input_unit: str
    volume_ton: float
    cbot_usd_per_bu: float
    ref_mes: date | None
    symbol: str | None
    observacao: str | None

    class Config:
        from_attributes = True


class HedgePremiumRead(BaseModel):
    id: int
    contract_id: int
    executed_by_user_id: int
    executado_em: datetime
    volume_input_value: float
    volume_input_unit: str
    volume_ton: float
    premium_value: float
    premium_unit: str
    base_local: str | None
    observacao: str | None

    class Config:
        from_attributes = True


class HedgeFxRead(BaseModel):
    id: int
    contract_id: int
    executed_by_user_id: int
    executado_em: datetime
    usd_amount: float
    brl_per_usd: float
    ref_mes: date | None
    tipo: str
    observacao: str | None

    class Config:
        from_attributes = True
