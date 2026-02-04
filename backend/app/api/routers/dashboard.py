from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.deps import get_current_farm_membership
from app.db.session import get_db
from app.schemas.dashboard import DashboardRead
from app.services.dashboard_service import DashboardService

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])
service = DashboardService()


@router.get("", response_model=DashboardRead)
def dashboard(
    db: Session = Depends(get_db),
    membership=Depends(get_current_farm_membership),
):
    return service.build(db, membership.farm_id)
