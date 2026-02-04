from sqlalchemy import ForeignKey, Date, Float, DateTime, func, Index
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base_class import Base


class InterestRate(Base):
    __tablename__ = "interest_rates"

    id: Mapped[int] = mapped_column(primary_key=True)
    farm_id: Mapped[int] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), nullable=False, index=True)

    rate_date: Mapped[Date] = mapped_column(Date, nullable=False, index=True)
    cdi_annual: Mapped[float] = mapped_column(Float, nullable=False)   # ex 0.105
    sofr_annual: Mapped[float] = mapped_column(Float, nullable=False)  # ex 0.052

    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )


Index("ix_interest_rates_farm_date", InterestRate.farm_id, InterestRate.rate_date)
