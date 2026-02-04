from sqlalchemy import ForeignKey, Date, DateTime, Float, func, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base_class import Base


class FxModelPoint(Base):
    __tablename__ = "fx_model_points"
    __table_args__ = (
        UniqueConstraint("run_id", "ref_mes", name="uq_fx_model_points_run_ref"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    run_id: Mapped[int] = mapped_column(ForeignKey("fx_model_runs.id", ondelete="CASCADE"), nullable=False, index=True)

    ref_mes: Mapped[Date] = mapped_column(Date, nullable=False, index=True)  # YYYY-MM-01
    t_anos: Mapped[float] = mapped_column(Float, nullable=False)

    dolar_sint: Mapped[float] = mapped_column(Float, nullable=False)
    dolar_desc: Mapped[float] = mapped_column(Float, nullable=False)

    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )
