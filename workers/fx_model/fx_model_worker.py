import os
import time
from datetime import datetime, date, timezone
from dateutil import tz

import requests
import psycopg2
import psycopg2.extras

# =========================================================
# CONFIG
# =========================================================

DB_URL = os.getenv("DB_URL")
if not DB_URL:
    raise RuntimeError("Defina DB_URL=postgresql://user:pass@host:5432/db")

FARM_ID = int(os.getenv("FARM_ID", "1"))

# Datas-alvo (vencimentos)
TARGET_DATES = [
    date(2026, 4, 30),
    date(2026, 5, 30),
    date(2026, 6, 30),
    date(2026, 7, 30),
    date(2026, 8, 30),
    date(2026, 9, 30),
    date(2026, 10, 30),
    date(2026, 11, 30),
]

INTERVAL_SEC = int(os.getenv("INTERVAL_SEC", "5"))
PERSIST_INTERVAL_SEC = float(os.getenv("PERSIST_INTERVAL_SEC", "5"))

DESCONTO_NEGOCIO_PCT = float(os.getenv("DESCONTO_NEGOCIO_PCT", "0.0"))

TIMEOUT = int(os.getenv("TIMEOUT", "12"))
RETRIES = int(os.getenv("RETRIES", "3"))
SLEEP_BETWEEN = float(os.getenv("SLEEP_BETWEEN", "1.2"))

MARKET_START_HOUR = int(os.getenv("MARKET_START_HOUR", "9"))
MARKET_END_HOUR = int(os.getenv("MARKET_END_HOUR", "18"))

MODEL_VERSION = os.getenv("MODEL_VERSION", "fx_amaggi_like_v1")
SOURCE = os.getenv("FX_SOURCE", "yahoo_chart")

DEBUG = os.getenv("DEBUG", "1").strip().lower() not in ("0", "false", "no", "off")

HEADERS_DEFAULT = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/123.0 Safari/537.36"
    )
}

# =========================================================
# DEBUG HELPERS / NORMALIZAÇÃO
# =========================================================

def dbg(*args):
    if DEBUG:
        print("[DEBUG]", *args)

def norm_rate(x: float) -> float:
    """
    Aceita taxa anual em decimal (0.135) ou em percentual (13.5).
    Retorna sempre decimal.
    """
    x = float(x)
    if x > 1.5:  # 13.5% etc
        return x / 100.0
    return x

def norm_offset_pp(x: float) -> float:
    """
    Offset em 'p.p.' pode vir como:
      - 0.004 (já decimal)
      - 0.4   (querendo dizer 0.4 p.p. => 0.004)
    Retorna sempre decimal.
    """
    x = float(x)
    if x > 0.2:  # 0.4 p.p., 0.8 p.p., etc
        return x / 100.0
    return x

# =========================================================
# TEMPO / MERCADO
# =========================================================

def now_br() -> datetime:
    br_tz = tz.gettz("America/Sao_Paulo")
    return datetime.now(br_tz)

def is_market_open(dt_br: datetime) -> bool:
    if dt_br.weekday() >= 5:
        return False
    hour_float = dt_br.hour + dt_br.minute / 60.0
    return MARKET_START_HOUR <= hour_float <= MARKET_END_HOUR

# =========================================================
# YAHOO CHART (USDBRL=X)
# =========================================================

def _fetch_chart(interval: str):
    url = "https://query1.finance.yahoo.com/v8/finance/chart/USDBRL=X"
    params = {"interval": interval, "range": "2d"}
    r = requests.get(url, headers=HEADERS_DEFAULT, params=params, timeout=TIMEOUT)
    if r.status_code != 200:
        return None

    data = r.json()
    result_list = data.get("chart", {}).get("result")
    if not result_list:
        return None

    result = result_list[0]
    timestamps = result.get("timestamp", [])
    quote_list = result.get("indicators", {}).get("quote", [])
    if not quote_list:
        return None

    closes = quote_list[0].get("close", [])
    if not timestamps or not closes:
        return None

    return list(zip(timestamps, closes))

def get_spot_usdbrl_at(dt_br: datetime) -> float:
    dt_utc = dt_br.astimezone(timezone.utc)
    cutoff_ts = int(dt_utc.timestamp())

    for interval in ["1m", "5m", "15m", "1h", "1d"]:
        tries = 0
        while tries < RETRIES:
            tries += 1
            try:
                candles = _fetch_chart(interval)
                if not candles:
                    time.sleep(SLEEP_BETWEEN)
                    continue

                last_px = None
                for ts, px in candles:
                    if px is None:
                        continue
                    if ts <= cutoff_ts:
                        last_px = float(px)
                    else:
                        break

                if last_px is not None:
                    return last_px

            except Exception:
                time.sleep(SLEEP_BETWEEN)
                continue

    raise RuntimeError("Não foi possível obter spot USDBRL=X no Yahoo chart.")

# =========================================================
# CUPOM / FORWARD
# =========================================================

def calc_coupon_sujo(cdi: float, sofr: float) -> float:
    return (1.0 + cdi) / (1.0 + sofr) - 1.0

def calc_coupon_amaggi_like(cdi: float, sofr: float, offset: float) -> float:
    r_sujo = calc_coupon_sujo(cdi, sofr)
    r_adj = r_sujo - offset
    return max(r_adj, 0.0)

def forward_from_spot(
    spot: float,
    ref_dt: datetime,
    target_dt: date,
    annual_rate: float,
) -> tuple[float, float, float]:
    d0 = ref_dt.date()
    days = (target_dt - d0).days
    if days <= 0:
        raise ValueError("Data-alvo deve ser posterior à data de referência.")
    t_years = days / 365.0
    cupom_t = (1.0 + annual_rate) ** t_years - 1.0
    fwd = spot * (1.0 + cupom_t)
    return t_years, cupom_t, fwd

# =========================================================
# LEITURA CONFIG NO BD (POR FAZENDA)
# =========================================================

def load_latest_interest_rates(cur, farm_id: int):
    cur.execute(
        """
        SELECT cdi_annual, sofr_annual
          FROM interest_rates
         WHERE farm_id = %s
         ORDER BY rate_date DESC, id DESC
         LIMIT 1
        """,
        (farm_id,),
    )
    row = cur.fetchone()
    if not row:
        raise RuntimeError("Tabela interest_rates vazia para esta fazenda.")
    return float(row[0]), float(row[1])

def load_latest_offset(cur, farm_id: int):
    cur.execute(
        """
        SELECT offset_value
          FROM offset_calibration
         WHERE farm_id = %s
         ORDER BY id DESC
         LIMIT 1
        """,
        (farm_id,),
    )
    row = cur.fetchone()
    if not row:
        raise RuntimeError("Tabela offset_calibration vazia para esta fazenda.")
    return float(row[0])

# =========================================================
# PERSISTÊNCIA NOVA ESTRUTURA
# =========================================================

def persist_spot_tick(cur, farm_id: int, ts_utc: datetime, price: float, source: str):
    cur.execute(
        """
        INSERT INTO fx_spot_ticks (farm_id, ts, price, source)
        VALUES (%s, %s, %s, %s)
        ON CONFLICT (farm_id, ts) DO NOTHING
        """,
        (farm_id, ts_utc, float(price), source),
    )

def persist_run_and_points(
    cur,
    farm_id: int,
    as_of_ts_utc: datetime,
    run_data: dict,
    points: list[dict],
) -> int:
    """
    Cria um fx_model_run e retorna run_id.
    Depois insere os fx_model_points (PK: run_id + ref_mes).
    """
    cur.execute(
        """
        INSERT INTO fx_model_runs (
            farm_id, as_of_ts,
            spot_usdbrl, cdi_annual, sofr_annual, offset_value,
            coupon_annual, desconto_pct,
            model_version, source,
            created_at, updated_at
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, now(), now())
        RETURNING id
        """,
        (
            farm_id,
            as_of_ts_utc,
            run_data["spot_usdbrl"],
            run_data["cdi_annual"],
            run_data["sofr_annual"],
            run_data["offset_value"],
            run_data["coupon_annual"],
            run_data["desconto_pct"],
            run_data["model_version"],
            run_data["source"],
        ),
    )
    run_id = int(cur.fetchone()[0])

    values = [
        (
            run_id,
            p["ref_mes"],
            p["t_anos"],
            p["dolar_sint"],
            p["dolar_desc"],
        )
        for p in points
    ]

    psycopg2.extras.execute_values(
        cur,
        """
        INSERT INTO fx_model_points (
            run_id, ref_mes, t_anos, dolar_sint, dolar_desc
        )
        VALUES %s
        ON CONFLICT (run_id, ref_mes) DO NOTHING
        """,
        values,
    )

    return run_id

def to_ref_mes(d: date) -> date:
    # normaliza para YYYY-MM-30
    return date(d.year, d.month, 30)

# =========================================================
# LOOP
# =========================================================

def main():
    conn = psycopg2.connect(DB_URL)
    conn.autocommit = False
    cur = conn.cursor()

    print(f"\nFX worker (farm_id={FARM_ID}) - model={MODEL_VERSION}")
    print(f"DEBUG={'ON' if DEBUG else 'OFF'}")
    print("Tabelas: fx_spot_ticks, fx_model_runs, fx_model_points, interest_rates, offset_calibration\n")

    last_persist_ts: datetime | None = None

    while True:
        try:
            dt_br = now_br()

            if not is_market_open(dt_br):
                time.sleep(INTERVAL_SEC)
                continue

            ts_utc = dt_br.astimezone(timezone.utc)

            # 1) carrega taxas
            raw_cdi, raw_sofr = load_latest_interest_rates(cur, FARM_ID)
            raw_offset = load_latest_offset(cur, FARM_ID)

            # 2) normaliza unidades (se necessário)
            cdi_annual = norm_rate(raw_cdi)
            sofr_annual = norm_rate(raw_sofr)
            offset_value = norm_offset_pp(raw_offset)

            dbg("RAW CDI:", raw_cdi, "| RAW SOFR:", raw_sofr, "| RAW OFFSET:", raw_offset)
            dbg("NORM CDI:", cdi_annual, "| NORM SOFR:", sofr_annual, "| NORM OFFSET:", offset_value)

            # 3) spot
            spot = get_spot_usdbrl_at(dt_br)
            dbg("SPOT:", spot)

            # 4) cupom
            coupon_sujo = calc_coupon_sujo(cdi_annual, sofr_annual)
            coupon_annual = calc_coupon_amaggi_like(cdi_annual, sofr_annual, offset_value)

            dbg("CUPOM SUJO:", coupon_sujo, "| CUPOM AMAGGI:", coupon_annual)

            if coupon_annual <= 0.0:
                raise RuntimeError(
                    "CUPOM ZERADO ❌ (isso faz todos os meses terem o mesmo forward=spot). "
                    f"CDI={cdi_annual} SOFR={sofr_annual} OFFSET={offset_value} "
                    f"(RAW: CDI={raw_cdi} SOFR={raw_sofr} OFFSET={raw_offset})"
                )

            # 5) calcula curva
            points = []
            dbg("---- CURVA FUTURA ----")
            for d in TARGET_DATES:
                t_years, cupom_t, fwd = forward_from_spot(spot, dt_br, d, coupon_annual)

                dolar_sint = float(fwd)
                dolar_desc = dolar_sint * (1.0 - float(DESCONTO_NEGOCIO_PCT))

                dbg(
                    d.strftime("%m/%Y"),
                    "| t_years=", f"{t_years:.4f}",
                    "| cupom_t=", f"{cupom_t*100:.4f}%",
                    "| fwd=", f"{fwd:.6f}",
                )

                points.append(
                    {
                        "ref_mes": to_ref_mes(d),
                        "t_anos": float(t_years),
                        "dolar_sint": float(dolar_sint),
                        "dolar_desc": float(dolar_desc),
                    }
                )
            dbg("----------------------")

            # 6) persistência
            should_persist = False
            if last_persist_ts is None:
                should_persist = True
            else:
                delta_sec = (dt_br - last_persist_ts).total_seconds()
                if delta_sec >= PERSIST_INTERVAL_SEC:
                    should_persist = True

            if should_persist:
                persist_spot_tick(cur, FARM_ID, ts_utc, spot, SOURCE)

                run_data = {
                    "spot_usdbrl": float(spot),
                    "cdi_annual": float(cdi_annual),
                    "sofr_annual": float(sofr_annual),
                    "offset_value": float(offset_value),
                    "coupon_annual": float(coupon_annual),
                    "desconto_pct": float(DESCONTO_NEGOCIO_PCT),
                    "model_version": MODEL_VERSION,
                    "source": SOURCE,
                }

                run_id = persist_run_and_points(cur, FARM_ID, ts_utc, run_data, points)
                conn.commit()
                last_persist_ts = dt_br

                print(
                    f"[{dt_br.strftime('%d/%m %H:%M:%S')}] "
                    f"run_id={run_id} spot={spot:.4f} cupom={coupon_annual*100:.3f}% "
                    f"CDI={cdi_annual*100:.2f}% SOFR={sofr_annual*100:.2f}% OFF={offset_value*100:.3f}p.p."
                )

            time.sleep(INTERVAL_SEC)

        except KeyboardInterrupt:
            print("\nFX worker interrompido.")
            break
        except Exception as e:
            print("\nERRO FX worker:", e)
            conn.rollback()
            time.sleep(1.0)

    cur.close()
    conn.close()

if __name__ == "__main__":
    main()
