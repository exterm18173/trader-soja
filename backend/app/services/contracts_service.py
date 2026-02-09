# app/services/contracts_service.py
from __future__ import annotations

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.contract import Contract
from app.utils.units import saca_to_ton

ALLOWED_TIPO = {"CBOT_PREMIO", "FIXO_BRL"}
ALLOWED_UNIT = {"TON", "SACA"}
ALLOWED_STATUS = {"ABERTO", "PARCIAL", "FECHADO", "CANCELADO"}  # ajuste como quiser


class ContractsService:
    def _norm_tipo(self, v: str) -> str:
        t = (v or "").strip().upper()
        if t not in ALLOWED_TIPO:
            raise HTTPException(
                status_code=400,
                detail=f"tipo_precificacao inválido. Use: {sorted(ALLOWED_TIPO)}",
            )
        return t

    def _norm_unit(self, v: str) -> str:
        u = (v or "").strip().upper()
        if u not in ALLOWED_UNIT:
            raise HTTPException(
                status_code=400,
                detail=f"volume_input_unit inválido. Use: {sorted(ALLOWED_UNIT)}",
            )
        return u

    def _norm_status(self, v: str) -> str:
        s = (v or "").strip().upper()
        if s not in ALLOWED_STATUS:
            raise HTTPException(
                status_code=400,
                detail=f"status inválido. Use: {sorted(ALLOWED_STATUS)}",
            )
        return s

    def _validate_frete(self, frete_total, frete_per_ton) -> None:
        # não permite ambos
        if frete_total is not None and frete_per_ton is not None:
            raise HTTPException(
                status_code=400,
                detail="Informe apenas um: frete_brl_total OU frete_brl_per_ton",
            )
        # reforço: não permite negativo (mesmo que schema já valide)
        if frete_total is not None and float(frete_total) < 0:
            raise HTTPException(status_code=400, detail="frete_brl_total não pode ser negativo")
        if frete_per_ton is not None and float(frete_per_ton) < 0:
            raise HTTPException(status_code=400, detail="frete_brl_per_ton não pode ser negativo")

    def create(self, db: Session, farm_id: int, user_id: int, payload) -> Contract:
        tipo = self._norm_tipo(payload.tipo_precificacao)
        unit = self._norm_unit(payload.volume_input_unit)

        vol_ton = float(payload.volume_total_ton or 0)
        if vol_ton <= 0:
            # fallback: tenta calcular
            if unit == "SACA":
                vol_ton = saca_to_ton(float(payload.volume_input_value))
            else:
                vol_ton = float(payload.volume_input_value)

        if vol_ton <= 0:
            raise HTTPException(status_code=400, detail="volume_total_ton inválido")

        if tipo == "FIXO_BRL":
            if payload.preco_fixo_brl_value is None or payload.preco_fixo_brl_unit is None:
                raise HTTPException(
                    status_code=400,
                    detail="Para FIXO_BRL informe preco_fixo_brl_value e preco_fixo_brl_unit",
                )

        # ✅ frete (novo)
        frete_total = getattr(payload, "frete_brl_total", None)
        frete_per_ton = getattr(payload, "frete_brl_per_ton", None)
        frete_obs = getattr(payload, "frete_obs", None)
        self._validate_frete(frete_total, frete_per_ton)

        c = Contract(
            farm_id=farm_id,
            created_by_user_id=user_id,
            produto=(payload.produto or "SOJA").strip().upper(),
            tipo_precificacao=tipo,
            volume_input_value=payload.volume_input_value,
            volume_input_unit=unit,
            volume_total_ton=vol_ton,
            data_entrega=payload.data_entrega,
            status="ABERTO",
            preco_fixo_brl_value=payload.preco_fixo_brl_value,
            preco_fixo_brl_unit=payload.preco_fixo_brl_unit,
            # ✅ frete (novo)
            frete_brl_total=frete_total,
            frete_brl_per_ton=frete_per_ton,
            frete_obs=frete_obs,
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

    def list(
        self,
        db: Session,
        farm_id: int,
        status: str | None = None,
        produto: str | None = None,
        tipo_precificacao: str | None = None,
        entrega_from=None,
        entrega_to=None,
        q: str | None = None,
    ) -> list[Contract]:
        query = db.query(Contract).filter(Contract.farm_id == farm_id)

        if status:
            query = query.filter(Contract.status == self._norm_status(status))
        if produto:
            query = query.filter(Contract.produto == produto.strip().upper())
        if tipo_precificacao:
            query = query.filter(Contract.tipo_precificacao == self._norm_tipo(tipo_precificacao))
        if entrega_from:
            query = query.filter(Contract.data_entrega >= entrega_from)
        if entrega_to:
            query = query.filter(Contract.data_entrega <= entrega_to)
        if q:
            query = query.filter(Contract.observacao.ilike(f"%{q.strip()}%"))

        return query.order_by(Contract.data_entrega.asc(), Contract.id.desc()).all()

    def update(self, db: Session, farm_id: int, contract_id: int, payload) -> Contract:
        c = self.get(db, farm_id, contract_id)

        if payload.status is not None:
            c.status = self._norm_status(payload.status)

        if payload.data_entrega is not None:
            c.data_entrega = payload.data_entrega

        # volume
        if payload.volume_input_unit is not None:
            c.volume_input_unit = self._norm_unit(payload.volume_input_unit)
        if payload.volume_input_value is not None:
            c.volume_input_value = payload.volume_input_value
        if payload.volume_total_ton is not None:
            c.volume_total_ton = float(payload.volume_total_ton)

        # preço fixo
        if payload.preco_fixo_brl_value is not None:
            c.preco_fixo_brl_value = payload.preco_fixo_brl_value
        if payload.preco_fixo_brl_unit is not None:
            c.preco_fixo_brl_unit = payload.preco_fixo_brl_unit

        # ✅ frete (novo)
        # Se setar um, zera o outro (evita ficar com os dois preenchidos)
        if getattr(payload, "frete_brl_total", None) is not None and getattr(payload, "frete_brl_per_ton", None) is not None:
            raise HTTPException(
                status_code=400,
                detail="Informe apenas um: frete_brl_total OU frete_brl_per_ton",
            )

        if getattr(payload, "frete_brl_total", None) is not None:
            v = float(payload.frete_brl_total)
            if v < 0:
                raise HTTPException(status_code=400, detail="frete_brl_total não pode ser negativo")
            c.frete_brl_total = v
            c.frete_brl_per_ton = None  # zera o outro

        if getattr(payload, "frete_brl_per_ton", None) is not None:
            v = float(payload.frete_brl_per_ton)
            if v < 0:
                raise HTTPException(status_code=400, detail="frete_brl_per_ton não pode ser negativo")
            c.frete_brl_per_ton = v
            c.frete_brl_total = None  # zera o outro

        if getattr(payload, "frete_obs", None) is not None:
            c.frete_obs = payload.frete_obs

        if payload.observacao is not None:
            c.observacao = payload.observacao

        # regra: se FIXO_BRL precisa preço
        if (c.tipo_precificacao or "").upper() == "FIXO_BRL":
            if c.preco_fixo_brl_value is None or c.preco_fixo_brl_unit is None:
                raise HTTPException(
                    status_code=400,
                    detail="Contrato FIXO_BRL exige preco_fixo_brl_value e preco_fixo_brl_unit",
                )

        db.commit()
        db.refresh(c)
        return c
