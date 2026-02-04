from datetime import date, datetime
from sqlalchemy import Date, DateTime, ForeignKey, Integer, Numeric, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base_class import Base
from app.db.mixins import TimestampMixin


class FxQuote(Base, TimestampMixin):
    __tablename__ = "fx_quotes"
    __table_args__ = (
        UniqueConstraint("farm_id", "source_id", "capturado_em", "ref_mes", name="uq_fx_quote"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    farm_id: Mapped[int] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), index=True, nullable=False)
    source_id: Mapped[int] = mapped_column(ForeignKey("fx_sources.id", ondelete="RESTRICT"), index=True, nullable=False)

    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)

    # ✅ aqui era str; deve ser datetime
    capturado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True, nullable=False)

    ref_mes: Mapped[date] = mapped_column(Date, index=True, nullable=False)
    brl_per_usd: Mapped[float] = mapped_column(Numeric(12, 6), nullable=False)

    observacao: Mapped[str | None] = mapped_column(String(255), nullable=True)

    check = relationship(
        "FxQuoteCheck",
        back_populates="quote",
        uselist=False,
        cascade="all, delete-orphan",
    )
