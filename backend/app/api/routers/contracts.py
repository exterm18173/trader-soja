from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.deps import get_current_farm_membership, get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.contracts import ContractCreate, ContractRead
from app.services.contracts_service import ContractsService

router = APIRouter(prefix="/contracts", tags=["Contracts"])
service = ContractsService()


@router.post("", response_model=ContractRead, status_code=status.HTTP_201_CREATED)
def create_contract(
    payload: ContractCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
    membership=Depends(get_current_farm_membership),
):
    return service.create(db, membership.farm_id, user.id, payload)


@router.get("", response_model=list[ContractRead])
def list_contracts(
    db: Session = Depends(get_db),
    membership=Depends(get_current_farm_membership),
):
    return service.list(db, membership.farm_id)


@router.get("/{contract_id}", response_model=ContractRead)
def get_contract(
    contract_id: int,
    db: Session = Depends(get_db),
    membership=Depends(get_current_farm_membership),
):
    return service.get(db, membership.farm_id, contract_id)
