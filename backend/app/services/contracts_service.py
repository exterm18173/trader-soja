from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.contract import Contract
from app.utils.units import saca_to_ton


class ContractsService:
    def create(self, db: Session, farm_id: int, user_id: int, payload) -> Contract:
        tipo = payload.tipo_precificacao.strip().upper()
        if tipo not in ("CBOT_PREMIO", "FIXO_BRL"):
            raise HTTPException(status_code=400, detail="tipo_precificacao inválido")

        unit = payload.volume_input_unit.strip().upper()
        if unit not in ("TON", "SACA"):
            raise HTTPException(status_code=400, detail="volume_input_unit inválido")

        # Se quiser, podemos calcular volume_total_ton aqui (MVP: aceita do front)
        vol_ton = float(payload.volume_total_ton)
        if vol_ton <= 0:
            # fallback: tenta calcular se vier SACA
            if unit == "SACA":
                vol_ton = saca_to_ton(float(payload.volume_input_value))
            else:
                vol_ton = float(payload.volume_input_value)

        if tipo == "FIXO_BRL":
            if payload.preco_fixo_brl_value is None or payload.preco_fixo_brl_unit is None:
                raise HTTPException(status_code=400, detail="Para FIXO_BRL informe preco_fixo_brl_value e preco_fixo_brl_unit")

        c = Contract(
            farm_id=farm_id,
            created_by_user_id=user_id,
            produto=payload.produto.strip().upper(),
            tipo_precificacao=tipo,
            volume_input_value=payload.volume_input_value,
            volume_input_unit=unit,
            volume_total_ton=vol_ton,
            data_entrega=payload.data_entrega,
            status="ABERTO",
            preco_fixo_brl_value=payload.preco_fixo_brl_value,
            preco_fixo_brl_unit=payload.preco_fixo_brl_unit,
            observacao=payload.observacao,
        )
        db.add(c)
        db.commit()
        db.refresh(c)
        return c

    def get(self, db: Session, farm_id: int, contract_id: int) -> Contract:
        c = (
            db.query(Contract)
            .filter(Contract.farm_id == farm_id, Contract.id == contract_id)
            .first()
        )
        if not c:
            raise HTTPException(status_code=404, detail="Contrato não encontrado")
        return c

    def list(self, db: Session, farm_id: int) -> list[Contract]:
        return (
            db.query(Contract)
            .filter(Contract.farm_id == farm_id)
            .order_by(Contract.data_entrega.asc(), Contract.id.desc())
            .all()
        )
