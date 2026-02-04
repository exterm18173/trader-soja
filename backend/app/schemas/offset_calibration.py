from pydantic import BaseModel


class OffsetCreate(BaseModel):
    offset_value: float


class OffsetRead(BaseModel):
    id: int
    farm_id: int
    offset_value: float
    created_by_user_id: int

    class Config:
        from_attributes = True
