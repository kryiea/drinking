from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Yinzhi API"
    app_version: str = "0.1.0"
    api_prefix: str = "/v1"
    environment: str = "development"
    database_url: str = "sqlite:///./.data/yinzhi-dev.db"
    database_echo: bool = False
    jwt_issuer: str = "yinzhi.local"
    jwt_audience: str = "yinzhi-ios"

    model_config = SettingsConfigDict(env_prefix="YINZHI_", case_sensitive=False)


settings = Settings()
