# app/api/routers/farm_members.py
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.deps import get_farm_membership_from_path
from app.db.session import get_db
from app.schemas.farm_members import FarmMemberCreate, FarmMemberUpdate, FarmMemberRead
from app.services.farms_service import FarmsService, ROLE_OWNER, ROLE_ADMIN

router = APIRouter(prefix="/farms/{farm_id}/members", tags=["Farm Members"])
service = FarmsService()


@router.get("", response_model=list[FarmMemberRead])
def listar_membros(
    farm_id: int,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    # qualquer membro pode listar
    members = service.list_members(db, farm_id)
    # garantir que vem user carregado (FarmUser -> relationship user)
    return members


@router.post("", response_model=FarmMemberRead, status_code=status.HTTP_201_CREATED)
def adicionar_membro(
    farm_id: int,
    payload: FarmMemberCreate,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    if membership.role not in {ROLE_OWNER, ROLE_ADMIN}:
        from fastapi import HTTPException
        raise HTTPException(status_code=403, detail="Ação permitida apenas para OWNER/ADMIN")
    return service.add_member(db, farm_id, payload)


@router.patch("/{membership_id}", response_model=FarmMemberRead)
def atualizar_membro(
    farm_id: int,
    membership_id: int,
    payload: FarmMemberUpdate,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    if membership.role not in {ROLE_OWNER, ROLE_ADMIN}:
        from fastapi import HTTPException
        raise HTTPException(status_code=403, detail="Ação permitida apenas para OWNER/ADMIN")
    return service.update_member(db, farm_id, membership_id, payload)
