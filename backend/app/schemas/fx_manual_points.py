# app/schemas/fx_manual_points.py
from datetime import datetime, date
from pydantic import BaseModel, Field


class FxManualPointCreate(BaseModel):
    source_id: int
    captured_at: datetime
    ref_mes: date  # YYYY-MM-01
    fx: float = Field(gt=0)


class FxManualPointUpdate(BaseModel):
    captured_at: datetime | None = None
    ref_mes: date | None = None
    fx: float | None = Field(default=None, gt=0)


class FxManualPointRead(BaseModel):
    id: int
    farm_id: int
    source_id: int
    created_by_user_id: int
    captured_at: datetime
    ref_mes: date
    fx: float

    class Config:
        from_attributes = True
