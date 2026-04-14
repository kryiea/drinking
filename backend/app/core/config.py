from typing import Optional

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Yinzhi API"
    app_version: str = "0.1.0"
    api_prefix: str = "/v1"
    environment: str = "development"
    database_url: str = "sqlite:///./.data/yinzhi-dev.db"
    database_echo: bool = False
    redis_url: str = "redis://127.0.0.1:6379/0"
    object_storage_endpoint: str = "http://127.0.0.1:9000"
    object_storage_bucket: str = "yinzhi-exports"
    support_base_url: str = "http://127.0.0.1:8000"
    jwt_issuer: str = "yinzhi.local"
    jwt_audience: str = "yinzhi-ios"
    llm_provider: str = "openai-compatible"
    llm_base_url: Optional[str] = None
    llm_api_key: Optional[str] = None
    llm_model: Optional[str] = None
    llm_timeout_seconds: float = 20.0

    model_config = SettingsConfigDict(env_prefix="YINZHI_", case_sensitive=False)


settings = Settings()
