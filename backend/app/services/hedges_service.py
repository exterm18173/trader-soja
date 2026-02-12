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

    # ---------- FX auto-ajuste (para deletes de CBOT/Prêmio) ----------
    def _fx_rows_desc(self, db: Session, contract_id: int) -> list[HedgeFx]:
        """Últimos FX primeiro (remove/ajusta do fim para trás)."""
        return (
            db.query(HedgeFx)
            .filter(HedgeFx.contract_id == contract_id)
            .order_by(HedgeFx.executado_em.desc(), HedgeFx.id.desc())
            .all()
        )

    def _auto_trim_fx_to_usd_formed(self, db: Session, contract_id: int) -> dict:
        """
        Garante: sum_fx_ton <= min(sum_cbot_ton, sum_premium_ton)

        Estratégia:
        - calcula usd_formed
        - se FX exceder, remove FX do fim para o começo
        - se precisar remover parcialmente o último FX, reduz volume_ton e ajusta usd_amount proporcionalmente
        Retorna um resumo (útil para log/debug).
        """
        cbot_ton = self._sum_cbot_ton(db, contract_id)
        prem_ton = self._sum_premium_ton(db, contract_id)
        usd_formed = min(cbot_ton, prem_ton)

        fx_total = self._sum_fx_ton(db, contract_id)
        excess = fx_total - usd_formed

        summary = {
            "usd_formed_ton": float(usd_formed),
            "fx_before_ton": float(fx_total),
            "fx_after_ton": float(fx_total),
            "deleted_fx_ids": [],
            "trimmed_fx": None,  # {"id":..., "from_ton":..., "to_ton":..., "usd_amount_from":..., "usd_amount_to":...}
        }

        if excess <= 1e-9:
            return summary

        rows = self._fx_rows_desc(db, contract_id)

        for fx in rows:
            if excess <= 1e-9:
                break

            fx_ton = float(fx.volume_ton)

            # remove inteiro
            if fx_ton <= excess + 1e-9:
                summary["deleted_fx_ids"].append(int(fx.id))
                excess -= fx_ton
                db.delete(fx)
                continue

            # remove parcial (reduz volume_ton) e ajusta usd_amount proporcionalmente
            new_ton = fx_ton - excess
            if new_ton < 0:
                new_ton = 0.0

            usd_from = float(fx.usd_amount)
            ratio = (new_ton / fx_ton) if fx_ton > 0 else 0.0
            usd_to = usd_from * ratio

            summary["trimmed_fx"] = {
                "id": int(fx.id),
                "from_ton": fx_ton,
                "to_ton": float(new_ton),
                "usd_amount_from": usd_from,
                "usd_amount_to": float(usd_to),
            }

            fx.volume_ton = new_ton
            fx.usd_amount = usd_to
            # brl_per_usd permanece igual
            excess = 0.0

        db.flush()
        summary["fx_after_ton"] = float(self._sum_fx_ton(db, contract_id))
        return summary

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
        #    (para FIXO_BRL, não aplica)
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

    # ---------- Deletes ----------
    def delete_cbot(self, db: Session, farm_id: int, contract_id: int, hedge_id: int, user_id: int) -> None:
        c = self._get_contract(db, farm_id, contract_id)
        self._require_cbot_premio(c, "CBOT")

        h = (
            db.query(HedgeCbot)
            .join(Contract, Contract.id == HedgeCbot.contract_id)
            .filter(
                Contract.farm_id == farm_id,
                HedgeCbot.contract_id == contract_id,
                HedgeCbot.id == hedge_id,
            )
            .first()
        )
        if not h:
            raise HTTPException(status_code=404, detail="Hedge CBOT não encontrado")

        db.delete(h)

        # ✅ Ajusta FX automaticamente (remove/trim excedente)
        self._auto_trim_fx_to_usd_formed(db, contract_id)

        db.commit()

    def delete_premium(self, db: Session, farm_id: int, contract_id: int, hedge_id: int, user_id: int) -> None:
        c = self._get_contract(db, farm_id, contract_id)
        self._require_cbot_premio(c, "prêmio")

        h = (
            db.query(HedgePremium)
            .join(Contract, Contract.id == HedgePremium.contract_id)
            .filter(
                Contract.farm_id == farm_id,
                HedgePremium.contract_id == contract_id,
                HedgePremium.id == hedge_id,
            )
            .first()
        )
        if not h:
            raise HTTPException(status_code=404, detail="Hedge Prêmio não encontrado")

        db.delete(h)

        # ✅ Ajusta FX automaticamente (remove/trim excedente)
        self._auto_trim_fx_to_usd_formed(db, contract_id)

        db.commit()

    def delete_fx(self, db: Session, farm_id: int, contract_id: int, hedge_id: int, user_id: int) -> None:
        self._get_contract(db, farm_id, contract_id)

        h = (
            db.query(HedgeFx)
            .join(Contract, Contract.id == HedgeFx.contract_id)
            .filter(
                Contract.farm_id == farm_id,
                HedgeFx.contract_id == contract_id,
                HedgeFx.id == hedge_id,
            )
            .first()
        )
        if not h:
            raise HTTPException(status_code=404, detail="Hedge FX não encontrado")

        db.delete(h)
        db.commit()
