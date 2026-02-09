# app/api/routers/cbot_sources.py
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.schemas.cbot_sources import CbotSourceCreate, CbotSourceRead
from app.services.cbot_sources_service import CbotSourcesService

router = APIRouter(prefix="/cbot/sources", tags=["CBOT Sources"])
service = CbotSourcesService()


@router.post("", response_model=CbotSourceRead, status_code=status.HTTP_201_CREATED)
def create_source(
    payload: CbotSourceCreate,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    return service.create(db, payload.nome, payload.ativo)


@router.get("", response_model=list[CbotSourceRead])
def list_sources(
    only_active: bool = Query(default=True),
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    return service.list(db, only_active=only_active)
