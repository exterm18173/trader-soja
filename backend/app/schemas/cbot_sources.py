# app/schemas/cbot_sources.py
from pydantic import BaseModel, Field


class CbotSourceCreate(BaseModel):
    nome: str = Field(min_length=2, max_length=80)
    ativo: bool = True


class CbotSourceRead(BaseModel):
    id: int
    nome: str
    ativo: bool

    class Config:
        from_attributes = True
