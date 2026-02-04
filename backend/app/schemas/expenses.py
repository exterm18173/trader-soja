from pydantic import BaseModel


class ExpenseUsdCreate(BaseModel):
    mes_competencia: str  # YYYY-MM
    valor_usd: float
    categoria: str | None = None
    descricao: str | None = None


class ExpenseUsdRead(BaseModel):
    id: int
    farm_id: int
    created_by_user_id: int
    mes_competencia: str
    valor_usd: float
    categoria: str | None
    descricao: str | None

    class Config:
        from_attributes = True
