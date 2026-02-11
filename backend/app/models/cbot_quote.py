# app/models/cbot_quote.py
from datetime import datetime, date
from decimal import Decimal
from sqlalchemy import ForeignKey, Date, DateTime, Numeric, String, UniqueConstraint, Index
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base_class import Base
from app.db.mixins import TimestampMixin

class CbotQuote(Base, TimestampMixin):
    __tablename__ = "cbot_quotes"
    __table_args__ = (
        # ✅ inclui ref_mes (pra poder salvar ZS=F para meses diferentes, se quiser)
        UniqueConstraint("farm_id", "capturado_em", "symbol", "ref_mes", name="uq_cbot_quotes_farm_ts_symbol_refmes"),
        Index("ix_cbot_quotes_farm_symbol_refmes_ts", "farm_id", "symbol", "ref_mes", "capturado_em"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)

    farm_id: Mapped[int] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), index=True, nullable=False)
    source_id: Mapped[int] = mapped_column(ForeignKey("cbot_sources.id", ondelete="RESTRICT"), index=True, nullable=False)

    capturado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True, nullable=False)
    symbol: Mapped[str] = mapped_column(String(30), index=True, nullable=False)

    # ✅ NOVO
    ref_mes: Mapped[date | None] = mapped_column(Date, index=True, nullable=True)

    price_usd_per_bu: Mapped[Decimal] = mapped_column(Numeric(18, 6), nullable=False)
