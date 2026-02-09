# app/services/dashboard_service.py
from __future__ import annotations

from collections import defaultdict
from datetime import date
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.expense_usd import ExpenseUsd
from app.models.hedge_fx import HedgeFx
from app.models.contract import Contract


def _month_start(d: date) -> date:
    return date(d.year, d.month, 1)


class DashboardService:
    def usd_exposure(
        self,
        db: Session,
        farm_id: int,
        from_mes: date | None = None,
        to_mes: date | None = None,
    ):
        # --- despesas USD (por competencia_mes) ---
        q_exp = db.query(ExpenseUsd).filter(ExpenseUsd.farm_id == farm_id)
        if from_mes:
            q_exp = q_exp.filter(ExpenseUsd.competencia_mes >= _month_start(from_mes))
        if to_mes:
            q_exp = q_exp.filter(ExpenseUsd.competencia_mes <= _month_start(to_mes))
        expenses = q_exp.all()

        exp_by_month: dict[date, float] = defaultdict(float)
        for e in expenses:
            exp_by_month[_month_start(e.competencia_mes)] += float(e.valor_usd)

        # --- receita travada (MVP): HedgeFx.usd_amount por ref_mes (ou mês de executado_em) ---
        # garante que o hedge pertence à farm via join Contract
        q_fx = (
            db.query(HedgeFx, Contract)
            .join(Contract, Contract.id == HedgeFx.contract_id)
            .filter(Contract.farm_id == farm_id)
        )
        hedges = q_fx.all()

        rev_by_month: dict[date, float] = defaultdict(float)
        for h, c in hedges:
            if getattr(h, "ref_mes", None):
                m = _month_start(h.ref_mes)
            else:
                m = date(h.executado_em.year, h.executado_em.month, 1)
            if from_mes and m < _month_start(from_mes):
                continue
            if to_mes and m > _month_start(to_mes):
                continue
            rev_by_month[m] += float(h.usd_amount)

        # --- merge months ---
        months = sorted(set(exp_by_month.keys()) | set(rev_by_month.keys()))
        rows = []
        for m in months:
            despesas = float(exp_by_month.get(m, 0.0))
            receita = float(rev_by_month.get(m, 0.0))
            saldo = receita - despesas
            cobertura = (receita / despesas) if despesas > 0 else 0.0
            rows.append(
                {
                    "competencia_mes": m,
                    "despesas_usd": despesas,
                    "receita_travada_usd": receita,
                    "saldo_usd": saldo,
                    "cobertura_pct": cobertura,
                }
            )

        return {"farm_id": farm_id, "rows": rows}
