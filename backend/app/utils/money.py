def safe_float(x) -> float:
    try:
        return float(x)
    except Exception:
        return 0.0
