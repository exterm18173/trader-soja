import os
from datetime import datetime, timedelta, timezone

import psycopg2

DB_URL = os.getenv("DB_URL")
if not DB_URL:
    raise RuntimeError("Defina DB_URL=postgresql://user:pass@host:5432/db")

KEEP_FULL_DAYS = int(os.getenv("KEEP_FULL_DAYS", "7"))
BUCKET_MINUTES = int(os.getenv("BUCKET_MINUTES", "5"))


def compact_fx_spot_ticks(cur, cutoff_utc: datetime):
    # mantém 1 tick por bucket (por fazenda)
    cur.execute(
        """
        DELETE FROM fx_spot_ticks t
        USING (
            SELECT farm_id, ts,
                   ROW_NUMBER() OVER (
                       PARTITION BY farm_id, floor(EXTRACT(EPOCH FROM ts) / (%s * 60))
                       ORDER BY ts
                   ) AS rn
            FROM fx_spot_ticks
            WHERE ts < %s
        ) d
        WHERE t.farm_id = d.farm_id
          AND t.ts = d.ts
          AND d.rn > 1
        """,
        (BUCKET_MINUTES, cutoff_utc),
    )
    return cur.rowcount


def compact_fx_model_runs(cur, cutoff_utc: datetime):
    # Preserva runs usados em checks manuais
    cur.execute(
        """
        WITH preserved AS (
            SELECT DISTINCT model_run_id AS id
              FROM fx_quote_checks
             WHERE model_run_id IS NOT NULL
        ),
        ranked AS (
            SELECT
                r.id,
                r.farm_id,
                r.as_of_ts,
                ROW_NUMBER() OVER (
                    PARTITION BY r.farm_id,
                                 floor(EXTRACT(EPOCH FROM r.as_of_ts) / (%s * 60))
                    ORDER BY r.as_of_ts
                ) AS rn
            FROM fx_model_runs r
            WHERE r.as_of_ts < %s
              AND NOT EXISTS (SELECT 1 FROM preserved p WHERE p.id = r.id)
        )
        DELETE FROM fx_model_runs r
        USING ranked d
        WHERE r.id = d.id
          AND d.rn > 1
        """,
        (BUCKET_MINUTES, cutoff_utc),
    )
    # pontos são cascade (fk ondelete=cascade) via fx_model_points.run_id
    return cur.rowcount


def main():
    conn = psycopg2.connect(DB_URL)
    conn.autocommit = False
    cur = conn.cursor()

    now_utc = datetime.now(timezone.utc)
    cutoff_utc = now_utc - timedelta(days=KEEP_FULL_DAYS)

    print("=======================================")
    print(" Compactação Market Data (FX/CBOT)")
    print("=======================================")
    print(f"DB_URL:         {DB_URL}")
    print(f"KEEP_FULL_DAYS: {KEEP_FULL_DAYS}")
    print(f"BUCKET_MINUTES: {BUCKET_MINUTES}")
    print(f"cutoff UTC:     {cutoff_utc.isoformat()}")
    print("=======================================")

    try:
        deleted_ticks = compact_fx_spot_ticks(cur, cutoff_utc)
        deleted_runs = compact_fx_model_runs(cur, cutoff_utc)

        conn.commit()
        print(f"\nOK. fx_spot_ticks removidos: {deleted_ticks}")
        print(f"OK. fx_model_runs removidos: {deleted_runs} (points em cascade)")

    except Exception as e:
        conn.rollback()
        print("\nERRO compactação:", e)
        raise

    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
