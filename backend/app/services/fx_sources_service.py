# app/services/fx_sources_service.py
from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.fx_source import FxSource


class FxSourcesService:
    def create(self, db: Session, nome: str, ativo: bool = True) -> FxSource:
        nome = nome.strip().upper()
        if not nome:
            raise HTTPException(status_code=400, detail="Nome inválido")

        row = FxSource(nome=nome, ativo=ativo)
        db.add(row)
        try:
            db.commit()
        except IntegrityError:
            db.rollback()
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Já existe uma fonte FX com esse nome")
        db.refresh(row)
        return row

    def list(self, db: Session, only_active: bool = True) -> list[FxSource]:
        q = db.query(FxSource)
        if only_active:
            q = q.filter(FxSource.ativo.is_(True))
        return q.order_by(FxSource.nome.asc(), FxSource.id.asc()).all()

    def get(self, db: Session, source_id: int) -> FxSource:
        row = db.query(FxSource).filter(FxSource.id == source_id).first()
        if not row:
            raise HTTPException(status_code=404, detail="Fonte FX não encontrada")
        return row

    def update(self, db: Session, source_id: int, nome: str | None, ativo: bool | None) -> FxSource:
        row = self.get(db, source_id)
        if nome is not None:
            row.nome = nome.strip().upper()
        if ativo is not None:
            row.ativo = bool(ativo)

        try:
            db.commit()
        except IntegrityError:
            db.rollback()
            raise HTTPException(status_code=409, detail="Já existe uma fonte FX com esse nome")
        db.refresh(row)
        return row
