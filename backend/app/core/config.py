"""
core/config.py
==============
Application settings loaded from environment variables via pydantic-settings.

All configuration is centralised here so that every module imports a single
``settings`` instance rather than reading ``os.environ`` directly.
"""
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parent.parent.parent


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

    # ── File storage ─────────────────────────────────────────────────────
    UPLOAD_DIR: str = str(BASE_DIR / "uploads")

    # ── Auth / JWT ────────────────────────────────────────────────────────
    SECRET_KEY: str = "change-me-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    # ── Redis ────────────────────────────────────────────────────────
    REDIS_URL: str

settings = Settings()
