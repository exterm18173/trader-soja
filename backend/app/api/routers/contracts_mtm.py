# app/api/routers/contracts_mtm.py
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.deps import get_farm_membership_from_path
from app.db.session import get_db

from app.schemas.contracts_mtm import ContractsMtmResponse
from app.services.contracts_mtm_service import ContractsMtmService

# ✅ prefix separado para não competir com /contracts/{contract_id}
router = APIRouter(
    prefix="/farms/{farm_id}/contracts-mtm",
    tags=["Contracts MTM"],
)
service = ContractsMtmService()


@router.get("", response_model=ContractsMtmResponse)
def contracts_mtm(
    farm_id: int,
    mode: str = Query(default="both", pattern="^(system|manual|both)$"),
    only_open: bool = Query(default=True),
    ref_mes: str | None = Query(
        default=None,
        description="YYYY-MM-01; se informado, força o ref_mes para FX",
    ),
    default_symbol: str = Query(
        default="ZS=F",
        description="fallback quando contrato não tem hedge CBOT com symbol",
    ),
    limit: int = Query(default=200, ge=1, le=2000),
    db: Session = Depends(get_db),
    membership=Depends(get_farm_membership_from_path),
):
    return service.contracts_mtm(
        db=db,
        farm_id=farm_id,
        mode=mode,
        only_open=only_open,
        ref_mes=ref_mes,
        default_symbol=default_symbol,
        limit=limit,
    )
