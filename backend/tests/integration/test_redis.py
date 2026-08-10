from app.core.redis import redis_client


def test_redis_connection():
    key = "test:redis:connection"

    redis_client.set(key, "hello")
    value = redis_client.get(key)

    assert value == "hello"

    redis_client.delete(key)