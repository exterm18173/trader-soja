# app/services/auth_service.py
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import hash_password, verify_password, create_access_token
from app.models.user import User

class AuthService:
    def register(self, db: Session, nome: str, email: str, senha: str) -> User:
        email_norm = email.lower().strip()
        nome_norm = nome.strip()

        exists = db.query(User).filter(User.email == email_norm).first()
        if exists:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email já cadastrado",
            )

        # Segurança extra (caso alguém bypass no schema)
        if len(senha.encode("utf-8")) > 72:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="A senha é muito longa. Máximo de 72 bytes (bcrypt).",
            )

        user = User(
            nome=nome_norm,
            email=email_norm,
            hashed_password=hash_password(senha),
            ativo=True,
        )

        db.add(user)
        db.commit()
        db.refresh(user)
        return user

    def login(self, db: Session, email: str, senha: str) -> str:
        email_norm = email.lower().strip()
        user = db.query(User).filter(User.email == email_norm).first()

        if not user or not user.ativo:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Credenciais inválidas")

        # Evita crash também no login se senha gigante
        if len(senha.encode("utf-8")) > 72:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Credenciais inválidas")

        if not verify_password(senha, user.hashed_password):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Credenciais inválidas")

        return create_access_token(str(user.id))
