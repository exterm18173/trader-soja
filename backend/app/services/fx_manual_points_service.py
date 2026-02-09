# app/services/fx_manual_points_service.py
from __future__ import annotations

from datetime import date
from fastapi import HTTPException
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.fx_manual_point import FxManualPoint
from app.models.fx_source import FxSource


class FxManualPointsService:
    def _source_or_404(self, db: Session, source_id: int) -> FxSource:
        src = db.query(FxSource).filter(FxSource.id == source_id, FxSource.ativo.is_(True)).first()
        if not src:
            raise HTTPException(status_code=404, detail="FX source_id inválido ou inativo")
        return src

    def _ensure_ref_mes(self, ref_mes: date) -> None:
        # padrão do sistema: ref_mes deve ser YYYY-MM-01
        if ref_mes.day != 1:
            raise HTTPException(status_code=400, detail="ref_mes deve ser o primeiro dia do mês (YYYY-MM-01)")

    def create(self, db: Session, farm_id: int, user_id: int, payload) -> FxManualPoint:
        self._source_or_404(db, payload.source_id)
        self._ensure_ref_mes(payload.ref_mes)

        row = FxManualPoint(
            farm_id=farm_id,
            source_id=payload.source_id,
            created_by_user_id=user_id,
            captured_at=payload.captured_at,
            ref_mes=payload.ref_mes,
            fx=payload.fx,
        )
        db.add(row)
        try:
            db.commit()
        except IntegrityError:
            db.rollback()
            raise HTTPException(status_code=409, detail="Ponto manual já existe (farm/source/captured_at/ref_mes)")
        db.refresh(row)
        return row

    def list(
        self,
        db: Session,
        farm_id: int,
        source_id: int | None = None,
        ref_mes=None,
        limit: int = 2000,
    ) -> list[FxManualPoint]:
        q = db.query(FxManualPoint).filter(FxManualPoint.farm_id == farm_id)
        if source_id is not None:
            self._source_or_404(db, source_id)
            q = q.filter(FxManualPoint.source_id == source_id)
        if ref_mes is not None:
            q = q.filter(FxManualPoint.ref_mes == ref_mes)

        return q.order_by(FxManualPoint.captured_at.desc(), FxManualPoint.id.desc()).limit(limit).all()

    def get(self, db: Session, farm_id: int, point_id: int) -> FxManualPoint:
        row = db.query(FxManualPoint).filter(FxManualPoint.farm_id == farm_id, FxManualPoint.id == point_id).first()
        if not row:
            raise HTTPException(status_code=404, detail="Ponto manual não encontrado")
        return row

    def update(self, db: Session, farm_id: int, point_id: int, payload) -> FxManualPoint:
        row = self.get(db, farm_id, point_id)

        if payload.captured_at is not None:
            row.captured_at = payload.captured_at
        if payload.ref_mes is not None:
            self._ensure_ref_mes(payload.ref_mes)
            row.ref_mes = payload.ref_mes
        if payload.fx is not None:
            row.fx = payload.fx

        try:
            db.commit()
        except IntegrityError:
            db.rollback()
            raise HTTPException(status_code=409, detail="Atualização gerou conflito (unique constraint)")
        db.refresh(row)
        return row

    def delete(self, db: Session, farm_id: int, point_id: int) -> None:
        row = self.get(db, farm_id, point_id)
        db.delete(row)
        db.commit()
