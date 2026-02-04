from datetime import date
from sqlalchemy import Date, DateTime, ForeignKey, Integer, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base_class import Base
from app.db.mixins import TimestampMixin



class HedgeFx(Base, TimestampMixin):
    __tablename__ = "hedge_fx"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    contract_id: Mapped[int] = mapped_column(ForeignKey("contracts.id", ondelete="CASCADE"), index=True, nullable=False)
    executed_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)

    executado_em: Mapped[str] = mapped_column(DateTime(timezone=True), index=True, nullable=False)

    usd_amount: Mapped[float] = mapped_column(Numeric(18, 6), nullable=False)
    brl_per_usd: Mapped[float] = mapped_column(Numeric(14, 6), nullable=False)

    ref_mes: Mapped[date | None] = mapped_column(Date, nullable=True)  # YYYY-MM-01 opcional
    tipo: Mapped[str] = mapped_column(String(20), default="CURVA_SCRIPT", nullable=False)

    observacao: Mapped[str | None] = mapped_column(String(255), nullable=True)

    contract = relationship("Contract", back_populates="hedges_fx")
