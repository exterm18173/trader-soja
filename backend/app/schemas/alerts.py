from datetime import datetime
from pydantic import BaseModel


class AlertRuleCreate(BaseModel):
    nome: str
    tipo: str
    params_json: str = "{}"
    ativo: bool = True


class AlertRuleRead(BaseModel):
    id: int
    farm_id: int
    created_by_user_id: int
    ativo: bool
    tipo: str
    params_json: str
    nome: str

    class Config:
        from_attributes = True


class AlertEventRead(BaseModel):
    id: int
    farm_id: int
    rule_id: int | None
    triggered_at: datetime
    severity: str
    title: str
    message: str
    read: bool

    class Config:
        from_attributes = True
