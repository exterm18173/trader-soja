from sqlalchemy import ForeignKey, DateTime, Float, String, func, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base_class import Base


class FxSpotTick(Base):
    __tablename__ = "fx_spot_ticks"
    __table_args__ = (
        UniqueConstraint("farm_id", "ts", name="uq_fx_spot_ticks_farm_ts"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    farm_id: Mapped[int] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), nullable=False, index=True)

    ts: Mapped[DateTime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    price: Mapped[float] = mapped_column(Float, nullable=False)
    source: Mapped[str] = mapped_column(String(40), default="yahoo_chart", nullable=False)

    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )
