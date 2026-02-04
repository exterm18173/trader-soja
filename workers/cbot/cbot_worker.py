import os
import time
from datetime import datetime, timezone

import requests
import psycopg2

DB_URL = os.getenv("DB_URL")
if not DB_URL:
    raise RuntimeError("Defina DB_URL=postgresql://user:pass@host:5432/db")

FARM_ID = int(os.getenv("FARM_ID", "1"))

# símbolos (pode adicionar mais depois)
SYMBOLS = [s.strip() for s in os.getenv("CBOT_SYMBOLS", "ZS=F").split(",") if s.strip()]

INTERVAL_SEC = int(os.getenv("INTERVAL_SEC", "15"))
TIMEOUT = int(os.getenv("TIMEOUT", "12"))

HEADERS_DEFAULT = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/123.0 Safari/537.36"
    )
}


def get_last_price(symbol: str) -> float:
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}"
    params = {"interval": "1m", "range": "1d"}
    r = requests.get(url, headers=HEADERS_DEFAULT, params=params, timeout=TIMEOUT)
    r.raise_for_status()

    data = r.json()
    result_list = data.get("chart", {}).get("result")
    if not result_list:
        raise RuntimeError(f"Yahoo sem result para {symbol}")

    result = result_list[0]
    ts_list = result.get("timestamp") or []
    quote_list = result.get("indicators", {}).get("quote") or []
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


def ensure_cbot_source(cur, name: str = "YAHOO") -> int:
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


def persist_quote(cur, farm_id: int, source_id: int, ts_utc: datetime, symbol: str, price: float):
    cur.execute(
        """
        INSERT INTO cbot_quotes (
            farm_id, source_id, capturado_em, symbol, price_usd_per_bu, created_at, updated_at
        )
        VALUES (%s, %s, %s, %s, %s, now(), now())
        ON CONFLICT (farm_id, capturado_em, symbol) DO NOTHING
        """,
        (farm_id, source_id, ts_utc, symbol, float(price)),
    )


def main():
    conn = psycopg2.connect(DB_URL)
    conn.autocommit = False
    cur = conn.cursor()

    source_id = ensure_cbot_source(cur, "YAHOO")
    conn.commit()

    print(f"\nCBOT worker (farm_id={FARM_ID}) symbols={SYMBOLS}")

    while True:
        try:
            ts_utc = datetime.now(timezone.utc)

            for sym in SYMBOLS:
                px = get_last_price(sym)
                persist_quote(cur, FARM_ID, source_id, ts_utc, sym, px)

            conn.commit()
            print(f"[{ts_utc.isoformat()}] CBOT ok -> {', '.join(SYMBOLS)}")

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
