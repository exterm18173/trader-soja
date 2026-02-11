import os
import time
from datetime import datetime, timezone, date

import requests
import psycopg2

# =========================================================
# CONFIG
# =========================================================

DB_URL = os.getenv("DB_URL")
if not DB_URL:
    raise RuntimeError("Defina DB_URL=postgresql://user:pass@host:5432/db")

FARM_ID = int(os.getenv("FARM_ID", "3"))

# 🔥 LISTA FIXA — vencimentos Yahoo
SYMBOLS = [
    "ZSH26.CBT",
    "ZSK26.CBT",
    "ZSN26.CBT",
    "ZSQ26.CBT",
    "ZSU26.CBT",
    "ZSX26.CBT",
]

INTERVAL_SEC = int(os.getenv("INTERVAL_SEC", "15"))
TIMEOUT = int(os.getenv("TIMEOUT", "12"))

SOURCE_NAME = os.getenv("CBOT_SOURCE_NAME", "YAHOO")
DEBUG = os.getenv("DEBUG", "0").strip().lower() not in ("0", "false", "no", "off")

# opcional: usado só se você tiver símbolo sem mês (ex: ZS=F)
# formato: YYYY-MM-01
DEFAULT_REF_MES_FOR_NON_MONTHLY = os.getenv("DEFAULT_REF_MES_FOR_NON_MONTHLY")

HEADERS_DEFAULT = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/123.0 Safari/537.36"
    )
}


def dbg(*args):
    if DEBUG:
        print("[DEBUG]", *args)


# =========================================================
# REF_MES (CBOT) HELPERS
# =========================================================

_CBOT_MONTH = {
    "F": 1,  # Jan
    "G": 2,  # Feb
    "H": 3,  # Mar
    "J": 4,  # Apr
    "K": 5,  # May
    "M": 6,  # Jun
    "N": 7,  # Jul
    "Q": 8,  # Aug
    "U": 9,  # Sep
    "V": 10, # Oct
    "X": 11, # Nov
    "Z": 12, # Dec
}


def _parse_ref_mes_env(s: str | None) -> date | None:
    if not s:
        return None
    try:
        y, m, d = map(int, s.strip().split("-"))
        if d != 1:
            raise ValueError("dia precisa ser 01")
        return date(y, m, d)
    except Exception:
        raise RuntimeError("DEFAULT_REF_MES_FOR_NON_MONTHLY inválido. Use YYYY-MM-01")


_DEFAULT_REF_MES = _parse_ref_mes_env(DEFAULT_REF_MES_FOR_NON_MONTHLY)


def ref_mes_from_symbol(symbol: str) -> date | None:
    """
    Extrai ref_mes de símbolos tipo:
      ZSN26.CBT  -> 2026-07-01
      ZSX25.CBT  -> 2025-11-01

    Se não conseguir (ex: ZS=F), retorna _DEFAULT_REF_MES (se definido) ou None.
    """
    s = (symbol or "").strip().upper()
    root = s.split(".", 1)[0]  # ZSN26

    # padrão esperado: ...[MonthCode][YY]
    if len(root) >= 4:
        month_code = root[-3]  # N
        yy = root[-2:]         # 26
        if month_code in _CBOT_MONTH:
            try:
                year = 2000 + int(yy)
                month = _CBOT_MONTH[month_code]
                return date(year, month, 30)
            except Exception:
                pass

    return _DEFAULT_REF_MES


# =========================================================
# YAHOO HELPERS
# =========================================================

def _yahoo_chart(symbol: str, interval: str = "1m", range_: str = "1d") -> dict:
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}"
    params = {"interval": interval, "range": range_}
    r = requests.get(url, headers=HEADERS_DEFAULT, params=params, timeout=TIMEOUT)
    r.raise_for_status()
    return r.json()


