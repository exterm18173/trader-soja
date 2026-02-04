from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.deps import get_current_farm_membership, get_current_user
from app.db.session import get_db
from app.models.expense_usd import ExpenseUsd
from app.models.user import User
from app.schemas.expenses import ExpenseUsdCreate, ExpenseUsdRead

router = APIRouter(prefix="/expenses-usd", tags=["Expenses USD"])


@router.post("", response_model=ExpenseUsdRead, status_code=status.HTTP_201_CREATED)
def create_expense(
    payload: ExpenseUsdCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
    membership=Depends(get_current_farm_membership),
):
    e = ExpenseUsd(
        farm_id=membership.farm_id,
        created_by_user_id=user.id,
        mes_competencia=payload.mes_competencia,
        valor_usd=payload.valor_usd,
        categoria=payload.categoria,
        descricao=payload.descricao,
    )
    db.add(e)
    db.commit()
    db.refresh(e)
    return e


@router.get("", response_model=list[ExpenseUsdRead])
def list_expenses(
    db: Session = Depends(get_db),
    membership=Depends(get_current_farm_membership),
):
    return (
        db.query(ExpenseUsd)
        .filter(ExpenseUsd.farm_id == membership.farm_id)
        .order_by(ExpenseUsd.mes_competencia.asc(), ExpenseUsd.id.desc())
        .all()
    )
