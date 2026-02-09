# app/api/routers/cbot_quotes.py
from datetime import datetime
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.deps import get_farm_membership_from_path
from app.db.session import get_db
from app.schemas.cbot import CbotQuoteRead
from app.services.cbot_service import CbotService

router = APIRouter(prefix="/farms/{farm_id}/cbot/quotes", tags=["CBOT"])
service = CbotService()


@router.get("/latest", response_model=CbotQuoteRead | None)
def latest_cbot(
    farm_id: int,
    symbol: str = Query(default="ZS=F"),
    source_id: int | None = Query(default=None),
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.latest_quote(db, farm_id, symbol=symbol, source_id=source_id)


@router.get("", response_model=list[CbotQuoteRead])
def list_cbot_quotes(
    farm_id: int,
    symbol: str | None = Query(default=None),
    source_id: int | None = Query(default=None),
    from_ts: str | None = Query(default=None),
    to_ts: str | None = Query(default=None),
    limit: int = Query(default=500, ge=1, le=5000),
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    def parse_iso(s: str | None) -> datetime | None:
        if not s:
            return None
        try:
            return datetime.fromisoformat(s.replace("Z", "+00:00"))
        except Exception:
            from fastapi import HTTPException
            raise HTTPException(status_code=400, detail="from_ts/to_ts inválido (ISO datetime)")

    return service.list_quotes(
        db,
        farm_id,
        symbol=symbol,
        source_id=source_id,
        from_ts=parse_iso(from_ts),
        to_ts=parse_iso(to_ts),
        limit=limit,
    )


@router.get("/{quote_id}", response_model=CbotQuoteRead)
def get_cbot_quote(
    farm_id: int,
    quote_id: int,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.get_quote(db, farm_id, quote_id)
