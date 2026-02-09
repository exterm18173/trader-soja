from decimal import Decimal

from sqlalchemy import ForeignKey, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base_class import Base
from app.db.mixins import TimestampMixin


class OffsetCalibration(Base, TimestampMixin):
    __tablename__ = "offset_calibration"

    id: Mapped[int] = mapped_column(primary_key=True)
    farm_id: Mapped[int] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), nullable=False, index=True)

    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)

    offset_value: Mapped[Decimal] = mapped_column(Numeric(10, 6), nullable=False)
    note: Mapped[str | None] = mapped_column(String(255), nullable=True)
