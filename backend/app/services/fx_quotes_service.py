# app/services/fx_quotes_service.py
from __future__ import annotations

from fastapi import HTTPException
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.fx_source import FxSource
from app.models.fx_quote import FxQuote
from app.models.fx_quote_check import FxQuoteCheck
from app.models.fx_manual_point import FxManualPoint
from app.models.fx_model_point import FxModelPoint
from app.models.fx_model_run import FxModelRun
from app.services.fx_model_service import FxModelService


class FxQuotesService:
    def __init__(self) -> None:
        self.fx_model = FxModelService()

    # ---------- helpers ----------
    def _get_source_or_404(self, db: Session, source_id: int) -> FxSource:
        src = db.query(FxSource).filter(FxSource.id == source_id, FxSource.ativo.is_(True)).first()
        if not src:
            raise HTTPException(status_code=404, detail="FX source_id inválido ou inativo")
        return src

    def _nearest_manual_point_id(self, db: Session, farm_id: int, source_id: int, ref_mes, ts) -> int | None:
        # pega o ponto manual mais próximo (mesma farm, mesma fonte e mesmo ref_mes)
        before = (
            db.query(FxManualPoint)
            .filter(
                FxManualPoint.farm_id == farm_id,
                FxManualPoint.source_id == source_id,
                FxManualPoint.ref_mes == ref_mes,
                FxManualPoint.captured_at <= ts,
            )
            .order_by(FxManualPoint.captured_at.desc())
            .first()
        )
        after = (
            db.query(FxManualPoint)
            .filter(
                FxManualPoint.farm_id == farm_id,
                FxManualPoint.source_id == source_id,
                FxManualPoint.ref_mes == ref_mes,
                FxManualPoint.captured_at >= ts,
            )
            .order_by(FxManualPoint.captured_at.asc())
            .first()
        )
        if before and after:
            dbefore = abs((ts - before.captured_at).total_seconds())
            dafter = abs((after.captured_at - ts).total_seconds())
            return before.id if dbefore <= dafter else after.id
        return (before or after).id if (before or after) else None

    def _compute_model_refs(self, db: Session, farm_id: int, capturado_em, ref_mes) -> tuple[int, int, float]:
        run: FxModelRun | None = self.fx_model.nearest_run(db, farm_id, capturado_em)
        if not run:
            raise HTTPException(status_code=400, detail="Sem FX model run para comparar (ainda não há runs)")

        point: FxModelPoint | None = (
            db.query(FxModelPoint)
            .filter(FxModelPoint.run_id == run.id, FxModelPoint.ref_mes == ref_mes)
            .first()
        )
        if not point:
            raise HTTPException(status_code=400, detail="Sem FX model point para este mês (ref_mes)")

        fx_model = float(point.dolar_desc)
        return run.id, point.id, fx_model

    # ---------- main ----------
    def create_quote_with_check(
        self,
        db: Session,
        farm_id: int,
        user_id: int,
        source_id: int,
        capturado_em,
        ref_mes,
        brl_per_usd: float,
        observacao: str | None,
    ) -> tuple[FxQuote, FxQuoteCheck]:
        # valida source (global)
        self._get_source_or_404(db, source_id)

        # calcula refs do modelo ANTES (pra não criar quote e falhar depois)
        model_run_id, model_point_id, fx_model = self._compute_model_refs(db, farm_id, capturado_em, ref_mes)

        # manual_point_id é só rastreio (opcional)
        manual_point_id = self._nearest_manual_point_id(db, farm_id, source_id, ref_mes, capturado_em)

        quote = FxQuote(
            farm_id=farm_id,
            source_id=source_id,
            created_by_user_id=user_id,
            capturado_em=capturado_em,
            ref_mes=ref_mes,
            brl_per_usd=brl_per_usd,
            observacao=observacao,
        )
        db.add(quote)

        try:
            db.flush()  # pega quote.id
        except IntegrityError:
            db.rollback()
            raise HTTPException(status_code=409, detail="Cotação já lançada (farm/source/timestamp/ref_mes)")

        fx_manual = float(brl_per_usd)
        delta_abs = fx_manual - fx_model
        delta_pct = (fx_manual / fx_model) - 1.0 if fx_model != 0 else 0.0

        check = FxQuoteCheck(
            quote_id=quote.id,          # ERD: quote_id unique
            farm_id=farm_id,
            manual_point_id=manual_point_id,
            model_run_id=model_run_id,
            model_point_id=model_point_id,
            ref_mes=ref_mes,
            fx_manual=fx_manual,
            fx_model=fx_model,
            delta_abs=delta_abs,
            delta_pct=delta_pct,
        )
        db.add(check)

        db.commit()
        db.refresh(quote)
        db.refresh(check)
        return quote, check

    def list_quotes(self, db: Session, farm_id: int, ref_mes=None, source_id: int | None = None, limit: int = 200) -> list[FxQuote]:
        q = db.query(FxQuote).filter(FxQuote.farm_id == farm_id)
        if ref_mes is not None:
            q = q.filter(FxQuote.ref_mes == ref_mes)
        if source_id is not None:
            q = q.filter(FxQuote.source_id == source_id)
        return q.order_by(FxQuote.capturado_em.desc(), FxQuote.id.desc()).limit(limit).all()

    def get_quote(self, db: Session, farm_id: int, quote_id: int) -> FxQuote:
        quote = db.query(FxQuote).filter(FxQuote.farm_id == farm_id, FxQuote.id == quote_id).first()
        if not quote:
            raise HTTPException(status_code=404, detail="Cotação não encontrada")
        return quote
