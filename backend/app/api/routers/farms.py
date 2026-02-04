from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.farms import FarmCreate, FarmMembershipRead, FarmRead
from app.services.farms_service import FarmsService

router = APIRouter(prefix="/farms", tags=["Farms"])
service = FarmsService()


@router.post("", response_model=FarmRead, status_code=status.HTTP_201_CREATED)
def criar_farm(
    payload: FarmCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return service.create_farm(db, user, payload.nome)


@router.get("/me", response_model=list[FarmMembershipRead])
def minhas_fazendas(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    links = service.list_my_farms(db, user)
    return [{"farm": l.farm, "role": l.role} for l in links]
