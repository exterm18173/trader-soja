from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.deps import get_current_farm_membership, get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.alerts import AlertRuleCreate, AlertRuleRead, AlertEventRead
from app.services.alerts_service import AlertsService

router = APIRouter(prefix="/alerts", tags=["Alerts"])
service = AlertsService()


@router.post("/rules", response_model=AlertRuleRead, status_code=status.HTTP_201_CREATED)
def create_rule(
    payload: AlertRuleCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
    membership=Depends(get_current_farm_membership),
):
    return service.create_rule(db, membership.farm_id, user.id, payload)


@router.get("/rules", response_model=list[AlertRuleRead])
def list_rules(
    db: Session = Depends(get_db),
    membership=Depends(get_current_farm_membership),
):
    return service.list_rules(db, membership.farm_id)


@router.get("/events", response_model=list[AlertEventRead])
def list_events(
    only_unread: bool = Query(default=False),
    db: Session = Depends(get_db),
    membership=Depends(get_current_farm_membership),
):
    return service.list_events(db, membership.farm_id, only_unread=only_unread)


@router.post("/events/{event_id}/read", response_model=AlertEventRead)
def mark_read(
    event_id: int,
    db: Session = Depends(get_db),
    membership=Depends(get_current_farm_membership),
):
    return service.mark_read(db, membership.farm_id, event_id)
