# app/api/routers/fx_quotes.py
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from datetime import date

from app.core.deps import get_current_user, get_farm_membership_from_path
from app.db.session import get_db
from app.models.user import User
from app.schemas.fx_quotes import FxQuoteCreate, FxQuoteWithCheckRead
from app.services.fx_quotes_service import FxQuotesService

router = APIRouter(prefix="/farms/{farm_id}/fx/quotes", tags=["FX Quotes"])
service = FxQuotesService()


@router.post("", response_model=FxQuoteWithCheckRead, status_code=status.HTTP_201_CREATED)
def create_fx_quote(
    farm_id: int,
    payload: FxQuoteCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
    membership=Depends(get_farm_membership_from_path),
):
    quote, check = service.create_quote_with_check(
        db=db,
        farm_id=farm_id,
        user_id=user.id,
        source_id=payload.source_id,
        capturado_em=payload.capturado_em,
        ref_mes=payload.ref_mes,
        brl_per_usd=payload.brl_per_usd,
        observacao=payload.observacao,
    )
    return {"quote": quote, "check": check}


@router.get("", response_model=list[FxQuoteWithCheckRead])
def list_fx_quotes(
    farm_id: int,
    ref_mes: date | None = Query(default=None),
    source_id: int | None = Query(default=None),
    limit: int = Query(default=200, ge=1, le=1000),
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    quotes = service.list_quotes(db, farm_id, ref_mes=ref_mes, source_id=source_id, limit=limit)
    # usa relationship quote.check
    return [{"quote": q, "check": q.check} for q in quotes]


@router.get("/{quote_id}", response_model=FxQuoteWithCheckRead)
def get_fx_quote(
    farm_id: int,
    quote_id: int,
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    q = service.get_quote(db, farm_id, quote_id)
    if not q.check:
        # pela regra do teu fluxo, deveria sempre existir; mas isso evita erro
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail="Cotação sem check associado (inconsistência)")
    return {"quote": q, "check": q.check}
