from datetime import datetime
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

    def nearest_run(self, db: Session, farm_id: int, ts: datetime) -> FxModelRun | None:
        # Busca o run mais próximo por diferença absoluta
        # (simples e eficiente com index em as_of_ts)
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

    def get_point(self, db: Session, run_id: int, ref_mes) -> FxModelPoint | None:
        return (
            db.query(FxModelPoint)
            .filter(FxModelPoint.run_id == run_id, FxModelPoint.ref_mes == ref_mes)
            .first()
        )
