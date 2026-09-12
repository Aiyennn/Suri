import redis

from app.core.config import Settings


def create_redis_client(settings: Settings) -> redis.Redis:
    """Create the synchronous Redis client for one application instance."""
    return redis.from_url(settings.REDIS_URL, decode_responses=True)
