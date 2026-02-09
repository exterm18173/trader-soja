# app/api/routers/fx_manual_points.py
from datetime import date
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.deps import get_current_user, get_farm_membership_from_path
from app.db.session import get_db
from app.models.user import User
from app.schemas.fx_manual_points import FxManualPointCreate, FxManualPointRead, FxManualPointUpdate
from app.services.fx_manual_points_service import FxManualPointsService

router = APIRouter(prefix="/farms/{farm_id}/fx/manual-points", tags=["FX Manual Points"])
service = FxManualPointsService()


@router.post("", response_model=FxManualPointRead, status_code=status.HTTP_201_CREATED)
def create_point(
    farm_id: int,
    payload: FxManualPointCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
    membership=Depends(get_farm_membership_from_path),
):
    return service.create(db, farm_id, user.id, payload)


@router.get("", response_model=list[FxManualPointRead])
def list_points(
    farm_id: int,
    source_id: int | None = Query(default=None),
    ref_mes: date | None = Query(default=None),
    limit: int = Query(default=2000, ge=1, le=20000),
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.list(db, farm_id, source_id=source_id, ref_mes=ref_mes, limit=limit)


@router.get("/{point_id}", response_model=FxManualPointRead)
def get_point(
    farm_id: int,
    point_id: int,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.get(db, farm_id, point_id)


@router.patch("/{point_id}", response_model=FxManualPointRead)
def update_point(
    farm_id: int,
    point_id: int,
    payload: FxManualPointUpdate,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.update(db, farm_id, point_id, payload)


@router.delete("/{point_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_point(
    farm_id: int,
    point_id: int,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    service.delete(db, farm_id, point_id)
    return None
