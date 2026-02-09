from datetime import datetime
from decimal import Decimal

from sqlalchemy import ForeignKey, DateTime, Numeric, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base_class import Base
from app.db.mixins import TimestampMixin


class FxSpotTick(Base, TimestampMixin):
    __tablename__ = "fx_spot_ticks"
    __table_args__ = (
        UniqueConstraint("farm_id", "ts", name="uq_fx_spot_ticks_farm_ts"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)

    farm_id: Mapped[int] = mapped_column(
        ForeignKey("farms.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    ts: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)

    # melhor que float
    price: Mapped[Decimal] = mapped_column(Numeric(18, 6), nullable=False)

    source: Mapped[str] = mapped_column(String(40), default="yahoo_chart", nullable=False)
