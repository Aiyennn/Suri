"""
core/config.py
==============
Application settings loaded from environment variables via pydantic-settings.

All configuration is centralised here so that every module imports a single
``settings`` instance rather than reading ``os.environ`` directly.

Environment loading order (later files override earlier ones):
  1. ``.env``            – base / shared defaults
  2. ``.env.<ENVIRONMENT>``  – environment-specific overrides
     e.g. ``.env.development``, ``.env.production``, ``.env.testing``

Set the ``ENVIRONMENT`` shell variable (or add it to ``.env``) to switch
between environments.  Defaults to ``"development"``.
"""

import os
from pathlib import Path
from typing import Annotated
from typing import Annotated, Literal

from pydantic import BeforeValidator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parent.parent.parent

# Read ENVIRONMENT early so we can pick the right .env file before pydantic
# initialises the full settings object.
_env = os.getenv("ENVIRONMENT", "development")


def _parse_cors_origins(value: str | list[str]) -> list[str]:
    if isinstance(value, str):
        return [origin.strip() for origin in value.split(",") if origin.strip()]
    return value


CorsOrigins = Annotated[list[str], NoDecode, BeforeValidator(_parse_cors_origins)]


class Settings(BaseSettings):
    """
    Application-wide configuration.

    Values are loaded from a ``.env`` file located in the ``backend/``
    directory (one level above ``app/``).  Any environment variable that
    matches a field name (case-insensitive) will override the file value.
    Values are loaded from ``.env`` and then ``.env.<ENVIRONMENT>`` (if it
    exists) located in the ``backend/`` directory.  Any environment variable
    that matches a field name (case-insensitive) will override the file values.
    """

    model_config = SettingsConfigDict(
        # Later files take precedence — .env.development overrides .env
        env_file=[
            BASE_DIR / ".env",
            BASE_DIR / f".env.{_env}",
        ],
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # ── Environment ───────────────────────────────────────────────────────
    ENVIRONMENT: Literal["development", "production", "testing"] = "development"

    # ── Database ──────────────────────────────────────────────────────────
    DATABASE_URL: str
    DIRECT_DATABASE_URL: str = ""

    # ── Application ───────────────────────────────────────────────────────
    APP_NAME: str = "Suri"
    DEBUG: bool = True
    CORS_ORIGINS: CorsOrigins = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8080",
    ]
    CORS_ALLOW_CREDENTIALS: bool = True

    # ── File storage ─────────────────────────────────────────────────────
    UPLOAD_DIR: str = str(BASE_DIR / "uploads")

    # ── Auth / JWT ────────────────────────────────────────────────────────
    SECRET_KEY: str = "change-me-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    # ── Redis ────────────────────────────────────────────────────────
    REDIS_URL: str
    REDIS_URL: str = "redis://localhost:6380/0"

    # ── Overpass API ─────────────────────────────────────────────────
    OVERPASS_URL: str = "https://overpass-api.de/api/interpreter"
    OVERPASS_TIMEOUT_SECONDS: int = 30

    # ── Gemini AI ─────────────────────────────────────────────────────
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemini-3.6-flash"

    # ── Convenience helpers ───────────────────────────────────────────
    @property
    def is_development(self) -> bool:
        """True when running against the local Docker dev stack."""
        return self.ENVIRONMENT == "development"

    @property
    def is_production(self) -> bool:
        """True when running against the production Supabase stack."""
        return self.ENVIRONMENT == "production"

    @property
    def is_testing(self) -> bool:
        """True when running the test suite."""
        return self.ENVIRONMENT == "testing"

    @property
    def db_url_safe(self) -> str:
        """DATABASE_URL with the password masked — safe for logging."""
        from urllib.parse import urlparse, urlunparse

        parsed = urlparse(self.DATABASE_URL)
        masked = parsed._replace(
            netloc=f"{parsed.username}:***@{parsed.hostname}"
            + (f":{parsed.port}" if parsed.port else "")
        )
        return urlunparse(masked)


settings = Settings()
