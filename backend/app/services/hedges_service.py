# app/services/hedges_service.py
from __future__ import annotations

from fastapi import HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.models.contract import Contract
from app.models.hedge_cbot import HedgeCbot
from app.models.hedge_premium import HedgePremium
from app.models.hedge_fx import HedgeFx


ALLOWED_UNIT = {"TON", "SACA"}
ALLOWED_PREMIUM_UNIT = {"USD_BU", "USD_TON"}
ALLOWED_FX_TIPO = {"CURVA_SCRIPT", "MANUAL"}  # ajuste se quiser


class HedgesService:
    # ---------- Normalizações ----------
    def _norm_unit(self, v: str) -> str:
        u = (v or "").strip().upper()
        if u not in ALLOWED_UNIT:
            raise HTTPException(status_code=400, detail=f"volume_input_unit inválido. Use: {sorted(ALLOWED_UNIT)}")
        return u

    def _norm_premium_unit(self, v: str) -> str:
        p = (v or "").strip().upper()
        if p not in ALLOWED_PREMIUM_UNIT:
            raise HTTPException(status_code=400, detail=f"premium_unit inválido. Use: {sorted(ALLOWED_PREMIUM_UNIT)}")
        return p

    def _norm_fx_tipo(self, v: str | None) -> str:
        t = (v or "CURVA_SCRIPT").strip().upper()
        if t not in ALLOWED_FX_TIPO:
            raise HTTPException(status_code=400, detail=f"tipo inválido. Use: {sorted(ALLOWED_FX_TIPO)}")
        return t

    # ---------- Somas ----------
    def _sum_cbot_ton(self, db: Session, contract_id: int) -> float:
        total = (
            db.query(func.coalesce(func.sum(HedgeCbot.volume_ton), 0))
            .filter(HedgeCbot.contract_id == contract_id)
            .scalar()
        )
        return float(total or 0)

    def _sum_premium_ton(self, db: Session, contract_id: int) -> float:
        total = (
            db.query(func.coalesce(func.sum(HedgePremium.volume_ton), 0))
            .filter(HedgePremium.contract_id == contract_id)
            .scalar()
        )
        return float(total or 0)

    def _sum_fx_ton(self, db: Session, contract_id: int) -> float:
        total = (
            db.query(func.coalesce(func.sum(HedgeFx.volume_ton), 0))
            .filter(HedgeFx.contract_id == contract_id)
            .scalar()
        )
        return float(total or 0)

    # ---------- Helpers ----------
    def _get_contract(self, db: Session, farm_id: int, contract_id: int) -> Contract:
        c = (
            db.query(Contract)
            .filter(Contract.farm_id == farm_id, Contract.id == contract_id)
            .first()
        )
        if not c:
            raise HTTPException(status_code=404, detail="Contrato não encontrado")
        return c

    def _require_cbot_premio(self, c: Contract, kind: str) -> None:
        if (c.tipo_precificacao or "").strip().upper() != "CBOT_PREMIO":
            raise HTTPException(status_code=400, detail=f"Trava {kind} só faz sentido para contratos CBOT_PREMIO")

    def _require_remaining(self, kind: str, contract_ton: float, locked_ton: float, add_ton: float) -> None:
        if add_ton <= 0:
            raise HTTPException(status_code=400, detail="volume_ton inválido")
        remaining = contract_ton - locked_ton
        if add_ton > remaining + 1e-9:
            raise HTTPException(
                status_code=400,
                detail=f"volume_ton excede o disponível para trava {kind}. Disponível: {remaining:.6f} ton",
            )

    def _require_fx_usd_formed(self, db: Session, contract_id: int, add_fx_ton: float) -> None:
        """
        Regra do fluxo:
        FX só pode travar até o volume que já tem USD formado (CBOT + Premium),
        no agregado: min(sum_cbot_ton, sum_premium_ton).
        """
        cbot_ton = self._sum_cbot_ton(db, contract_id)
        prem_ton = self._sum_premium_ton(db, contract_id)
        usd_formed = min(cbot_ton, prem_ton)

        fx_locked = self._sum_fx_ton(db, contract_id)
        fx_remaining_usd = usd_formed - fx_locked

        if add_fx_ton > fx_remaining_usd + 1e-9:
            raise HTTPException(
                status_code=400,
                detail=(
                    "Trava de dólar excede o volume com USD formado (CBOT+Prêmio). "
                    f"Disponível para FX: {fx_remaining_usd:.6f} ton"
                ),
            )

    # ---------- Creates ----------
    def create_cbot(self, db: Session, farm_id: int, contract_id: int, user_id: int, payload) -> HedgeCbot:
        c = self._get_contract(db, farm_id, contract_id)
        self._require_cbot_premio(c, "CBOT")

        add_ton = float(payload.volume_ton)
        locked = self._sum_cbot_ton(db, c.id)
        self._require_remaining("CBOT", float(c.volume_total_ton), locked, add_ton)

        h = HedgeCbot(
            contract_id=c.id,
            executed_by_user_id=user_id,
            executado_em=payload.executado_em,
            volume_input_value=payload.volume_input_value,
            volume_input_unit=self._norm_unit(payload.volume_input_unit),
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
        self._require_cbot_premio(c, "prêmio")

        add_ton = float(payload.volume_ton)
        locked = self._sum_premium_ton(db, c.id)
        self._require_remaining("prêmio", float(c.volume_total_ton), locked, add_ton)

        h = HedgePremium(
            contract_id=c.id,
            executed_by_user_id=user_id,
            executado_em=payload.executado_em,
            volume_input_value=payload.volume_input_value,
            volume_input_unit=self._norm_unit(payload.volume_input_unit),
            volume_ton=payload.volume_ton,
            premium_value=payload.premium_value,
            premium_unit=self._norm_premium_unit(payload.premium_unit),
            base_local=payload.base_local,
            observacao=payload.observacao,
        )
        db.add(h)
        db.commit()
        db.refresh(h)
        return h

    def create_fx(self, db: Session, farm_id: int, contract_id: int, user_id: int, payload) -> HedgeFx:
        c = self._get_contract(db, farm_id, contract_id)

        add_ton = float(payload.volume_ton)

        # 1) não pode passar do volume do contrato
        locked_fx = self._sum_fx_ton(db, c.id)
        self._require_remaining("dólar", float(c.volume_total_ton), locked_fx, add_ton)

        # 2) regra do fluxo: FX só trava volume que já tem USD formado (CBOT+Premium)
        #    (se não for CBOT_PREMIO, você pode escolher: permitir ou bloquear.
        #     aqui, para não atrapalhar FIXO_BRL, só aplica a regra quando CBOT_PREMIO)
        if (c.tipo_precificacao or "").strip().upper() == "CBOT_PREMIO":
            self._require_fx_usd_formed(db, c.id, add_ton)

        h = HedgeFx(
            contract_id=c.id,
            executed_by_user_id=user_id,
            executado_em=payload.executado_em,
            volume_ton=payload.volume_ton,
            usd_amount=payload.usd_amount,
            brl_per_usd=payload.brl_per_usd,
            ref_mes=payload.ref_mes,
            tipo=self._norm_fx_tipo(payload.tipo),
            observacao=payload.observacao,
        )
        db.add(h)
        db.commit()
        db.refresh(h)
        return h

    # ---------- Lists ----------
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
