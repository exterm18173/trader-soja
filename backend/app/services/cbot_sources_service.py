# app/services/cbot_sources_service.py
from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.cbot_source import CbotSource


class CbotSourcesService:
    def create(self, db: Session, nome: str, ativo: bool = True) -> CbotSource:
        nome = nome.strip().upper()
        if not nome:
            raise HTTPException(status_code=400, detail="Nome inválido")

        row = CbotSource(nome=nome, ativo=ativo)
        db.add(row)
        try:
            db.commit()
        except IntegrityError:
            db.rollback()
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Já existe uma fonte CBOT com esse nome")
        db.refresh(row)
        return row

    def list(self, db: Session, only_active: bool = True) -> list[CbotSource]:
        q = db.query(CbotSource)
        if only_active:
            q = q.filter(CbotSource.ativo.is_(True))
        return q.order_by(CbotSource.nome.asc(), CbotSource.id.asc()).all()
