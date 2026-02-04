from pydantic import BaseModel, EmailStr


class UserRead(BaseModel):
    id: int
    nome: str
    email: EmailStr
    ativo: bool

    class Config:
        from_attributes = True
