from datetime import date
from pydantic import BaseModel, Field, model_validator

class ContractCreate(BaseModel):
    produto: str = Field(default="SOJA", min_length=2, max_length=40)
    tipo_precificacao: str  # CBOT_PREMIO|FIXO_BRL

    volume_input_value: float = Field(gt=0)
    volume_input_unit: str = Field(min_length=1, max_length=10)  # TON|SACA
    volume_total_ton: float = Field(gt=0)  # MVP aceita do front (service tem fallback)

    data_entrega: date

    preco_fixo_brl_value: float | None = None
    preco_fixo_brl_unit: str | None = None

    # ✅ NOVO: frete
    frete_brl_total: float | None = Field(default=None, ge=0)
    frete_brl_per_ton: float | None = Field(default=None, ge=0)
    frete_obs: str | None = None

    observacao: str | None = None

    @model_validator(mode="after")
    def _validate_frete(self):
        if self.frete_brl_total is not None and self.frete_brl_per_ton is not None:
            raise ValueError("Informe apenas um: frete_brl_total OU frete_brl_per_ton")
        return self


class ContractUpdate(BaseModel):
    status: str | None = None
    data_entrega: date | None = None
    volume_input_value: float | None = Field(default=None, gt=0)
    volume_input_unit: str | None = None
    volume_total_ton: float | None = Field(default=None, gt=0)

    preco_fixo_brl_value: float | None = None
    preco_fixo_brl_unit: str | None = None

    # ✅ NOVO: frete
    frete_brl_total: float | None = Field(default=None, ge=0)
    frete_brl_per_ton: float | None = Field(default=None, ge=0)
    frete_obs: str | None = None

    observacao: str | None = None

    @model_validator(mode="after")
    def _validate_frete(self):
        if self.frete_brl_total is not None and self.frete_brl_per_ton is not None:
            raise ValueError("Informe apenas um: frete_brl_total OU frete_brl_per_ton")
        return self


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

    # ✅ NOVO: frete
    frete_brl_total: float | None
    frete_brl_per_ton: float | None
    frete_obs: str | None

    observacao: str | None

    class Config:
        from_attributes = True
