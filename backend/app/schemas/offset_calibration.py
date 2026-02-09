# app/schemas/offset_calibration.py
from pydantic import BaseModel, Field


class OffsetCreate(BaseModel):
    offset_value: float = Field(ge=-9999, le=9999)
    note: str | None = None


class OffsetRead(BaseModel):
    id: int
    farm_id: int
    created_by_user_id: int  
    offset_value: float
    note: str | None = None

    class Config:
        from_attributes = True
