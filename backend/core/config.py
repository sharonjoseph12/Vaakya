from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    GEMINI_API_KEY: str
    FIREBASE_SERVICE_ACCOUNT_PATH: str
    CHROMA_DB_PATH: str = "./chroma_db"

    class Config:
        env_file = ".env"

@lru_cache()
def get_settings():
    return Settings()
