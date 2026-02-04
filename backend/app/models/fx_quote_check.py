from sqlalchemy import ForeignKey, Date, DateTime, Float, func, UniqueConstraint, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base_class import Base


class FxQuoteCheck(Base):
    __tablename__ = "fx_quote_checks"
    __table_args__ = (
        UniqueConstraint("quote_id", name="uq_fx_quote_checks_quote_id"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    # ✅ FK que faltava para ligar com fx_quotes
    quote_id: Mapped[int] = mapped_column(
        ForeignKey("fx_quotes.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    farm_id: Mapped[int] = mapped_column(
        ForeignKey("farms.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    manual_point_id: Mapped[int] = mapped_column(
        ForeignKey("fx_manual_points.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    model_run_id: Mapped[int | None] = mapped_column(
        ForeignKey("fx_model_runs.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    model_point_id: Mapped[int | None] = mapped_column(
        ForeignKey("fx_model_points.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    ref_mes: Mapped[Date] = mapped_column(Date, nullable=False, index=True)

    fx_manual: Mapped[float] = mapped_column(Float, nullable=False)
    fx_model: Mapped[float] = mapped_column(Float, nullable=False)

    delta_abs: Mapped[float] = mapped_column(Float, nullable=False)
    delta_pct: Mapped[float] = mapped_column(Float, nullable=False)

    created_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    # ✅ lado inverso do relationship
    quote = relationship("FxQuote", back_populates="check", uselist=False)
