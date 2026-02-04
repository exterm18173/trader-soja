from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.contract import Contract
from app.models.hedge_cbot import HedgeCbot
from app.models.hedge_premium import HedgePremium
from app.models.hedge_fx import HedgeFx


class HedgesService:
    def _get_contract(self, db: Session, farm_id: int, contract_id: int) -> Contract:
        c = (
            db.query(Contract)
            .filter(Contract.farm_id == farm_id, Contract.id == contract_id)
            .first()
        )
        if not c:
            raise HTTPException(status_code=404, detail="Contrato não encontrado")
        return c

    def create_cbot(self, db: Session, farm_id: int, contract_id: int, user_id: int, payload) -> HedgeCbot:
        c = self._get_contract(db, farm_id, contract_id)
        if c.tipo_precificacao != "CBOT_PREMIO":
            raise HTTPException(status_code=400, detail="Trava CBOT só faz sentido para contratos CBOT_PREMIO")

        h = HedgeCbot(
            contract_id=c.id,
            executed_by_user_id=user_id,
            executado_em=payload.executado_em,
            volume_input_value=payload.volume_input_value,
            volume_input_unit=payload.volume_input_unit,
            volume_ton=payload.volume_ton,
            cbot_usd_per_bu=payload.cbot_usd_per_bu,
            ref_mes=payload.ref_mes,
            symbol=payload.symbol,
            observacao=payload.observacao,
        )
        db.add(h)
        db.commit()
        db.refresh(h)
        return h

    def create_premium(self, db: Session, farm_id: int, contract_id: int, user_id: int, payload) -> HedgePremium:
        c = self._get_contract(db, farm_id, contract_id)
        if c.tipo_precificacao != "CBOT_PREMIO":
            raise HTTPException(status_code=400, detail="Trava prêmio só faz sentido para contratos CBOT_PREMIO")

        h = HedgePremium(
            contract_id=c.id,
            executed_by_user_id=user_id,
            executado_em=payload.executado_em,
            volume_input_value=payload.volume_input_value,
            volume_input_unit=payload.volume_input_unit,
            volume_ton=payload.volume_ton,
            premium_value=payload.premium_value,
            premium_unit=payload.premium_unit,
            base_local=payload.base_local,
            observacao=payload.observacao,
        )
        db.add(h)
        db.commit()
        db.refresh(h)
        return h

    def create_fx(self, db: Session, farm_id: int, contract_id: int, user_id: int, payload) -> HedgeFx:
        c = self._get_contract(db, farm_id, contract_id)
        h = HedgeFx(
            contract_id=c.id,
            executed_by_user_id=user_id,
            executado_em=payload.executado_em,
            usd_amount=payload.usd_amount,
            brl_per_usd=payload.brl_per_usd,
            ref_mes=payload.ref_mes,
            tipo=payload.tipo,
            observacao=payload.observacao,
        )
        db.add(h)
        db.commit()
        db.refresh(h)
        return h

    def list_cbot(self, db: Session, farm_id: int, contract_id: int) -> list[HedgeCbot]:
        self._get_contract(db, farm_id, contract_id)
        return (
            db.query(HedgeCbot)
            .join(Contract, Contract.id == HedgeCbot.contract_id)
            .filter(Contract.farm_id == farm_id, HedgeCbot.contract_id == contract_id)
            .order_by(HedgeCbot.executado_em.asc(), HedgeCbot.id.asc())
            .all()
        )

    def list_premium(self, db: Session, farm_id: int, contract_id: int) -> list[HedgePremium]:
        self._get_contract(db, farm_id, contract_id)
        return (
            db.query(HedgePremium)
            .join(Contract, Contract.id == HedgePremium.contract_id)
            .filter(Contract.farm_id == farm_id, HedgePremium.contract_id == contract_id)
            .order_by(HedgePremium.executado_em.asc(), HedgePremium.id.asc())
            .all()
        )

    def list_fx(self, db: Session, farm_id: int, contract_id: int) -> list[HedgeFx]:
        self._get_contract(db, farm_id, contract_id)
        return (
            db.query(HedgeFx)
            .join(Contract, Contract.id == HedgeFx.contract_id)
            .filter(Contract.farm_id == farm_id, HedgeFx.contract_id == contract_id)
            .order_by(HedgeFx.executado_em.asc(), HedgeFx.id.asc())
            .all()
        )
