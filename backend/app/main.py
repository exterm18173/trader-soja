from fastapi import FastAPI

from app.api.routers.auth import router as auth_router
from app.api.routers.farms import router as farms_router
from app.api.routers.rates import router as rates_router
from app.api.routers.fx_model import router as fx_model_router
from app.api.routers.fx_quotes import router as fx_quotes_router
from app.api.routers.cbot import router as cbot_router
from app.api.routers.contracts import router as contracts_router
from app.api.routers.hedges import router as hedges_router
from app.api.routers.expenses import router as expenses_router
from app.api.routers.alerts import router as alerts_router
from app.api.routers.dashboard import router as dashboard_router

def create_app() -> FastAPI:
    app = FastAPI(title="Trader Soja API", version="0.1.0")

    app.include_router(auth_router)
    app.include_router(farms_router)

    app.include_router(rates_router)
    app.include_router(fx_model_router)
    app.include_router(fx_quotes_router)
    app.include_router(cbot_router)
    app.include_router(contracts_router)
    app.include_router(hedges_router)
    app.include_router(expenses_router)
    app.include_router(alerts_router)
    app.include_router(dashboard_router)


    @app.get("/health")
    def health():
        return {"status": "ok"}

    return app


app = create_app()
