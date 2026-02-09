# app/api/routers/farms.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.deps import get_current_user, get_farm_membership_from_path
from app.db.session import get_db
from app.models.user import User
from app.schemas.farms import FarmCreate, FarmMembershipRead, FarmRead, FarmUpdate
from app.services.farms_service import FarmsService, ROLE_OWNER, ROLE_ADMIN

router = APIRouter(prefix="/farms", tags=["Farms"])
service = FarmsService()


@router.post("", response_model=FarmRead, status_code=status.HTTP_201_CREATED)
def criar_farm(
    payload: FarmCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return service.create_farm(db, user, payload.nome)


@router.get("", response_model=list[FarmMembershipRead])
def minhas_fazendas(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    links = service.list_my_memberships(db, user)

    # Requer: FarmUser.farm relationship preenchido (via join/relationship)
    return [
        {
            "membership_id": l.id,
            "farm": l.farm, 
            "role": l.role,
            "ativo": l.ativo,
        }
        for l in links
    ]


@router.get("/{farm_id}", response_model=FarmRead)
def obter_farm(
    farm_id: int,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    # membership garante acesso; aqui só buscamos
    return service.get_farm(db, farm_id)


@router.patch("/{farm_id}", response_model=FarmRead)
def atualizar_farm(
    farm_id: int,
    payload: FarmUpdate,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    if membership.role not in {ROLE_OWNER, ROLE_ADMIN}:
        raise HTTPException(status_code=403, detail="Ação permitida apenas para OWNER/ADMIN")

    return service.update_farm(db, farm_id, payload)
