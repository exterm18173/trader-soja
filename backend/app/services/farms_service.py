from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.farm import Farm
from app.models.farm_user import FarmUser
from app.models.user import User


class FarmsService:
    def create_farm(self, db: Session, user: User, nome: str) -> Farm:
        nome = nome.strip()
        if not nome:
            raise HTTPException(status_code=400, detail="Nome inválido")

        farm = Farm(nome=nome, ativo=True)
        db.add(farm)
        db.flush()  # pega farm.id antes do commit

        link = FarmUser(farm_id=farm.id, user_id=user.id, role="OWNER", ativo=True)
        db.add(link)

        db.commit()
        db.refresh(farm)
        return farm

    def list_my_farms(self, db: Session, user: User) -> list[FarmUser]:
        return (
            db.query(FarmUser)
            .filter(FarmUser.user_id == user.id, FarmUser.ativo.is_(True))
            .order_by(FarmUser.id.desc())
            .all()
        )
