# app/services/cbot_service.py
from __future__ import annotations

from datetime import datetime
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.cbot_quote import CbotQuote
from app.models.cbot_source import CbotSource


class CbotService:
    def _ensure_source_ok(self, db: Session, source_id: int) -> None:
        src = db.query(CbotSource).filter(CbotSource.id == source_id, CbotSource.ativo.is_(True)).first()
        if not src:
            raise HTTPException(status_code=404, detail="CBOT source_id inválido ou inativo")

    def latest_quote(self, db: Session, farm_id: int, symbol: str = "ZS=F", source_id: int | None = None) -> CbotQuote | None:
        q = db.query(CbotQuote).filter(CbotQuote.farm_id == farm_id, CbotQuote.symbol == symbol)
        if source_id is not None:
            self._ensure_source_ok(db, source_id)
            q = q.filter(CbotQuote.source_id == source_id)

        return q.order_by(CbotQuote.capturado_em.desc(), CbotQuote.id.desc()).first()

    def list_quotes(
        self,
        db: Session,
        farm_id: int,
        symbol: str | None = None,
        source_id: int | None = None,
        from_ts: datetime | None = None,
        to_ts: datetime | None = None,
        limit: int = 500,
    ) -> list[CbotQuote]:
        q = db.query(CbotQuote).filter(CbotQuote.farm_id == farm_id)

        if symbol:
            q = q.filter(CbotQuote.symbol == symbol.strip())
        if source_id is not None:
            self._ensure_source_ok(db, source_id)
            q = q.filter(CbotQuote.source_id == source_id)
        if from_ts:
            q = q.filter(CbotQuote.capturado_em >= from_ts)
        if to_ts:
            q = q.filter(CbotQuote.capturado_em <= to_ts)

        return q.order_by(CbotQuote.capturado_em.desc(), CbotQuote.id.desc()).limit(limit).all()

    def get_quote(self, db: Session, farm_id: int, quote_id: int) -> CbotQuote:
        row = db.query(CbotQuote).filter(CbotQuote.farm_id == farm_id, CbotQuote.id == quote_id).first()
        if not row:
            raise HTTPException(status_code=404, detail="Cotação CBOT não encontrada")
        return row
