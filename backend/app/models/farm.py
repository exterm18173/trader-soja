# app/models/farm.py
from sqlalchemy import String, Boolean
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base_class import Base
from app.db.mixins import TimestampMixin

class Farm(Base, TimestampMixin):
    __tablename__ = "farms"

    id: Mapped[int] = mapped_column(primary_key=True)
    nome: Mapped[str] = mapped_column(String(200), nullable=False, index=True)

    ativo: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, server_default="true"
    )
