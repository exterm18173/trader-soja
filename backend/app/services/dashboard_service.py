from sqlalchemy.orm import Session
from sqlalchemy import func

from app.models.contract import Contract
from app.models.expense_usd import ExpenseUsd


class DashboardService:
    def build(self, db: Session, farm_id: int) -> dict:
        # Dívida USD por mês (da tabela expenses_usd)
        debt_rows = (
            db.query(
                ExpenseUsd.mes_competencia.label("mes"),
                func.coalesce(func.sum(ExpenseUsd.valor_usd), 0).label("divida_usd"),
            )
            .filter(ExpenseUsd.farm_id == farm_id)
            .group_by(ExpenseUsd.mes_competencia)
            .order_by(ExpenseUsd.mes_competencia.asc())
            .all()
        )
        debt = [{"mes": r.mes, "divida_usd": float(r.divida_usd)} for r in debt_rows]

        # Contratos por mês de entrega
        # (conta quantidade e soma volume_total_ton)
        contracts_rows = (
            db.query(
                func.to_char(Contract.data_entrega, "YYYY-MM").label("mes_entrega"),
                func.count(Contract.id).label("contratos"),
                func.coalesce(func.sum(Contract.volume_total_ton), 0).label("volume_ton"),
            )
            .filter(Contract.farm_id == farm_id)
            .group_by(func.to_char(Contract.data_entrega, "YYYY-MM"))
            .order_by(func.to_char(Contract.data_entrega, "YYYY-MM").asc())
            .all()
        )
        contracts = [
            {"mes_entrega": r.mes_entrega, "contratos": int(r.contratos), "volume_ton": float(r.volume_ton)}
            for r in contracts_rows
        ]

        return {"farm_id": farm_id, "debt_usd": debt, "contracts": contracts}
