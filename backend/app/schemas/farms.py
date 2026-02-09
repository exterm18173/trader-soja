# app/schemas/farms.py
from pydantic import BaseModel, Field


class FarmCreate(BaseModel):
    nome: str = Field(min_length=2, max_length=200)


class FarmUpdate(BaseModel):
    nome: str | None = Field(default=None, min_length=2, max_length=200)
    ativo: bool | None = None


class FarmRead(BaseModel):
    id: int
    nome: str
    ativo: bool

    class Config:
        from_attributes = True


class FarmMembershipRead(BaseModel):
    membership_id: int
    farm: FarmRead
    role: str
    ativo: bool
