from collections.abc import Generator

from fastapi import Header, Request

from app.domain.repository import AppRepository
from app.persistence.repository import SQLAlchemyRepository


def get_repository(request: Request) -> Generator[AppRepository, None, None]:
    session = request.app.state.session_factory()
    try:
        yield SQLAlchemyRepository(session)
    finally:
        session.close()


def get_user_id(x_user_id: str = Header(default="demo-user")) -> str:
    return x_user_id
