from datetime import date
from pydantic import BaseModel


class InterestRateCreate(BaseModel):
    rate_date: date
    cdi_annual: float
    sofr_annual: float


class InterestRateRead(BaseModel):
    id: int
    farm_id: int
    rate_date: date
    cdi_annual: float
    sofr_annual: float
    created_by_user_id: int

    class Config:
        from_attributes = True
