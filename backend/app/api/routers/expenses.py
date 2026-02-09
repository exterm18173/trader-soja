# app/api/routers/expenses_usd.py
from datetime import date
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.deps import get_current_user, get_farm_membership_from_path
from app.db.session import get_db
from app.models.user import User
from app.schemas.expenses import ExpenseUsdCreate, ExpenseUsdRead, ExpenseUsdUpdate
from app.services.expenses_usd_service import ExpensesUsdService

router = APIRouter(prefix="/farms/{farm_id}/expenses-usd", tags=["Expenses USD"])
service = ExpensesUsdService()


@router.post("", response_model=ExpenseUsdRead, status_code=status.HTTP_201_CREATED)
def create_expense(
    farm_id: int,
    payload: ExpenseUsdCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
    membership=Depends(get_farm_membership_from_path),
):
    return service.create(db, farm_id, user.id, payload)


@router.get("", response_model=list[ExpenseUsdRead])
def list_expenses(
    farm_id: int,
    from_mes: date | None = Query(default=None),
    to_mes: date | None = Query(default=None),
    categoria: str | None = Query(default=None),
    limit: int = Query(default=1000, ge=1, le=5000),
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.list(db, farm_id, from_mes=from_mes, to_mes=to_mes, categoria=categoria, limit=limit)


@router.get("/{expense_id}", response_model=ExpenseUsdRead)
def get_expense(
    farm_id: int,
    expense_id: int,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.get(db, farm_id, expense_id)


@router.patch("/{expense_id}", response_model=ExpenseUsdRead)
def update_expense(
    farm_id: int,
    expense_id: int,
    payload: ExpenseUsdUpdate,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.update(db, farm_id, expense_id, payload)


@router.delete("/{expense_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_expense(
    farm_id: int,
    expense_id: int,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    service.delete(db, farm_id, expense_id)
    return None
