from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, ForeignKey, Integer, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base_class import Base
from app.db.mixins import TimestampMixin


class HedgePremium(Base, TimestampMixin):
    __tablename__ = "hedge_premium"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    contract_id: Mapped[int] = mapped_column(ForeignKey("contracts.id", ondelete="CASCADE"), index=True, nullable=False)
    executed_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)

    executado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True, nullable=False)

    volume_input_value: Mapped[Decimal] = mapped_column(Numeric(14, 4), nullable=False)
    volume_input_unit: Mapped[str] = mapped_column(String(10), nullable=False)
    volume_ton: Mapped[Decimal] = mapped_column(Numeric(14, 6), nullable=False)

    premium_value: Mapped[Decimal] = mapped_column(Numeric(18, 6), nullable=False)
    premium_unit: Mapped[str] = mapped_column(String(20), nullable=False)  # USD_BU|USD_TON

    base_local: Mapped[str | None] = mapped_column(String(80), nullable=True)
    observacao: Mapped[str | None] = mapped_column(String(255), nullable=True)

    contract = relationship("Contract", back_populates="hedges_premium")
