# app/schemas/fx_spot.py
from datetime import datetime
from pydantic import BaseModel, Field


class FxSpotTickCreate(BaseModel):
    ts: datetime
    price: float = Field(gt=0)
    source: str = Field(default="B3", min_length=2, max_length=40)


class FxSpotTickRead(BaseModel):
    id: int
    farm_id: int
    ts: datetime
    price: float
    source: str

    class Config:
        from_attributes = True
