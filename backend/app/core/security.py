# app/core/security.py
from datetime import datetime, timedelta, timezone
import hashlib
import bcrypt
from jose import jwt, JWTError

from app.core.config import settings

def _prehash_password(password: str) -> bytes:
    # sempre pré-hash (32 bytes) => sem limite de 72
    return hashlib.sha256(password.encode("utf-8")).digest()

def hash_password(password: str) -> str:
    pw = _prehash_password(password)
    salt = bcrypt.gensalt(rounds=12)  # custo ok
    hashed = bcrypt.hashpw(pw, salt)
    return hashed.decode("utf-8")

def verify_password(password: str, password_hash: str) -> bool:
    pw = _prehash_password(password)
    return bcrypt.checkpw(pw, password_hash.encode("utf-8"))

def create_access_token(sub: str) -> str:
    now = datetime.now(timezone.utc)
    exp = now + timedelta(minutes=int(settings.ACCESS_TOKEN_EXPIRE_MIN))
    payload = {"sub": sub, "iat": int(now.timestamp()), "exp": int(exp.timestamp())}
    return jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALG)

def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALG])
    except JWTError as e:
        raise ValueError("Token inválido") from e
