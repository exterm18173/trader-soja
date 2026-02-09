from datetime import date
from decimal import Decimal

from sqlalchemy import ForeignKey, Date, Numeric, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base_class import Base
from app.db.mixins import TimestampMixin


class FxModelPoint(Base, TimestampMixin):
    __tablename__ = "fx_model_points"
    __table_args__ = (
        UniqueConstraint("run_id", "ref_mes", name="uq_fx_model_points_run_ref"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)

    run_id: Mapped[int] = mapped_column(ForeignKey("fx_model_runs.id", ondelete="CASCADE"), nullable=False, index=True)

    ref_mes: Mapped[date] = mapped_column(Date, nullable=False, index=True)  # YYYY-MM-01
    t_anos: Mapped[Decimal] = mapped_column(Numeric(18, 8), nullable=False)

    dolar_sint: Mapped[Decimal] = mapped_column(Numeric(18, 6), nullable=False)
    dolar_desc: Mapped[Decimal] = mapped_column(Numeric(18, 6), nullable=False)