def get_last_price(symbol: str) -> float:
    """
    Pega o último preço válido para o símbolo.
    1) tenta meta->regularMarketPrice
    2) fallback: lê closes do chart e pega o último não-nulo
    """
    data = _yahoo_chart(symbol, interval="1m", range_="1d")

    result_list = data.get("chart", {}).get("result") or []
    if not result_list:
        err = data.get("chart", {}).get("error")
        raise RuntimeError(f"Yahoo sem result para {symbol}. error={err}")

    result = result_list[0]

    meta = result.get("meta") or {}
    rmp = meta.get("regularMarketPrice")
    if rmp is not None:
        try:
            px = float(rmp)
            if px > 0:
                return px
        except Exception:
            pass

    quote_list = (result.get("indicators") or {}).get("quote") or []
    if not quote_list:
        raise RuntimeError(f"Yahoo sem quote para {symbol}")

    closes = quote_list[0].get("close") or []
    last = None
    for px in closes:
        if px is not None:
            last = float(px)

    if last is None:
        raise RuntimeError(f"Yahoo sem close válido para {symbol}")

    return last


# =========================================================
# DB HELPERS
# =========================================================

def ensure_cbot_source(cur, name: str) -> int:
    cur.execute("SELECT id FROM cbot_sources WHERE nome = %s", (name,))
    row = cur.fetchone()
    if row:
        return int(row[0])

    cur.execute(
        """
        INSERT INTO cbot_sources (nome, ativo, created_at, updated_at)
        VALUES (%s, true, now(), now())
        RETURNING id
        """,
        (name,),
    )
    return int(cur.fetchone()[0])


def persist_quote(
    cur,
    farm_id: int,
    source_id: int,
    ts_utc: datetime,
    symbol: str,
    price: float,
):
    rm = ref_mes_from_symbol(symbol)

    # ✅ se o símbolo não tem mês e você não setou fallback, não salva (pra não poluir)
    if rm is None:
        dbg("SKIP (no ref_mes)", symbol)
        return False

    cur.execute(
        """
        INSERT INTO cbot_quotes (
            farm_id,
            source_id,
            capturado_em,
            symbol,
            ref_mes,
            price_usd_per_bu,
            created_at,
            updated_at
        )
        VALUES (%s, %s, %s, %s, %s, %s, now(), now())
        ON CONFLICT (farm_id, capturado_em, symbol, ref_mes) DO NOTHING
        """,
        (farm_id, source_id, ts_utc, symbol, rm, float(price)),
    )
    return True


# =========================================================
# LOOP
# =========================================================

def main():
    if not SYMBOLS:
        raise RuntimeError("SYMBOLS está vazio. Adicione símbolos no topo do arquivo.")

    conn = psycopg2.connect(DB_URL)
    conn.autocommit = False
    cur = conn.cursor()

    source_id = ensure_cbot_source(cur, SOURCE_NAME)
    conn.commit()

    print(f"\nCBOT worker (farm_id={FARM_ID}) source={SOURCE_NAME} interval={INTERVAL_SEC}s")
    print("Símbolos monitorados:")
    for s in SYMBOLS:
        rm = ref_mes_from_symbol(s)
        print(f"  - {s}  (ref_mes={rm})")
    if _DEFAULT_REF_MES is not None:
        print(f"\nDEFAULT_REF_MES_FOR_NON_MONTHLY={_DEFAULT_REF_MES} (usado só se símbolo não tiver mês)")
    print("")

    while True:
        try:
            ts_utc = datetime.now(timezone.utc)

            ok = 0
            fail = 0
            skipped = 0
            parts_log = []

            for sym in SYMBOLS:
                try:
                    px = get_last_price(sym)
                    dbg("PRICE", sym, px)

                    saved = persist_quote(cur, FARM_ID, source_id, ts_utc, sym, px)
                    if not saved:
                        skipped += 1
                        parts_log.append(f"{sym}=SKIP")
                        continue

                    ok += 1
                    parts_log.append(f"{sym}={px:.4f}")

                except Exception as e:
                    fail += 1
                    parts_log.append(f"{sym}=ERR")
                    print(f"[WARN] {sym} erro: {e}")

            conn.commit()

            print(
                f"[{ts_utc.isoformat()}] ok={ok} fail={fail} skip={skipped} -> "
                + ", ".join(parts_log)
            )
            time.sleep(INTERVAL_SEC)

        except KeyboardInterrupt:
            print("\nCBOT worker interrompido.")
            break
        except Exception as e:
            print("\nERRO CBOT worker:", e)
            conn.rollback()
            time.sleep(2.0)

    cur.close()
    conn.close()


if __name__ == "__main__":
    main()
