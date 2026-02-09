from datetime import date
from decimal import Decimal

from sqlalchemy import Date, ForeignKey, Numeric, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base_class import Base
from app.db.mixins import TimestampMixin


class InterestRate(Base, TimestampMixin):
    __tablename__ = "interest_rates"
    __table_args__ = (
        UniqueConstraint("farm_id", "rate_date", name="uq_interest_rates_farm_date"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    farm_id: Mapped[int] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), nullable=False, index=True)

    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)

    rate_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)

    # ex: 0.105000 (10.5% a.a.)
    cdi_annual: Mapped[Decimal] = mapped_column(Numeric(10, 6), nullable=False)
    sofr_annual: Mapped[Decimal] = mapped_column(Numeric(10, 6), nullable=False)
