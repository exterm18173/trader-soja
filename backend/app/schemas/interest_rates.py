# app/schemas/interest_rates.py
from datetime import date
from pydantic import BaseModel, Field


class InterestRateCreate(BaseModel):
    rate_date: date
    cdi_annual: float = Field(ge=0)
    sofr_annual: float = Field(ge=0)


class InterestRateUpsert(BaseModel):
    # ✅ usado no PUT /interest/{rate_date}
    cdi_annual: float = Field(ge=0)
    sofr_annual: float = Field(ge=0)


class InterestRateUpdate(BaseModel):
    cdi_annual: float | None = Field(default=None, ge=0)
    sofr_annual: float | None = Field(default=None, ge=0)


class InterestRateRead(BaseModel):
    id: int
    farm_id: int
    created_by_user_id: int  # ✅ obrigatório (bate com NOT NULL do banco)
    rate_date: date
    cdi_annual: float
    sofr_annual: float

    class Config:
        from_attributes = True
