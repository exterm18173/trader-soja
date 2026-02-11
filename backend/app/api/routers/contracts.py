# app/api/routers/contracts.py
from datetime import date
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.deps import get_current_user, get_farm_membership_from_path
from app.db.session import get_db
from app.models.user import User
from app.schemas.contracts import ContractCreate, ContractRead, ContractUpdate
from app.services.contracts_service import ContractsService

router = APIRouter(prefix="/farms/{farm_id}/contracts", tags=["Contracts"])
service = ContractsService()


@router.post("", response_model=ContractRead, status_code=status.HTTP_201_CREATED)
def create_contract(
    farm_id: int,
    payload: ContractCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
    membership=Depends(get_farm_membership_from_path),
):
    return service.create(db, farm_id, user.id, payload)


@router.get("", response_model=list[ContractRead])
def list_contracts(
    farm_id: int,
    status_: str | None = Query(default=None, alias="status"),
    produto: str | None = Query(default=None),
    tipo_precificacao: str | None = Query(default=None),
    entrega_from: date | None = Query(default=None),
    entrega_to: date | None = Query(default=None),
    q: str | None = Query(default=None),
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.list(
        db,
        farm_id,
        status=status_,
        produto=produto,
        tipo_precificacao=tipo_precificacao,
        entrega_from=entrega_from,
        entrega_to=entrega_to,
        q=q,
    )


@router.get("/{contract_id}", response_model=ContractRead)
def get_contract(
    farm_id: int,
    contract_id: int,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.get(db, farm_id, contract_id)


@router.patch("/{contract_id}", response_model=ContractRead)
def update_contract(
    farm_id: int,
    contract_id: int,
    payload: ContractUpdate,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.update(db, farm_id, contract_id, payload)


@router.delete("/{contract_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_contract(
    farm_id: int,
    contract_id: int,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    service.delete(db, farm_id, contract_id)
    return None
