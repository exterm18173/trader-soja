from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.deps import get_current_farm_membership
from app.db.session import get_db
from app.schemas.fx_model import FxModelRunRead
from app.services.fx_model_service import FxModelService

router = APIRouter(prefix="/fx/model", tags=["FX Model"])
service = FxModelService()


@router.get("/latest", response_model=FxModelRunRead | None)
def latest_run(
    db: Session = Depends(get_db),
    membership=Depends(get_current_farm_membership),
):
    return service.latest_run(db, membership.farm_id)
