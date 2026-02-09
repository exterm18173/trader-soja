# app/services/fx_model_service.py
from __future__ import annotations

from datetime import datetime
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.fx_model_run import FxModelRun
from app.models.fx_model_point import FxModelPoint


class FxModelService:
    def latest_run(self, db: Session, farm_id: int) -> FxModelRun | None:
        return (
            db.query(FxModelRun)
            .filter(FxModelRun.farm_id == farm_id)
            .order_by(FxModelRun.as_of_ts.desc(), FxModelRun.id.desc())
            .first()
        )

    def list_runs(self, db: Session, farm_id: int, from_ts: datetime | None = None, to_ts: datetime | None = None, limit: int = 50) -> list[FxModelRun]:
        q = db.query(FxModelRun).filter(FxModelRun.farm_id == farm_id)
        if from_ts:
            q = q.filter(FxModelRun.as_of_ts >= from_ts)
        if to_ts:
            q = q.filter(FxModelRun.as_of_ts <= to_ts)
        return q.order_by(FxModelRun.as_of_ts.desc(), FxModelRun.id.desc()).limit(limit).all()

    def get_run(self, db: Session, farm_id: int, run_id: int) -> FxModelRun:
        run = (
            db.query(FxModelRun)
            .filter(FxModelRun.farm_id == farm_id, FxModelRun.id == run_id)
            .first()
        )
        if not run:
            raise HTTPException(status_code=404, detail="Run não encontrado")
        return run

    def nearest_run(self, db: Session, farm_id: int, ts: datetime) -> FxModelRun | None:
        before = (
            db.query(FxModelRun)
            .filter(FxModelRun.farm_id == farm_id, FxModelRun.as_of_ts <= ts)
            .order_by(FxModelRun.as_of_ts.desc())
            .first()
        )
        after = (
            db.query(FxModelRun)
            .filter(FxModelRun.farm_id == farm_id, FxModelRun.as_of_ts >= ts)
            .order_by(FxModelRun.as_of_ts.asc())
            .first()
        )

        if before and after:
            dbefore = abs((ts - before.as_of_ts).total_seconds())
            dafter = abs((after.as_of_ts - ts).total_seconds())
            return before if dbefore <= dafter else after

        return before or after

    def list_points(self, db: Session, farm_id: int, run_id: int) -> list[FxModelPoint]:
        # garante que o run pertence à farm
        self.get_run(db, farm_id, run_id)

        return (
            db.query(FxModelPoint)
            .filter(FxModelPoint.run_id == run_id)
            .order_by(FxModelPoint.ref_mes.asc())
            .all()
        )

    def get_point(self, db: Session, farm_id: int, run_id: int, ref_mes) -> FxModelPoint | None:
        self.get_run(db, farm_id, run_id)
        return (
            db.query(FxModelPoint)
            .filter(FxModelPoint.run_id == run_id, FxModelPoint.ref_mes == ref_mes)
            .first()
        )
