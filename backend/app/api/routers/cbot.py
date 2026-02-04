from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.deps import get_current_farm_membership
from app.db.session import get_db
from app.schemas.cbot import CbotQuoteRead
from app.services.cbot_service import CbotService

router = APIRouter(prefix="/cbot", tags=["CBOT"])
service = CbotService()


@router.get("/latest", response_model=CbotQuoteRead | None)
def latest_cbot(
    symbol: str = Query(default="ZS=F"),
    db: Session = Depends(get_db),
    membership=Depends(get_current_farm_membership),
):
    return service.latest_quote(db, membership.farm_id, symbol=symbol)
