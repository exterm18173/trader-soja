from datetime import date
from sqlalchemy import Date, DateTime, ForeignKey, Integer, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base_class import Base
from app.db.mixins import TimestampMixin



class HedgeCbot(Base, TimestampMixin):
    __tablename__ = "hedge_cbot"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    contract_id: Mapped[int] = mapped_column(ForeignKey("contracts.id", ondelete="CASCADE"), index=True, nullable=False)
    executed_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)

    executado_em: Mapped[str] = mapped_column(DateTime(timezone=True), index=True, nullable=False)

    volume_input_value: Mapped[float] = mapped_column(Numeric(14, 4), nullable=False)
    volume_input_unit: Mapped[str] = mapped_column(String(10), nullable=False)  # TON|SACA
    volume_ton: Mapped[float] = mapped_column(Numeric(14, 6), nullable=False)

    cbot_usd_per_bu: Mapped[float] = mapped_column(Numeric(14, 6), nullable=False)

    ref_mes: Mapped[date | None] = mapped_column(Date, nullable=True)  # YYYY-MM-01 opcional
    symbol: Mapped[str | None] = mapped_column(String(30), nullable=True)

    observacao: Mapped[str | None] = mapped_column(String(255), nullable=True)

    contract = relationship("Contract", back_populates="hedges_cbot")
