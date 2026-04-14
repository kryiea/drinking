from typing import Optional

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import admin, auth, drink_definitions, drink_logs, exports, goals, insights, profile, recommendations
from app.core.config import settings
from app.persistence.session import build_engine, init_database, make_session_factory, seed_database


def create_app(*, database_url: Optional[str] = None) -> FastAPI:
    app = FastAPI(title=settings.app_name, version=settings.app_version)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    engine = build_engine(database_url or settings.database_url, echo=settings.database_echo)
    session_factory = make_session_factory(engine)
    init_database(engine)
    with session_factory() as session:
        seed_database(session)
    app.state.engine = engine
    app.state.session_factory = session_factory

    app.include_router(auth.router, prefix=settings.api_prefix)
    app.include_router(profile.router, prefix=settings.api_prefix)
    app.include_router(goals.router, prefix=settings.api_prefix)
    app.include_router(drink_definitions.router, prefix=settings.api_prefix)
    app.include_router(drink_logs.router, prefix=settings.api_prefix)
    app.include_router(insights.router, prefix=settings.api_prefix)
    app.include_router(recommendations.router, prefix=settings.api_prefix)
    app.include_router(exports.router, prefix=settings.api_prefix)
    app.include_router(admin.router, prefix=settings.api_prefix)

    @app.get("/healthz", tags=["system"])
    def healthz() -> dict[str, str]:
        return {"status": "ok", "service": settings.app_name}

    return app


app = create_app()
