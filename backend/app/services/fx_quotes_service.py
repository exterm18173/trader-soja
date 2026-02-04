from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.fx_source import FxSource
from app.models.fx_quote import FxQuote
from app.models.fx_quote_check import FxQuoteCheck
from app.services.fx_model_service import FxModelService


class FxQuotesService:
    def __init__(self) -> None:
        self.fx_model = FxModelService()

    def get_or_create_source(self, db: Session, farm_id: int, name: str) -> FxSource:
        name = name.strip().upper()
        src = (
            db.query(FxSource)
            .filter(FxSource.farm_id == farm_id, FxSource.nome == name)
            .first()
        )
        if src:
            return src
        src = FxSource(farm_id=farm_id, nome=name, ativo=True)
        db.add(src)
        db.commit()
        db.refresh(src)
        return src

    def create_quote_with_check(
        self,
        db: Session,
        farm_id: int,
        user_id: int,
        source_name: str,
        capturado_em,
        ref_mes,
        brl_per_usd: float,
        observacao: str | None,
    ) -> tuple[FxQuote, FxQuoteCheck]:
        src = self.get_or_create_source(db, farm_id, source_name)

        # evita duplicar
        exists = (
            db.query(FxQuote)
            .filter(
                FxQuote.farm_id == farm_id,
                FxQuote.source_id == src.id,
                FxQuote.capturado_em == capturado_em,
                FxQuote.ref_mes == ref_mes,
            )
            .first()
        )
        if exists:
            raise HTTPException(status_code=409, detail="Cotação já lançada para este timestamp e mês")

        quote = FxQuote(
            farm_id=farm_id,
            source_id=src.id,
            created_by_user_id=user_id,
            capturado_em=capturado_em,
            ref_mes=ref_mes,
            brl_per_usd=brl_per_usd,
            observacao=observacao,
        )
        db.add(quote)
        db.flush()  # pega quote.id

        # acha run mais próximo e ponto do mês
        run = self.fx_model.nearest_run(db, farm_id, capturado_em)
        if not run:
            raise HTTPException(status_code=400, detail="Sem FX model run para comparar (worker ainda não gravou dados)")

        point = self.fx_model.get_point(db, run.id, ref_mes)
        if not point:
            raise HTTPException(status_code=400, detail="Sem ponto do modelo para este mês (ref_mes)")

        script_rate = float(point.dolar_desc)
        diff_abs = float(brl_per_usd) - script_rate
        diff_pct = (float(brl_per_usd) / script_rate) - 1.0 if script_rate != 0 else 0.0

        check = FxQuoteCheck(
            fx_quote_id=quote.id,
            model_run_id=run.id,
            script_brl_per_usd=script_rate,
            diff_abs=diff_abs,
            diff_pct=diff_pct,
            calculo_em=capturado_em,
        )
        db.add(check)

        db.commit()
        db.refresh(quote)
        db.refresh(check)
        return quote, check
