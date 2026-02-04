from datetime import datetime
from dateutil import tz


def now_br() -> datetime:
    br_tz = tz.gettz("America/Sao_Paulo")
    return datetime.now(br_tz)
