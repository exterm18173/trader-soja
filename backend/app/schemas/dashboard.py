from pydantic import BaseModel


class DashboardDebtRow(BaseModel):
    mes: str           # YYYY-MM
    divida_usd: float


class DashboardContractsRow(BaseModel):
    mes_entrega: str    # YYYY-MM
    contratos: int
    volume_ton: float


class DashboardRead(BaseModel):
    farm_id: int
    debt_usd: list[DashboardDebtRow]
    contracts: list[DashboardContractsRow]
