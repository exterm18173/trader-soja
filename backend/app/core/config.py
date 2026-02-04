from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # aceita tanto DB_URL quanto DATABASE_URL
    DB_URL: str

    JWT_SECRET: str = "dev_secret_change_me"
    JWT_ALG: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MIN: int = 10080  # 7 dias

    @property
    def DATABASE_URL(self) -> str:
        # compatibilidade caso algum lugar use DATABASE_URL
        return self.DB_URL


settings = Settings()
