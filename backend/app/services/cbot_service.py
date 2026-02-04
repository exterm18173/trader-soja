from sqlalchemy.orm import Session
from app.models.cbot_quote import CbotQuote


class CbotService:
    def latest_quote(self, db: Session, farm_id: int, symbol: str = "ZS=F") -> CbotQuote | None:
        return (
            db.query(CbotQuote)
            .filter(CbotQuote.farm_id == farm_id, CbotQuote.symbol == symbol)
            .order_by(CbotQuote.capturado_em.desc(), CbotQuote.id.desc())
            .first()
        )
