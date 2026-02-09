from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import ForeignKey, Date, DateTime, Numeric, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base_class import Base
from app.db.mixins import TimestampMixin


class FxManualPoint(Base, TimestampMixin):
    __tablename__ = "fx_manual_points"
    __table_args__ = (
        UniqueConstraint("farm_id", "source_id", "captured_at", "ref_mes", name="uq_fx_manual_point"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)

    farm_id: Mapped[int] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), nullable=False, index=True)
    source_id: Mapped[int] = mapped_column(ForeignKey("fx_sources.id", ondelete="RESTRICT"), nullable=False, index=True)

    # quem lançou manualmente (muito útil)
    created_by_user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True)

    captured_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    ref_mes: Mapped[date] = mapped_column(Date, nullable=False, index=True)  # YYYY-MM-01

    fx: Mapped[Decimal] = mapped_column(Numeric(18, 6), nullable=False)
