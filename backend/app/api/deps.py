# app/core/deps.py  (ou onde você guarda)
from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.core.security import decode_token
from app.models.user import User
from app.models.farm_user import FarmUser

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    try:
        payload = decode_token(token)
        sub = payload.get("sub")
        if not sub:
            raise ValueError("Token sem sub")
        user_id = int(sub)
    except Exception:
        raise HTTPException(status_code=401, detail="Não autenticado")

    user = db.query(User).filter(User.id == user_id, User.ativo.is_(True)).first()
    if not user:
        raise HTTPException(status_code=401, detail="Usuário inválido")
    return user


def require_farm_membership(
    farm_id: int,
    user: User,
    db: Session,
) -> FarmUser:
    link = (
        db.query(FarmUser)
        .filter(
            FarmUser.farm_id == farm_id,
            FarmUser.user_id == user.id,
            FarmUser.ativo.is_(True),
        )
        .first()
    )
    if not link:
        raise HTTPException(status_code=403, detail="Sem acesso a esta fazenda")
    return link


def get_farm_membership_from_path(
    farm_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> FarmUser:
    return require_farm_membership(farm_id=farm_id, user=user, db=db)
