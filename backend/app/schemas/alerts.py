# app/schemas/alerts.py
from __future__ import annotations

from datetime import datetime
from typing import Any

import json
from pydantic import BaseModel, Field, computed_field
from pydantic.config import ConfigDict


class AlertRuleCreate(BaseModel):
    # ✅ bate com model String(120)
    nome: str = Field(min_length=1, max_length=120)
    tipo: str = Field(min_length=1, max_length=40)
    params: dict[str, Any] = Field(default_factory=dict)
    ativo: bool = True


class AlertRuleUpdate(BaseModel):
    # ✅ bate com model String(120)
    nome: str | None = Field(default=None, min_length=1, max_length=120)
    tipo: str | None = Field(default=None, min_length=1, max_length=40)
    params: dict[str, Any] | None = None
    ativo: bool | None = None


class AlertRuleRead(BaseModel):
    id: int
    farm_id: int
    created_by_user_id: int
    ativo: bool
    tipo: str
    nome: str

    # Mantém o que já existe (compatibilidade)
    params_json: str

    model_config = ConfigDict(from_attributes=True)

    # ✅ novo campo “amigável” para o front, sem mexer em model/service
    @computed_field
    @property
    def params(self) -> dict[str, Any]:
        try:
            data = json.loads(self.params_json or "{}")
            return data if isinstance(data, dict) else {}
        except Exception:
            return {}


class AlertEventRead(BaseModel):
    id: int
    farm_id: int
    rule_id: int | None
    triggered_at: datetime
    severity: str
    title: str
    message: str
    read: bool

    model_config = ConfigDict(from_attributes=True)


class AlertEventUpdate(BaseModel):
    read: bool | None = None
