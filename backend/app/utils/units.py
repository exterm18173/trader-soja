SACA_KG = 60.0
TON_KG = 1000.0


def saca_to_ton(sacas: float) -> float:
    return (sacas * SACA_KG) / TON_KG


def ton_to_saca(tons: float) -> float:
    return (tons * TON_KG) / SACA_KG
