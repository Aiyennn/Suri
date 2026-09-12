import asyncio
from unittest.mock import Mock

from fastapi import FastAPI
from starlette.requests import Request

from app.dependencies import get_db
from app.main import create_app


def test_create_app_preserves_routes_and_metadata():
    app = create_app()

    paths = {route.path for route in app.routes}
    assert app.title == "Suri"
    assert {"/", "/auth/login", "/wound/analyze", "/chatbot/message"} <= paths


def test_lifespan_initializes_and_releases_resources(monkeypatch):
    engine = Mock()
    connection = engine.connect.return_value.__enter__.return_value
    redis_client = Mock()
    session_factory = Mock()

    monkeypatch.setattr("app.main.create_database_engine", lambda _: engine)
    monkeypatch.setattr("app.main.create_session_factory", lambda _: session_factory)
    monkeypatch.setattr("app.main.create_redis_client", lambda _: redis_client)

    app = create_app()

    async def exercise_lifespan():
        async with app.router.lifespan_context(app):
            assert app.state.database_engine is engine
            assert app.state.session_factory is session_factory
            assert app.state.redis_client is redis_client

    asyncio.run(exercise_lifespan())

    connection.execute.assert_called_once()
    redis_client.close.assert_called_once()
    engine.dispose.assert_called_once()


def test_database_dependency_uses_request_app_state_and_closes_session():
    app = FastAPI()
    session = Mock()
    factory = Mock(return_value=session)
    app.state.session_factory = factory
    request = Request({"type": "http", "app": app, "headers": []})

    dependency = get_db(request)
    assert next(dependency) is session
    dependency.close()

    factory.assert_called_once_with()
    session.close.assert_called_once_with()
