from sqlalchemy import ForeignKey, DateTime, Float, String, func, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base_class import Base


class CbotQuote(Base):
    __tablename__ = "cbot_quotes"
    __table_args__ = (
        UniqueConstraint("farm_id", "capturado_em", "symbol", name="uq_cbot_quotes_farm_ts_symbol"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)

    farm_id: Mapped[int] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), nullable=False, index=True)
    source_id: Mapped[int] = mapped_column(ForeignKey("cbot_sources.id", ondelete="RESTRICT"), nullable=False, index=True)

    capturado_em: Mapped[DateTime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    symbol: Mapped[str] = mapped_column(String(30), nullable=False, index=True)  # ex: ZS=F
    price_usd_per_bu: Mapped[float] = mapped_column(Float, nullable=False)

    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )
