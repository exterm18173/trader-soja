# app/api/routers/dashboard.py
from datetime import date
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.deps import get_farm_membership_from_path
from app.db.session import get_db
from app.schemas.dashboard_usd import UsdExposureResponse
from app.services.dashboard_service import DashboardService

router = APIRouter(prefix="/farms/{farm_id}/dashboard", tags=["Dashboard"])
service = DashboardService()


@router.get("/usd-exposure", response_model=UsdExposureResponse)
def usd_exposure(
    farm_id: int,
    from_mes: date | None = Query(default=None),
    to_mes: date | None = Query(default=None),
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.usd_exposure(db, farm_id, from_mes=from_mes, to_mes=to_mes)
