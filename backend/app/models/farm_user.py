# app/models/farm_user.py
from sqlalchemy import ForeignKey, String, Boolean, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base_class import Base
from app.db.mixins import TimestampMixin

class FarmUser(Base, TimestampMixin):
    __tablename__ = "farm_users"
    __table_args__ = (
        UniqueConstraint("farm_id", "user_id", name="uq_farm_users_farm_user"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)

    farm_id: Mapped[int] = mapped_column(
        ForeignKey("farms.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )

    # ✅ evita circular import: não puxa do service
    role: Mapped[str] = mapped_column(String(40), nullable=False, default="VIEWER")
    ativo: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    farm = relationship("Farm")
    user = relationship("User")
