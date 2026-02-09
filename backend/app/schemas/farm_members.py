# app/schemas/farm_members.py
from pydantic import BaseModel, Field
from app.schemas.users import UserPublic 


class FarmMemberCreate(BaseModel):
    user_id: int
    role: str = Field(default="VIEWER", max_length=40)
    ativo: bool = True


class FarmMemberUpdate(BaseModel):
    role: str | None = Field(default=None, max_length=40)
    ativo: bool | None = None


class FarmMemberRead(BaseModel):
    id: int  # membership_id
    farm_id: int
    user: UserPublic
    role: str
    ativo: bool

    class Config:
        from_attributes = True
