from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.deps import get_current_farm_membership, get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.interest_rates import InterestRateCreate, InterestRateRead
from app.schemas.offset_calibration import OffsetCreate, OffsetRead
from app.services.rates_service import RatesService

router = APIRouter(prefix="/rates", tags=["Rates"])
service = RatesService()


@router.post("/interest", response_model=InterestRateRead, status_code=status.HTTP_201_CREATED)
def create_interest(
    payload: InterestRateCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
    membership=Depends(get_current_farm_membership),
):
    return service.create_interest_rate(
        db, membership.farm_id, user.id, payload.rate_date, payload.cdi_annual, payload.sofr_annual
    )


@router.get("/interest/latest", response_model=InterestRateRead | None)
def latest_interest(
    db: Session = Depends(get_db),
    membership=Depends(get_current_farm_membership),
):
    return service.latest_interest_rate(db, membership.farm_id)


@router.post("/offset", response_model=OffsetRead, status_code=status.HTTP_201_CREATED)
def create_offset(
    payload: OffsetCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
    membership=Depends(get_current_farm_membership),
):
    return service.create_offset(db, membership.farm_id, user.id, payload.offset_value)


@router.get("/offset/latest", response_model=OffsetRead | None)
def latest_offset(
    db: Session = Depends(get_db),
    membership=Depends(get_current_farm_membership),
):
    return service.latest_offset(db, membership.farm_id)
