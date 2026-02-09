# app/core/config.py
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    DB_URL: str

    JWT_SECRET: str = "dev_secret_change_me"
    JWT_ALG: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MIN: int = 10080  # 7 dias

    @property
    def DATABASE_URL(self) -> str:
        return self.DB_URL

settings = Settings()
