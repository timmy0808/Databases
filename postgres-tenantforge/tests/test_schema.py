from pathlib import Path

SQL_DIR = Path(__file__).resolve().parents[1] / "sql"


def read_sql(name: str) -> str:
    return (SQL_DIR / name).read_text(encoding="utf-8")


def test_core_tables_include_tenant_id() -> None:
    sql = read_sql("03_tables.sql").lower()
    for table in ("users", "customers", "products", "orders", "order_items", "payments"):
        table_start = sql.index(f"create table app.{table}")
        table_end = sql.index(";", table_start)
        assert "tenant_id uuid not null" in sql[table_start:table_end]


def test_orders_are_partitioned() -> None:
    sql = read_sql("03_tables.sql").lower()
    assert "partition by range (order_timestamp)" in sql


def test_rls_is_enabled() -> None:
    sql = read_sql("05_security.sql").lower()
    assert "enable row level security" in sql
    assert "app.current_tenant_id" in sql


def test_audit_trigger_exists() -> None:
    sql = read_sql("06_audit.sql").lower()
    assert "capture_row_change" in sql
    assert "customers_audit_trigger" in sql
