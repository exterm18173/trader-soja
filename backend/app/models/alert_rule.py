from sqlalchemy import Boolean, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base_class import Base
from app.db.mixins import TimestampMixin



class AlertRule(Base, TimestampMixin):
    __tablename__ = "alert_rules"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    farm_id: Mapped[int] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), index=True, nullable=False)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)

    ativo: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # Exemplos: FX_CLOSE_TO_AMAGGI, FX_ABOVE, CBOT_ABOVE, PREMIUM_ABOVE
    tipo: Mapped[str] = mapped_column(String(40), index=True, nullable=False)

    # JSON simples em texto (por enquanto). Depois migramos para JSONB se quiser.
    params_json: Mapped[str] = mapped_column(String(1000), default="{}", nullable=False)

    nome: Mapped[str] = mapped_column(String(120), nullable=False)
