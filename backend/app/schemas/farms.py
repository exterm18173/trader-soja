from pydantic import BaseModel


class FarmCreate(BaseModel):
    nome: str


class FarmRead(BaseModel):
    id: int
    nome: str
    ativo: bool

    class Config:
        from_attributes = True


class FarmMembershipRead(BaseModel):
    farm: FarmRead
    role: str
