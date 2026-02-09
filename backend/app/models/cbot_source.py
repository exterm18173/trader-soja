# app/models/cbot_source.py
from sqlalchemy import String, Boolean, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base_class import Base
from app.db.mixins import TimestampMixin

class CbotSource(Base, TimestampMixin):
    __tablename__ = "cbot_sources"
    __table_args__ = (UniqueConstraint("nome", name="uq_cbot_sources_nome"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    nome: Mapped[str] = mapped_column(String(60), nullable=False)
    ativo: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False, index=True)
