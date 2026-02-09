# app/services/expenses_usd_service.py
from __future__ import annotations

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.expense_usd import ExpenseUsd


class ExpensesUsdService:
    def create(self, db: Session, farm_id: int, user_id: int, payload) -> ExpenseUsd:
        row = ExpenseUsd(
            farm_id=farm_id,
            created_by_user_id=user_id,
            competencia_mes=payload.competencia_mes,
            valor_usd=payload.valor_usd,
            categoria=(payload.categoria.strip().upper() if payload.categoria else None),
            descricao=payload.descricao,
        )
        db.add(row)
        db.commit()
        db.refresh(row)
        return row

    def list(
        self,
        db: Session,
        farm_id: int,
        from_mes=None,
        to_mes=None,
        categoria: str | None = None,
        limit: int = 1000,
    ) -> list[ExpenseUsd]:
        q = db.query(ExpenseUsd).filter(ExpenseUsd.farm_id == farm_id)

        if from_mes:
            q = q.filter(ExpenseUsd.competencia_mes >= from_mes)
        if to_mes:
            q = q.filter(ExpenseUsd.competencia_mes <= to_mes)
        if categoria:
            q = q.filter(ExpenseUsd.categoria == categoria.strip().upper())

        return q.order_by(ExpenseUsd.competencia_mes.asc(), ExpenseUsd.id.desc()).limit(limit).all()

    def get(self, db: Session, farm_id: int, expense_id: int) -> ExpenseUsd:
        row = db.query(ExpenseUsd).filter(ExpenseUsd.farm_id == farm_id, ExpenseUsd.id == expense_id).first()
        if not row:
            raise HTTPException(status_code=404, detail="Despesa USD não encontrada")
        return row

    def update(self, db: Session, farm_id: int, expense_id: int, payload) -> ExpenseUsd:
        row = self.get(db, farm_id, expense_id)

        if payload.competencia_mes is not None:
            row.competencia_mes = payload.competencia_mes
        if payload.valor_usd is not None:
            row.valor_usd = payload.valor_usd
        if payload.categoria is not None:
            row.categoria = payload.categoria.strip().upper() if payload.categoria else None
        if payload.descricao is not None:
            row.descricao = payload.descricao

        db.commit()
        db.refresh(row)
        return row

    def delete(self, db: Session, farm_id: int, expense_id: int) -> None:
        row = self.get(db, farm_id, expense_id)
        db.delete(row)
        db.commit()
