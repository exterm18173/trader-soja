# app/schemas/auth.py
from pydantic import BaseModel, EmailStr, Field, field_validator

MAX_BCRYPT_BYTES = 72

class LoginRequest(BaseModel):
    email: EmailStr
    senha: str = Field(min_length=1, max_length=128)

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

class RegisterRequest(BaseModel):
    nome: str = Field(min_length=2, max_length=160)
    email: EmailStr
    # max_length é bom, mas o que manda é bytes no validator
    senha: str = Field(min_length=8, max_length=128)

    @field_validator("senha")
    @classmethod
    def senha_max_72_bytes(cls, v: str) -> str:
        if len(v.encode("utf-8")) > MAX_BCRYPT_BYTES:
            raise ValueError("A senha é muito longa. Máximo de 72 bytes (bcrypt).")
        return v
