# app/services/fx_spot_service.py
from __future__ import annotations

from datetime import datetime
from fastapi import HTTPException
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.fx_spot_tick import FxSpotTick


class FxSpotService:
    def create(self, db: Session, farm_id: int, payload) -> FxSpotTick:
        row = FxSpotTick(
            farm_id=farm_id,
            ts=payload.ts,
            price=payload.price,
            source=payload.source.strip().upper(),
        )
        db.add(row)
        try:
            db.commit()
        except IntegrityError:
            db.rollback()
            raise HTTPException(status_code=409, detail="Tick já existe (farm_id, ts)")
        db.refresh(row)
        return row

    def latest(self, db: Session, farm_id: int, source: str | None = None) -> FxSpotTick | None:
        q = db.query(FxSpotTick).filter(FxSpotTick.farm_id == farm_id)
        if source:
            q = q.filter(FxSpotTick.source == source.strip().upper())
        return q.order_by(FxSpotTick.ts.desc(), FxSpotTick.id.desc()).first()

    def list(
        self,
        db: Session,
        farm_id: int,
        from_ts: datetime | None = None,
        to_ts: datetime | None = None,
        source: str | None = None,
        limit: int = 2000,
    ) -> list[FxSpotTick]:
        q = db.query(FxSpotTick).filter(FxSpotTick.farm_id == farm_id)
        if source:
            q = q.filter(FxSpotTick.source == source.strip().upper())
        if from_ts:
            q = q.filter(FxSpotTick.ts >= from_ts)
        if to_ts:
            q = q.filter(FxSpotTick.ts <= to_ts)

        return q.order_by(FxSpotTick.ts.desc(), FxSpotTick.id.desc()).limit(limit).all()
