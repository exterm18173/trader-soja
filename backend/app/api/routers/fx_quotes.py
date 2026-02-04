from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.deps import get_current_farm_membership, get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.fx_quotes import FxQuoteCreate, FxQuoteWithCheckRead
from app.services.fx_quotes_service import FxQuotesService

router = APIRouter(prefix="/fx/quotes", tags=["FX Quotes"])
service = FxQuotesService()


@router.post("", response_model=FxQuoteWithCheckRead, status_code=status.HTTP_201_CREATED)
def create_fx_quote(
    payload: FxQuoteCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
    membership=Depends(get_current_farm_membership),
):
    quote, check = service.create_quote_with_check(
        db=db,
        farm_id=membership.farm_id,
        user_id=user.id,
        source_name=payload.source_name,
        capturado_em=payload.capturado_em,
        ref_mes=payload.ref_mes,
        brl_per_usd=payload.brl_per_usd,
        observacao=payload.observacao,
    )
    return {"quote": quote, "check": check}
