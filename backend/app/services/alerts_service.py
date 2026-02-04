from datetime import datetime, timezone
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.alert_rule import AlertRule
from app.models.alert_event import AlertEvent


class AlertsService:
    def create_rule(self, db: Session, farm_id: int, user_id: int, payload) -> AlertRule:
        tipo = payload.tipo.strip().upper()
        if not tipo:
            raise HTTPException(status_code=400, detail="tipo inválido")

        r = AlertRule(
            farm_id=farm_id,
            created_by_user_id=user_id,
            ativo=payload.ativo,
            tipo=tipo,
            params_json=payload.params_json or "{}",
            nome=payload.nome.strip(),
        )
        db.add(r)
        db.commit()
        db.refresh(r)
        return r

    def list_rules(self, db: Session, farm_id: int) -> list[AlertRule]:
        return (
            db.query(AlertRule)
            .filter(AlertRule.farm_id == farm_id)
            .order_by(AlertRule.id.desc())
            .all()
        )

    def emit_event(self, db: Session, farm_id: int, title: str, message: str, severity: str = "INFO", rule_id: int | None = None) -> AlertEvent:
        e = AlertEvent(
            farm_id=farm_id,
            rule_id=rule_id,
            triggered_at=datetime.now(timezone.utc),
            severity=severity,
            title=title,
            message=message,
            read=False,
        )
        db.add(e)
        db.commit()
        db.refresh(e)
        return e

    def list_events(self, db: Session, farm_id: int, only_unread: bool = False) -> list[AlertEvent]:
        q = db.query(AlertEvent).filter(AlertEvent.farm_id == farm_id)
        if only_unread:
            q = q.filter(AlertEvent.read.is_(False))
        return q.order_by(AlertEvent.triggered_at.desc(), AlertEvent.id.desc()).all()

    def mark_read(self, db: Session, farm_id: int, event_id: int) -> AlertEvent:
        e = (
            db.query(AlertEvent)
            .filter(AlertEvent.farm_id == farm_id, AlertEvent.id == event_id)
            .first()
        )
        if not e:
            raise HTTPException(status_code=404, detail="Evento não encontrado")
        e.read = True
        db.commit()
        db.refresh(e)
        return e
