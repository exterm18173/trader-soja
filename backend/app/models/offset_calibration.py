from sqlalchemy import ForeignKey, Float, DateTime, func, Index
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base_class import Base


class OffsetCalibration(Base):
    __tablename__ = "offset_calibration"

    id: Mapped[int] = mapped_column(primary_key=True)
    farm_id: Mapped[int] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), nullable=False, index=True)

    offset_value: Mapped[float] = mapped_column(Float, nullable=False)  # ex 0.0015 (p.p. em forma decimal)
    note: Mapped[str | None] = mapped_column(nullable=True)

    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )


Index("ix_offset_calibration_farm_id_id", OffsetCalibration.farm_id, OffsetCalibration.id)
