# app/api/routers/fx_spot.py
from datetime import datetime
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.deps import get_farm_membership_from_path
from app.db.session import get_db
from app.schemas.fx_spot import FxSpotTickCreate, FxSpotTickRead
from app.services.fx_spot_service import FxSpotService

router = APIRouter(prefix="/farms/{farm_id}/fx/spot", tags=["FX Spot"])
service = FxSpotService()


@router.post("", response_model=FxSpotTickRead, status_code=status.HTTP_201_CREATED)
def create_tick(
    farm_id: int,
    payload: FxSpotTickCreate,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.create(db, farm_id, payload)


@router.get("/latest", response_model=FxSpotTickRead | None)
def latest_tick(
    farm_id: int,
    source: str | None = Query(default=None),
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.latest(db, farm_id, source=source)


@router.get("", response_model=list[FxSpotTickRead])
def list_ticks(
    farm_id: int,
    from_ts: str | None = Query(default=None),
    to_ts: str | None = Query(default=None),
    source: str | None = Query(default=None),
    limit: int = Query(default=2000, ge=1, le=20000),
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

    return service.list(
        db,
        farm_id,
        from_ts=parse_iso(from_ts),
        to_ts=parse_iso(to_ts),
        source=source,
        limit=limit,
    )
