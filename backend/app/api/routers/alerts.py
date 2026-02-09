# app/api/routes/alerts.py
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.deps import get_current_user, get_farm_membership_from_path
from app.db.session import get_db
from app.models.user import User
from app.schemas.alerts import (
    AlertRuleCreate,
    AlertRuleUpdate,
    AlertRuleRead,
    AlertEventRead,
    AlertEventUpdate,
)
from app.services.alerts_service import AlertsService

router = APIRouter(prefix="/farms/{farm_id}/alerts", tags=["Alerts"])
service = AlertsService()


# ---------- RULES ----------
@router.post("/rules", response_model=AlertRuleRead, status_code=status.HTTP_201_CREATED)
def create_rule(
    farm_id: int,
    payload: AlertRuleCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
    membership=Depends(get_farm_membership_from_path),
):
    return service.create_rule(db, farm_id, user.id, payload)


@router.get("/rules", response_model=list[AlertRuleRead])
def list_rules(
    farm_id: int,
    ativo: bool | None = Query(default=None),
    tipo: str | None = Query(default=None),
    q: str | None = Query(default=None),
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.list_rules(db, farm_id, ativo=ativo, tipo=tipo, q=q)


@router.get("/rules/{rule_id}", response_model=AlertRuleRead)
def get_rule(
    farm_id: int,
    rule_id: int,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.get_rule(db, farm_id, rule_id)


@router.patch("/rules/{rule_id}", response_model=AlertRuleRead)
def update_rule(
    farm_id: int,
    rule_id: int,
    payload: AlertRuleUpdate,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    # soft delete = payload.ativo = false
    return service.update_rule(db, farm_id, rule_id, payload)


# ---------- EVENTS ----------
@router.get("/events", response_model=list[AlertEventRead])
def list_events(
    farm_id: int,
    read: bool | None = Query(default=None),
    severity: str | None = Query(default=None),
    limit: int = Query(default=200, ge=1, le=1000),
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.list_events(db, farm_id, read=read, severity=severity, limit=limit)


@router.get("/events/{event_id}", response_model=AlertEventRead)
def get_event(
    farm_id: int,
    event_id: int,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.get_event(db, farm_id, event_id)


@router.patch("/events/{event_id}", response_model=AlertEventRead)
def update_event(
    farm_id: int,
    event_id: int,
    payload: AlertEventUpdate,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    # marcar lido = {"read": true}
    return service.update_event(db, farm_id, event_id, payload)
