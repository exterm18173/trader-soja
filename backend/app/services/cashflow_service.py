from sqlalchemy.orm import Session
from sqlalchemy import func

from app.models.expense_usd import ExpenseUsd


class CashflowService:
    def debt_usd_by_month(self, db: Session, farm_id: int) -> list[dict]:
        rows = (
            db.query(
                ExpenseUsd.mes_competencia.label("mes"),
                func.coalesce(func.sum(ExpenseUsd.valor_usd), 0).label("divida_usd"),
            )
            .filter(ExpenseUsd.farm_id == farm_id)
            .group_by(ExpenseUsd.mes_competencia)
            .order_by(ExpenseUsd.mes_competencia.asc())
            .all()
        )
        return [{"mes": r.mes, "divida_usd": float(r.divida_usd)} for r in rows]
