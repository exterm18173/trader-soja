# app/services/alerts_service.py
from datetime import datetime, timezone
import json
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.alert_rule import AlertRule
from app.models.alert_event import AlertEvent


def _norm_tipo(tipo: str) -> str:
    t = (tipo or "").strip().upper()
    if not t:
        raise HTTPException(status_code=400, detail="tipo inválido")
    return t


def _norm_nome(nome: str) -> str:
    n = (nome or "").strip()
    if not n:
        raise HTTPException(status_code=400, detail="nome inválido")
    return n


class AlertsService:
    def create_rule(self, db: Session, farm_id: int, user_id: int, payload) -> AlertRule:
        r = AlertRule(
            farm_id=farm_id,
            created_by_user_id=user_id,
            ativo=payload.ativo,
            tipo=_norm_tipo(payload.tipo),
            params_json=json.dumps(payload.params or {}, ensure_ascii=False),
            nome=_norm_nome(payload.nome),
        )
        db.add(r)
        db.commit()
        db.refresh(r)
        return r

    def list_rules(self, db: Session, farm_id: int, ativo=None, tipo=None, q=None) -> list[AlertRule]:
        query = db.query(AlertRule).filter(AlertRule.farm_id == farm_id)

        if ativo is not None:
            query = query.filter(AlertRule.ativo.is_(ativo))
        if tipo:
            query = query.filter(AlertRule.tipo == _norm_tipo(tipo))
        if q:
            query = query.filter(AlertRule.nome.ilike(f"%{q.strip()}%"))

        return query.order_by(AlertRule.id.desc()).all()

    def get_rule(self, db: Session, farm_id: int, rule_id: int) -> AlertRule:
        r = db.query(AlertRule).filter(AlertRule.farm_id == farm_id, AlertRule.id == rule_id).first()
        if not r:
            raise HTTPException(status_code=404, detail="Regra não encontrada")
        return r

    def update_rule(self, db: Session, farm_id: int, rule_id: int, payload) -> AlertRule:
        r = self.get_rule(db, farm_id, rule_id)

        if payload.nome is not None:
            r.nome = _norm_nome(payload.nome)
        if payload.tipo is not None:
            r.tipo = _norm_tipo(payload.tipo)
        if payload.ativo is not None:
            r.ativo = payload.ativo
        if payload.params is not None:
            r.params_json = json.dumps(payload.params or {}, ensure_ascii=False)

        db.commit()
        db.refresh(r)
        return r

    # Events
    def emit_event(self, db: Session, farm_id: int, title: str, message: str, severity: str = "INFO", rule_id: int | None = None) -> AlertEvent:
        e = AlertEvent(
            farm_id=farm_id,
            rule_id=rule_id,
            triggered_at=datetime.now(timezone.utc),
            severity=(severity or "INFO").strip().upper(),
            title=(title or "").strip(),
            message=(message or "").strip(),
            read=False,
        )
        db.add(e)
        db.commit()
        db.refresh(e)
        return e

    def list_events(self, db: Session, farm_id: int, read=None, severity=None, limit=200) -> list[AlertEvent]:
        q = db.query(AlertEvent).filter(AlertEvent.farm_id == farm_id)
        if read is not None:
            q = q.filter(AlertEvent.read.is_(read))
        if severity:
            q = q.filter(AlertEvent.severity == (severity or "").strip().upper())

        return q.order_by(AlertEvent.triggered_at.desc(), AlertEvent.id.desc()).limit(limit).all()

    def get_event(self, db: Session, farm_id: int, event_id: int) -> AlertEvent:
        e = db.query(AlertEvent).filter(AlertEvent.farm_id == farm_id, AlertEvent.id == event_id).first()
        if not e:
            raise HTTPException(status_code=404, detail="Evento não encontrado")
        return e

    def update_event(self, db: Session, farm_id: int, event_id: int, payload) -> AlertEvent:
        e = self.get_event(db, farm_id, event_id)
        if payload.read is not None:
            e.read = payload.read
        db.commit()
        db.refresh(e)
        return e
