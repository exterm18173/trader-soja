# app/schemas/users.py
from pydantic import BaseModel, EmailStr

class UserRead(BaseModel):
    id: int
    nome: str
    email: EmailStr
    ativo: bool

    class Config:
        from_attributes = True
class UserPublic(BaseModel):
    id: int
    nome: str
    email: str
    ativo: bool

    class Config:
        from_attributes = True