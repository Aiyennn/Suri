import json
import logging

from app.core.redis import redis_client

logger = logging.getLogger(__name__)

def get_cache(key: str):
    value = redis_client.get(key)

    if value is None:
        logger.debug("Redis cache MISS: key=%s", key)
        return None

    logger.debug("Redis cache HIT: key=%s", key)
    return json.loads(value)

def set_cache(key: str, value, ttl: int = 300):
    redis_client.set(
        key,
        json.dumps(value),
        ex=ttl,
    )

    logger.debug(
        "Redis cache SET: key=%s ttl=%d",
        key,
        ttl
    )

def delete_cache(key: str):
    redis_client.delete(key)

    logger.debug("Redis cache DELETE: key=%s", key)