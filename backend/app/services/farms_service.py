# app/services/farms_service.py
from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from sqlalchemy.orm import joinedload
from app.models.farm import Farm
from app.models.farm_user import FarmUser
from app.models.user import User

ROLE_OWNER = "OWNER"
ROLE_ADMIN = "ADMIN"
ROLE_TRADER = "TRADER"
ROLE_VIEWER = "VIEWER"

ALLOWED_ROLES = {ROLE_OWNER, ROLE_ADMIN, ROLE_TRADER, ROLE_VIEWER}


def _norm_role(role: str) -> str:
    r = (role or "").strip().upper()
    if r not in ALLOWED_ROLES:
        raise HTTPException(status_code=400, detail=f"role inválido. Use: {sorted(ALLOWED_ROLES)}")
    return r


def _require_admin(membership: FarmUser) -> None:
    if membership.role not in {ROLE_OWNER, ROLE_ADMIN}:
        raise HTTPException(status_code=403, detail="Ação permitida apenas para OWNER/ADMIN")


class FarmsService:
    # -------- FARMS --------
    def create_farm(self, db: Session, user: User, nome: str) -> Farm:
        nome = (nome or "").strip()
        if not nome:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nome inválido")

        farm = Farm(nome=nome, ativo=True)
        db.add(farm)

        try:
            db.flush()  # pega farm.id antes do commit
        except IntegrityError:
            db.rollback()
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Já existe uma fazenda com esse nome")

        link = FarmUser(farm_id=farm.id, user_id=user.id, role=ROLE_OWNER, ativo=True)
        db.add(link)

        db.commit()
        db.refresh(farm)
        return farm

    def list_my_memberships(self, db: Session, user: User) -> list[FarmUser]:
        return (
            db.query(FarmUser)
            .options(joinedload(FarmUser.farm))
            .join(Farm, Farm.id == FarmUser.farm_id)
            .filter(
                FarmUser.user_id == user.id,
                FarmUser.ativo.is_(True),
                Farm.ativo.is_(True),
            )
            .order_by(FarmUser.id.desc())
            .all()
        )

    def get_farm(self, db: Session, farm_id: int) -> Farm:
        farm = db.query(Farm).filter(Farm.id == farm_id).first()
        if not farm:
            raise HTTPException(status_code=404, detail="Fazenda não encontrada")
        return farm

    def update_farm(self, db: Session, farm_id: int, payload) -> Farm:
        farm = self.get_farm(db, farm_id)

        if payload.nome is not None:
            nome = payload.nome.strip()
            if not nome:
                raise HTTPException(status_code=400, detail="Nome inválido")
            farm.nome = nome

        if payload.ativo is not None:
            farm.ativo = payload.ativo

        try:
            db.commit()
        except IntegrityError:
            db.rollback()
            raise HTTPException(status_code=409, detail="Já existe uma fazenda com esse nome")

        db.refresh(farm)
        return farm

    # -------- MEMBERS --------
    def list_members(self, db: Session, farm_id: int) -> list[FarmUser]:
        return (
            db.query(FarmUser)
            .filter(FarmUser.farm_id == farm_id)
            .order_by(FarmUser.id.desc())
            .all()
        )

    def add_member(self, db: Session, farm_id: int, payload) -> FarmUser:
        role = _norm_role(payload.role)

        user = db.query(User).filter(User.id == payload.user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")

        # se já existir vínculo, atualiza (upsert)
        link = (
            db.query(FarmUser)
            .filter(FarmUser.farm_id == farm_id, FarmUser.user_id == payload.user_id)
            .first()
        )
        if link:
            link.role = role
            link.ativo = payload.ativo
            db.commit()
            db.refresh(link)
            return link

        link = FarmUser(farm_id=farm_id, user_id=payload.user_id, role=role, ativo=payload.ativo)
        db.add(link)
        db.commit()
        db.refresh(link)
        return link

    def update_member(self, db: Session, farm_id: int, membership_id: int, payload) -> FarmUser:
        link = (
            db.query(FarmUser)
            .filter(FarmUser.farm_id == farm_id, FarmUser.id == membership_id)
            .first()
        )
        if not link:
            raise HTTPException(status_code=404, detail="Vínculo não encontrado")

        if payload.role is not None:
            link.role = _norm_role(payload.role)
        if payload.ativo is not None:
            link.ativo = payload.ativo

        db.commit()
        db.refresh(link)
        return link
