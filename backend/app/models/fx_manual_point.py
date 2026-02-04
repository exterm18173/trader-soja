from sqlalchemy import ForeignKey, Date, DateTime, Float, func, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base_class import Base


class FxManualPoint(Base):
    """
    Cotação manual do comprador (ex: AMAGGI) para o dólar do mês futuro.

    Ex:
      ref_mes = 2026-08-01
      fx = 5.7895
      captured_at = 2026-02-04 15:52:12 -03 (salva como timestamptz)
    """

    __tablename__ = "fx_manual_points"
    __table_args__ = (
        UniqueConstraint("farm_id", "source_id", "captured_at", "ref_mes", name="uq_fx_manual_point"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)

    farm_id: Mapped[int] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), nullable=False, index=True)
    source_id: Mapped[int] = mapped_column(ForeignKey("fx_sources.id", ondelete="RESTRICT"), nullable=False, index=True)

    captured_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    ref_mes: Mapped[Date] = mapped_column(Date, nullable=False, index=True)  # YYYY-MM-01
    fx: Mapped[float] = mapped_column(Float, nullable=False)

    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )
