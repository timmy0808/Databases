from __future__ import annotations
from config import settings


def sqlserver_connection(database: str | None = None):
    import pyodbc
    db = database or settings.mssql_database
    return pyodbc.connect(
        "DRIVER={ODBC Driver 18 for SQL Server};"
        f"SERVER={settings.mssql_host},{settings.mssql_port};"
        f"DATABASE={db};UID={settings.mssql_user};PWD={settings.mssql_password};"
        "Encrypt=yes;TrustServerCertificate=yes;Connection Timeout=30;",
        autocommit=False,
    )


def postgres_connection():
    import psycopg
    return psycopg.connect(
        host=settings.postgres_host,
        port=settings.postgres_port,
        dbname=settings.postgres_database,
        user=settings.postgres_user,
        password=settings.postgres_password,
    )
