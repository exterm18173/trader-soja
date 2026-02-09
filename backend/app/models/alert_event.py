# app/models/alert_event.py
from datetime import datetime
from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base_class import Base
from app.db.mixins import TimestampMixin

class AlertEvent(Base, TimestampMixin):
    __tablename__ = "alert_events"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    farm_id: Mapped[int] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), index=True, nullable=False)
    rule_id: Mapped[int | None] = mapped_column(
        ForeignKey("alert_rules.id", ondelete="SET NULL"), index=True, nullable=True
    )

    triggered_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True, nullable=False)

    severity: Mapped[str] = mapped_column(String(10), default="INFO", nullable=False)
    title: Mapped[str] = mapped_column(String(160), nullable=False)
    message: Mapped[str] = mapped_column(String(400), nullable=False)

    read: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False, index=True)
