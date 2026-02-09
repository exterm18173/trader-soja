# app/schemas/expenses.py
from datetime import date
from pydantic import BaseModel, Field


class ExpenseUsdCreate(BaseModel):
    competencia_mes: date  # use YYYY-MM-01
    valor_usd: float = Field(gt=0)
    categoria: str | None = Field(default=None, max_length=80)
    descricao: str | None = Field(default=None, max_length=255)


class ExpenseUsdUpdate(BaseModel):
    competencia_mes: date | None = None
    valor_usd: float | None = Field(default=None, gt=0)
    categoria: str | None = Field(default=None, max_length=80)
    descricao: str | None = Field(default=None, max_length=255)


class ExpenseUsdRead(BaseModel):
    id: int
    farm_id: int
    created_by_user_id: int
    competencia_mes: date
    valor_usd: float
    categoria: str | None
    descricao: str | None

    class Config:
        from_attributes = True
