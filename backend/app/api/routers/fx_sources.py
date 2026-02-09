# app/api/routers/fx_sources.py
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.schemas.fx_sources import FxSourceCreate, FxSourceRead
from app.services.fx_sources_service import FxSourcesService

router = APIRouter(prefix="/fx/sources", tags=["FX Sources"])
service = FxSourcesService()


@router.post("", response_model=FxSourceRead, status_code=status.HTTP_201_CREATED)
def create_source(
    payload: FxSourceCreate,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    return service.create(db, payload.nome, payload.ativo)


@router.get("", response_model=list[FxSourceRead])
def list_sources(
    only_active: bool = Query(default=True),
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    return service.list(db, only_active=only_active)
