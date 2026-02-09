# app/api/routers/fx_model.py
from datetime import datetime, date
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.deps import get_farm_membership_from_path
from app.db.session import get_db
from app.schemas.fx_model import FxModelRunRead, FxModelPointRead, FxModelRunWithPointsRead
from app.services.fx_model_service import FxModelService

router = APIRouter(prefix="/farms/{farm_id}/fx/model", tags=["FX Model"])
service = FxModelService()


@router.get("/runs", response_model=list[FxModelRunRead])
def list_runs(
    farm_id: int,
    from_ts: str | None = Query(default=None),
    to_ts: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=500),
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

    return service.list_runs(db, farm_id, from_ts=parse_iso(from_ts), to_ts=parse_iso(to_ts), limit=limit)


@router.get("/runs/latest", response_model=FxModelRunRead | None)
def latest_run(
    farm_id: int,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.latest_run(db, farm_id)


@router.get("/runs/nearest", response_model=FxModelRunRead | None)
def nearest_run(
    farm_id: int,
    ts: str = Query(...),
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    try:
        dts = datetime.fromisoformat(ts.replace("Z", "+00:00"))
    except Exception:
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail="ts inválido (ISO datetime)")

    return service.nearest_run(db, farm_id, dts)


@router.get("/runs/{run_id}", response_model=FxModelRunWithPointsRead)
def get_run(
    farm_id: int,
    run_id: int,
    include_points: bool = Query(default=True),
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    run = service.get_run(db, farm_id, run_id)
    if not include_points:
        # FastAPI vai serializar só os campos do run; points default []
        return {"points": [], **run.__dict__}  # se isso te incomodar, eu faço schema separado

    points = service.list_points(db, farm_id, run_id)
    return {"points": points, **run.__dict__}


@router.get("/runs/{run_id}/points", response_model=list[FxModelPointRead])
def list_points(
    farm_id: int,
    run_id: int,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.list_points(db, farm_id, run_id)


@router.get("/runs/{run_id}/points/{ref_mes}", response_model=FxModelPointRead | None)
def get_point(
    farm_id: int,
    run_id: int,
    ref_mes: date,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.get_point(db, farm_id, run_id, ref_mes)
