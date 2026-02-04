from sqlalchemy import ForeignKey, String, Boolean, DateTime, func, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base_class import Base


class FarmUser(Base):
    __tablename__ = "farm_users"
    __table_args__ = (
        UniqueConstraint("farm_id", "user_id", name="uq_farm_users_farm_user"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)

    farm_id: Mapped[int] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    role: Mapped[str] = mapped_column(String(40), default="admin", nullable=False)
    ativo: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )
