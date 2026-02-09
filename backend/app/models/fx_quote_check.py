from datetime import date
from decimal import Decimal

from sqlalchemy import Date, ForeignKey, Integer, Numeric, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base_class import Base
from app.db.mixins import TimestampMixin


class FxQuoteCheck(Base, TimestampMixin):
    __tablename__ = "fx_quote_checks"
    __table_args__ = (
        UniqueConstraint("quote_id", name="uq_fx_quote_checks_quote_id"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    quote_id: Mapped[int] = mapped_column(ForeignKey("fx_quotes.id", ondelete="CASCADE"), nullable=False, index=True)
    farm_id: Mapped[int] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), nullable=False, index=True)

    manual_point_id: Mapped[int] = mapped_column(ForeignKey("fx_manual_points.id", ondelete="CASCADE"), nullable=False, index=True)

    model_run_id: Mapped[int | None] = mapped_column(ForeignKey("fx_model_runs.id", ondelete="SET NULL"), nullable=True, index=True)
    model_point_id: Mapped[int | None] = mapped_column(ForeignKey("fx_model_points.id", ondelete="SET NULL"), nullable=True, index=True)

    ref_mes: Mapped[date] = mapped_column(Date, nullable=False, index=True)

    fx_manual: Mapped[Decimal] = mapped_column(Numeric(18, 6), nullable=False)
    fx_model: Mapped[Decimal] = mapped_column(Numeric(18, 6), nullable=False)

    delta_abs: Mapped[Decimal] = mapped_column(Numeric(18, 6), nullable=False)
    delta_pct: Mapped[Decimal] = mapped_column(Numeric(18, 6), nullable=False)

    quote = relationship("FxQuote", back_populates="check", uselist=False)
