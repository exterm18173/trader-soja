# app/api/routers/contracts_mtm.py
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.deps import get_farm_membership_from_path
from app.db.session import get_db
from app.schemas.contracts_mtm import ContractsMtmResponse
from app.services.contracts_mtm_service import ContractsMtmService

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
        description="YYYY-MM-30; se informado, força o ref_mes para FX (CBOT usa ref_mes do hedge/contrato).",
    ),
    default_symbol: str = Query(
        default="AUTO",
        description="CBOT: 'AUTO' usa o vencimento do mês do contrato. Ou informe símbolo fixo (ex: ZS=F).",
    ),
    limit: int = Query(default=200, ge=1, le=2000),

    # lock filters
    lock_types: str | None = Query(default=None, description="CSV: cbot,premium,fx"),
    lock_states: str | None = Query(default=None, description="CSV: locked,open"),

    # NOVO: sem travas (FIXO_BRL)
    no_locks: bool = Query(
        default=False,
        description="Se true, retorna apenas contratos sem travas (ex: FIXO_BRL). Ignora lock_types/lock_states.",
    ),

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
        lock_types=lock_types,
        lock_states=lock_states,
        no_locks=no_locks,
    )
