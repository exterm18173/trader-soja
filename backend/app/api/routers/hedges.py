# app/api/routers/hedges.py
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.deps import get_current_user, get_farm_membership_from_path
from app.db.session import get_db
from app.models.user import User
from app.schemas.hedges import (
    HedgeCbotCreate, HedgeCbotRead,
    HedgePremiumCreate, HedgePremiumRead,
    HedgeFxCreate, HedgeFxRead,
)
from app.services.hedges_service import HedgesService

router = APIRouter(prefix="/farms/{farm_id}/contracts/{contract_id}/hedges", tags=["Hedges"])
service = HedgesService()


@router.post("/cbot", response_model=HedgeCbotRead, status_code=status.HTTP_201_CREATED)
def create_cbot(
    farm_id: int,
    contract_id: int,
    payload: HedgeCbotCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
    membership=Depends(get_farm_membership_from_path),
):
    return service.create_cbot(db, farm_id, contract_id, user.id, payload)


@router.get("/cbot", response_model=list[HedgeCbotRead])
def list_cbot(
    farm_id: int,
    contract_id: int,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.list_cbot(db, farm_id, contract_id)


@router.post("/premium", response_model=HedgePremiumRead, status_code=status.HTTP_201_CREATED)
def create_premium(
    farm_id: int,
    contract_id: int,
    payload: HedgePremiumCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
    membership=Depends(get_farm_membership_from_path),
):
    return service.create_premium(db, farm_id, contract_id, user.id, payload)


@router.get("/premium", response_model=list[HedgePremiumRead])
def list_premium(
    farm_id: int,
    contract_id: int,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.list_premium(db, farm_id, contract_id)


@router.post("/fx", response_model=HedgeFxRead, status_code=status.HTTP_201_CREATED)
def create_fx(
    farm_id: int,
    contract_id: int,
    payload: HedgeFxCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
    membership=Depends(get_farm_membership_from_path),
):
    return service.create_fx(db, farm_id, contract_id, user.id, payload)


@router.get("/fx", response_model=list[HedgeFxRead])
def list_fx(
    farm_id: int,
    contract_id: int,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.list_fx(db, farm_id, contract_id)
