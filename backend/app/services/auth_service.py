from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.core.security import hash_password, verify_password, create_access_token
from app.models.user import User


class AuthService:
    def register(self, db: Session, nome: str, email: str, senha: str) -> User:
        exists = db.query(User).filter(User.email == email).first()
        if exists:
            raise HTTPException(status_code=400, detail="Email já cadastrado")

        user = User(
            nome=nome.strip(),
            email=email.lower().strip(),
            senha_hash=hash_password(senha),
            ativo=True,
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        return user

    def login(self, db: Session, email: str, senha: str) -> str:
        user = db.query(User).filter(User.email == email.lower().strip()).first()
        if not user or not user.ativo:
            raise HTTPException(status_code=401, detail="Credenciais inválidas")

        if not verify_password(senha, user.senha_hash):
            raise HTTPException(status_code=401, detail="Credenciais inválidas")

        return create_access_token(str(user.id))
