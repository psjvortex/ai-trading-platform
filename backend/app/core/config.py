from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import AnyUrl
from typing import Optional, List


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # Core
    PROJECT_NAME: str = "AI Trading Platform API"
    BACKEND_CORS_ORIGINS: List[str] = []  # e.g., ["http://localhost:5173"]
    POSTGRES_URL: str = "postgresql+psycopg://trader:trader@db:5432/trading"
    POLYGON_API_KEY: Optional[str] = None

    # TradeLocker (not legacy; use updated names as provided)
    TRADELOCKER_ENVIRONMENT: str = "demo"  # demo | live
    TRADELOCKER_DEMO_USERNAME: Optional[str] = None
    TRADELOCKER_DEMO_PASSWORD: Optional[str] = None
    TRADELOCKER_DEMO_SERVER: Optional[str] = None
    TRADELOCKER_DEMO_URL: Optional[str] = None
    TRADELOCKER_DEMO_ACCOUNT_ID: Optional[str] = None
    TRADELOCKER_DEMO_ACC_NUM: Optional[str] = None

    TRADELOCKER_LIVE_USERNAME: Optional[str] = None
    TRADELOCKER_LIVE_PASSWORD: Optional[str] = None
    TRADELOCKER_LIVE_SERVER: Optional[str] = None
    TRADELOCKER_LIVE_URL: Optional[str] = None
    TRADELOCKER_LIVE_ACCOUNT_ID: Optional[str] = None

    # Observability
    OTEL_EXPORTER_OTLP_ENDPOINT: Optional[AnyUrl] = None


settings = Settings()  # type: ignore
