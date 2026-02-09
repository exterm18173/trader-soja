# app/schemas/dashboard_usd.py
from datetime import date
from pydantic import BaseModel


class UsdExposureRow(BaseModel):
    competencia_mes: date
    despesas_usd: float
    receita_travada_usd: float
    saldo_usd: float
    cobertura_pct: float  # receita_travada / despesas (0 se despesas=0)


class UsdExposureResponse(BaseModel):
    farm_id: int
    rows: list[UsdExposureRow]
