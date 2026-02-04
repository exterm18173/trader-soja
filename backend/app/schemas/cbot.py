from datetime import datetime
from pydantic import BaseModel


class CbotQuoteRead(BaseModel):
    id: int
    farm_id: int
    source_id: int
    capturado_em: datetime
    symbol: str
    price_usd_per_bu: float

    class Config:
        from_attributes = True
