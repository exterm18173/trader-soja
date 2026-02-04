from sqlalchemy import ForeignKey, DateTime, Float, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base_class import Base


class FxModelRun(Base):
    __tablename__ = "fx_model_runs"

    id: Mapped[int] = mapped_column(primary_key=True)
    farm_id: Mapped[int] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), nullable=False, index=True)

    as_of_ts: Mapped[DateTime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)

    spot_usdbrl: Mapped[float] = mapped_column(Float, nullable=False)
    cdi_annual: Mapped[float] = mapped_column(Float, nullable=False)
    sofr_annual: Mapped[float] = mapped_column(Float, nullable=False)
    offset_value: Mapped[float] = mapped_column(Float, nullable=False)

    coupon_annual: Mapped[float] = mapped_column(Float, nullable=False)
    desconto_pct: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)

    model_version: Mapped[str] = mapped_column(String(80), nullable=False)
    source: Mapped[str] = mapped_column(String(40), nullable=False)

    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )
