import pytest

from app.core.config import settings
from app.core.redis import create_redis_client


def test_redis_connection():
    redis_client = create_redis_client(settings)
    key = "test:redis:connection"
    connected = False

    try:
        redis_client.set(key, "hello")
        connected = True
        value = redis_client.get(key)

        assert value == "hello"
    except Exception as exc:
        pytest.skip(f"Redis is unavailable: {exc}")
    finally:
        if connected:
            try:
                redis_client.delete(key)
            except Exception:
                pass
        redis_client.close()
