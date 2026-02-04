from sqlalchemy.orm import Session

from app.models.interest_rate import InterestRate
from app.models.offset_calibration import OffsetCalibration


class RatesService:
    def create_interest_rate(self, db: Session, farm_id: int, user_id: int, rate_date, cdi: float, sofr: float) -> InterestRate:
        row = InterestRate(
            farm_id=farm_id,
            created_by_user_id=user_id,
            rate_date=rate_date,
            cdi_annual=cdi,
            sofr_annual=sofr,
        )
        db.add(row)
        db.commit()
        db.refresh(row)
        return row

    def latest_interest_rate(self, db: Session, farm_id: int) -> InterestRate | None:
        return (
            db.query(InterestRate)
            .filter(InterestRate.farm_id == farm_id)
            .order_by(InterestRate.rate_date.desc(), InterestRate.id.desc())
            .first()
        )

    def create_offset(self, db: Session, farm_id: int, user_id: int, offset_value: float) -> OffsetCalibration:
        row = OffsetCalibration(
            farm_id=farm_id,
            created_by_user_id=user_id,
            offset_value=offset_value,
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
