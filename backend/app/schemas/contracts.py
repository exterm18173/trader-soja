from datetime import date
from pydantic import BaseModel


class ContractCreate(BaseModel):
    produto: str = "SOJA"
    tipo_precificacao: str  # CBOT_PREMIO|FIXO_BRL

    volume_input_value: float
    volume_input_unit: str  # TON|SACA
    volume_total_ton: float  # frontend pode mandar já calculado (depois automatizamos)

    data_entrega: date

    preco_fixo_brl_value: float | None = None
    preco_fixo_brl_unit: str | None = None

    observacao: str | None = None


class ContractRead(BaseModel):
    id: int
    farm_id: int
    created_by_user_id: int

    produto: str
    tipo_precificacao: str

    volume_input_value: float
    volume_input_unit: str
    volume_total_ton: float

    data_entrega: date
    status: str

    preco_fixo_brl_value: float | None
    preco_fixo_brl_unit: str | None

    observacao: str | None

    class Config:
        from_attributes = True
