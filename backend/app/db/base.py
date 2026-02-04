from app.db.base_class import Base

# Importa models para o Alembic enxergar
from app.models.user import User
from app.models.farm import Farm
from app.models.farm_user import FarmUser

from app.models.interest_rate import InterestRate
from app.models.offset_calibration import OffsetCalibration

from app.models.fx_source import FxSource
from app.models.fx_spot_tick import FxSpotTick
from app.models.fx_model_run import FxModelRun
from app.models.fx_model_point import FxModelPoint
from app.models.fx_manual_point import FxManualPoint
from app.models.fx_quote_check import FxQuoteCheck

from app.models.cbot_source import CbotSource
from app.models.cbot_quote import CbotQuote

__all__ = ["Base"]
