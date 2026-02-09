# app/models/cbot_quote.py
from datetime import datetime
from decimal import Decimal
from sqlalchemy import ForeignKey, DateTime, Numeric, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base_class import Base
from app.db.mixins import TimestampMixin

class CbotQuote(Base, TimestampMixin):
    __tablename__ = "cbot_quotes"
    __table_args__ = (
        UniqueConstraint("farm_id", "capturado_em", "symbol", name="uq_cbot_quotes_farm_ts_symbol"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)

    farm_id: Mapped[int] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), index=True, nullable=False)
    source_id: Mapped[int] = mapped_column(ForeignKey("cbot_sources.id", ondelete="RESTRICT"), index=True, nullable=False)

    capturado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True, nullable=False)
    symbol: Mapped[str] = mapped_column(String(30), index=True, nullable=False)

    price_usd_per_bu: Mapped[Decimal] = mapped_column(Numeric(18, 6), nullable=False)
