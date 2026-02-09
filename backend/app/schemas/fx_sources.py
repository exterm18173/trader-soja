# app/schemas/fx_sources.py
from pydantic import BaseModel, Field


class FxSourceCreate(BaseModel):
    nome: str = Field(min_length=2, max_length=80)
    ativo: bool = True


class FxSourceRead(BaseModel):
    id: int
    nome: str
    ativo: bool

    class Config:
        from_attributes = True
