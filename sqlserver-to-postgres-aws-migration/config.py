from __future__ import annotations
import os
from dataclasses import dataclass
from dotenv import load_dotenv

load_dotenv()

@dataclass(frozen=True)
class Settings:
    mssql_host: str = os.getenv("MSSQL_HOST", "localhost")
    mssql_port: int = int(os.getenv("MSSQL_PORT", "1433"))
    mssql_database: str = os.getenv("MSSQL_DATABASE", "TransplantDiagnostics")
    mssql_user: str = os.getenv("MSSQL_USER", "sa")
    mssql_password: str = os.getenv("MSSQL_PASSWORD", "ChangeMe_StrongPassword123!")
    postgres_host: str = os.getenv("POSTGRES_HOST", "localhost")
    postgres_port: int = int(os.getenv("POSTGRES_PORT", "5432"))
    postgres_database: str = os.getenv("POSTGRES_DATABASE", "transplant_diagnostics")
    postgres_user: str = os.getenv("POSTGRES_USER", "postgres")
    postgres_password: str = os.getenv("POSTGRES_PASSWORD", "postgres")
    batch_size: int = int(os.getenv("BATCH_SIZE", "1000"))
    cdc_poll_seconds: int = int(os.getenv("CDC_POLL_SECONDS", "2"))

settings = Settings()
