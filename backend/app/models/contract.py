from datetime import date
from sqlalchemy import Date, ForeignKey, Integer, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base_class import Base
from app.db.mixins import TimestampMixin



class Contract(Base, TimestampMixin):
    __tablename__ = "contracts"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    farm_id: Mapped[int] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), index=True, nullable=False)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)

    produto: Mapped[str] = mapped_column(String(20), default="SOJA", nullable=False)

    # "CBOT_PREMIO" ou "FIXO_BRL"
    tipo_precificacao: Mapped[str] = mapped_column(String(20), nullable=False)

    volume_input_value: Mapped[float] = mapped_column(Numeric(14, 4), nullable=False)
    volume_input_unit: Mapped[str] = mapped_column(String(10), nullable=False)  # TON|SACA
    volume_total_ton: Mapped[float] = mapped_column(Numeric(14, 6), nullable=False)

    data_entrega: Mapped[date] = mapped_column(Date, index=True, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="ABERTO", nullable=False)

    # apenas para FIXO_BRL
    preco_fixo_brl_value: Mapped[float | None] = mapped_column(Numeric(14, 4), nullable=True)
    preco_fixo_brl_unit: Mapped[str | None] = mapped_column(String(20), nullable=True)  # BRL_SACA|BRL_TON

    observacao: Mapped[str | None] = mapped_column(String(255), nullable=True)

    hedges_cbot = relationship("HedgeCbot", back_populates="contract", cascade="all, delete-orphan")
    hedges_premium = relationship("HedgePremium", back_populates="contract", cascade="all, delete-orphan")
    hedges_fx = relationship("HedgeFx", back_populates="contract", cascade="all, delete-orphan")
