from sqlalchemy import ForeignKey, Integer, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base_class import Base
from app.db.mixins import TimestampMixin



class ExpenseUsd(Base, TimestampMixin):
    __tablename__ = "expenses_usd"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    farm_id: Mapped[int] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), index=True, nullable=False)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)

    mes_competencia: Mapped[str] = mapped_column(String(7), index=True, nullable=False)  # YYYY-MM
    valor_usd: Mapped[float] = mapped_column(Numeric(18, 6), nullable=False)

    categoria: Mapped[str | None] = mapped_column(String(80), nullable=True)
    descricao: Mapped[str | None] = mapped_column(String(255), nullable=True)
