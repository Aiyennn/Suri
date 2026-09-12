"""
core/config.py
==============
Application settings loaded from environment variables via pydantic-settings.

All configuration is centralised here so that every module imports a single
``settings`` instance rather than reading ``os.environ`` directly.
"""

from pathlib import Path
from typing import Annotated

from pydantic import BeforeValidator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parent.parent.parent


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
    """

    model_config = SettingsConfigDict(
        env_file=BASE_DIR / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # ── Database ──────────────────────────────────────────────────────────
    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/suri"
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

    # ── Overpass API ─────────────────────────────────────────────────
    OVERPASS_URL: str = "https://overpass-api.de/api/interpreter"
    OVERPASS_TIMEOUT_SECONDS: int = 30

    # ── Gemini AI ─────────────────────────────────────────────────────
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemini-3.6-flash"


settings = Settings()
