# app/api/routers/rates.py
from datetime import date
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.deps import get_current_user, get_farm_membership_from_path
from app.db.session import get_db
from app.models.user import User
from app.schemas.interest_rates import (
    InterestRateCreate,
    InterestRateRead,
    InterestRateUpdate,
    InterestRateUpsert,
)
from app.schemas.offset_calibration import OffsetCreate, OffsetRead
from app.services.rates_service import RatesService

router = APIRouter(prefix="/farms/{farm_id}/rates", tags=["Rates"])
service = RatesService()


# -------- Interest --------
@router.post("/interest", response_model=InterestRateRead, status_code=status.HTTP_201_CREATED)
def create_interest(
    farm_id: int,
    payload: InterestRateCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
    membership=Depends(get_farm_membership_from_path),
):
    return service.create_interest_rate(
        db, farm_id, user.id, payload.rate_date, payload.cdi_annual, payload.sofr_annual
    )


@router.get("/interest", response_model=list[InterestRateRead])
def list_interest(
    farm_id: int,
    from_date: date | None = Query(default=None, alias="from"),
    to_date: date | None = Query(default=None, alias="to"),
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.list_interest_rates(db, farm_id, from_date=from_date, to_date=to_date)


@router.get("/interest/latest", response_model=InterestRateRead | None)
def latest_interest(
    farm_id: int,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.latest_interest_rate(db, farm_id)


@router.patch("/interest/{row_id}", response_model=InterestRateRead)
def update_interest(
    farm_id: int,
    row_id: int,
    payload: InterestRateUpdate,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.update_interest_rate(db, farm_id, row_id, payload)


@router.put("/interest/{rate_date}", response_model=InterestRateRead)
def upsert_interest(
    farm_id: int,
    rate_date: date,
    payload: InterestRateUpsert,  # ✅ agora NÃO exige rate_date no body
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
    membership=Depends(get_farm_membership_from_path),
):
    return service.upsert_interest_rate(
        db, farm_id, user.id, rate_date, payload.cdi_annual, payload.sofr_annual
    )


# -------- Offset --------
@router.post("/offset", response_model=OffsetRead, status_code=status.HTTP_201_CREATED)
def create_offset(
    farm_id: int,
    payload: OffsetCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
    membership=Depends(get_farm_membership_from_path),
):
    return service.create_offset(db, farm_id, user.id, payload.offset_value, note=payload.note)


@router.get("/offset/latest", response_model=OffsetRead | None)
def latest_offset(
    farm_id: int,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.latest_offset(db, farm_id)


@router.get("/offset/history", response_model=list[OffsetRead])
def offset_history(
    farm_id: int,
    limit: int = Query(default=200, ge=1, le=1000),
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.list_offsets(db, farm_id, limit=limit)
