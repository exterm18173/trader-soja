from datetime import datetime
from decimal import Decimal

from sqlalchemy import ForeignKey, DateTime, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base_class import Base
from app.db.mixins import TimestampMixin


class FxModelRun(Base, TimestampMixin):
    __tablename__ = "fx_model_runs"

    id: Mapped[int] = mapped_column(primary_key=True)

    farm_id: Mapped[int] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), nullable=False, index=True)
    as_of_ts: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)

    spot_usdbrl: Mapped[Decimal] = mapped_column(Numeric(18, 6), nullable=False)

    cdi_annual: Mapped[Decimal] = mapped_column(Numeric(10, 6), nullable=False)
    sofr_annual: Mapped[Decimal] = mapped_column(Numeric(10, 6), nullable=False)
    offset_value: Mapped[Decimal] = mapped_column(Numeric(10, 6), nullable=False)

    coupon_annual: Mapped[Decimal] = mapped_column(Numeric(10, 6), nullable=False)
    desconto_pct: Mapped[Decimal] = mapped_column(Numeric(10, 6), nullable=False, default=Decimal("0"))

    model_version: Mapped[str] = mapped_column(String(80), nullable=False)
    source: Mapped[str] = mapped_column(String(40), nullable=False)
