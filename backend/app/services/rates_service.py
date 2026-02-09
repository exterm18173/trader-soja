# app/services/rates_service.py
from __future__ import annotations

from datetime import date
from fastapi import HTTPException
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.interest_rate import InterestRate
from app.models.offset_calibration import OffsetCalibration


class RatesService:
    # ---------- Interest ----------
    def create_interest_rate(
        self,
        db: Session,
        farm_id: int,
        user_id: int,
        rate_date: date,
        cdi: float,
        sofr: float,
    ) -> InterestRate:
        row = InterestRate(
            farm_id=farm_id,
            created_by_user_id=user_id,
            rate_date=rate_date,
            cdi_annual=cdi,
            sofr_annual=sofr,
        )
        db.add(row)
        try:
            db.commit()
        except IntegrityError:
            db.rollback()
            raise HTTPException(status_code=409, detail="Já existe taxa para esta data (farm_id + rate_date)")
        db.refresh(row)
        return row

    def list_interest_rates(
        self,
        db: Session,
        farm_id: int,
        from_date: date | None = None,
        to_date: date | None = None,
    ) -> list[InterestRate]:
        q = db.query(InterestRate).filter(InterestRate.farm_id == farm_id)
        if from_date:
            q = q.filter(InterestRate.rate_date >= from_date)
        if to_date:
            q = q.filter(InterestRate.rate_date <= to_date)
        return q.order_by(InterestRate.rate_date.desc(), InterestRate.id.desc()).all()

    def latest_interest_rate(self, db: Session, farm_id: int) -> InterestRate | None:
        return (
            db.query(InterestRate)
            .filter(InterestRate.farm_id == farm_id)
            .order_by(InterestRate.rate_date.desc(), InterestRate.id.desc())
            .first()
        )

    def update_interest_rate(
        self,
        db: Session,
        farm_id: int,
        row_id: int,
        payload,
    ) -> InterestRate:
        row = (
            db.query(InterestRate)
            .filter(InterestRate.farm_id == farm_id, InterestRate.id == row_id)
            .first()
        )
        if not row:
            raise HTTPException(status_code=404, detail="Taxa não encontrada")

        if payload.cdi_annual is not None:
            row.cdi_annual = payload.cdi_annual
        if payload.sofr_annual is not None:
            row.sofr_annual = payload.sofr_annual

        db.commit()
        db.refresh(row)
        return row

    def upsert_interest_rate(
        self,
        db: Session,
        farm_id: int,
        user_id: int,
        rate_date: date,
        cdi: float,
        sofr: float,
    ) -> InterestRate:
        row = (
            db.query(InterestRate)
            .filter(InterestRate.farm_id == farm_id, InterestRate.rate_date == rate_date)
            .first()
        )
        if row:
            row.cdi_annual = cdi
            row.sofr_annual = sofr
            # opcional: manter created_by original ou atualizar?
            # aqui vou manter o original.
            db.commit()
            db.refresh(row)
            return row

        return self.create_interest_rate(db, farm_id, user_id, rate_date, cdi, sofr)

    # ---------- Offset ----------
    def create_offset(self, db: Session, farm_id: int, user_id: int, offset_value: float, note: str | None = None) -> OffsetCalibration:
        row = OffsetCalibration(
            farm_id=farm_id,
            created_by_user_id=user_id,
            offset_value=offset_value,
            note=note,
        )
        db.add(row)
        db.commit()
        db.refresh(row)
        return row

    def latest_offset(self, db: Session, farm_id: int) -> OffsetCalibration | None:
        return (
            db.query(OffsetCalibration)
            .filter(OffsetCalibration.farm_id == farm_id)
            .order_by(OffsetCalibration.id.desc())
            .first()
        )

    def list_offsets(
        self,
        db: Session,
        farm_id: int,
        limit: int = 200,
    ) -> list[OffsetCalibration]:
        return (
            db.query(OffsetCalibration)
            .filter(OffsetCalibration.farm_id == farm_id)
            .order_by(OffsetCalibration.id.desc())
            .limit(limit)
            .all()
        )
