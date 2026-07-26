# TenantForge PostgreSQL

A PostgreSQL reference architecture for a secure, multi-tenant SaaS order-management platform.

## What this project demonstrates

- Multi-tenant relational modeling
- PostgreSQL row-level security
- Range partitioning
- B-tree and GIN indexes
- JSONB storage and querying
- Trigger-based audit logging
- Reporting views
- Docker Compose deployment
- Python test-data generation
- Automated validation with GitHub Actions

## Repository structure

```text
.
├── sql/                  Database initialization scripts
├── src/                  Python data-generation utilities
├── tests/                Automated repository tests
├── scripts/              Reset and backup helpers
├── docs/                 Architecture documentation
├── .github/workflows/    CI workflow
├── docker-compose.yml
└── .env.example
```

## Start the database

```bash
cp .env.example .env
docker compose up -d
```

Check container health:

```bash
docker compose ps
```

## Connect with DBeaver

Use these values from `.env`:

```text
Host: localhost
Port: 5432
Database: tenantforge
Username: tenantforge_admin
Password: change_me
```

Change the password in your local `.env` before using the project outside a local demonstration environment.

## Verify the schema

```bash
docker compose exec postgres psql \
  -U tenantforge_admin \
  -d tenantforge \
  -c "SELECT tenant_name FROM app.tenants;"
```



## Generate larger test data

Create a virtual environment and install dependencies:

```bash
python -m venv .venv
.venv\Scripts\activate.bat
pip install -r requirements.txt
```

On Windows PowerShell, activate it with:

```powershell
.venv\Scripts\Activate.ps1
```

Set the database environment variables or load them from `.env`, then run:

```bash
python src/generate_data.py --tenants 3 --customers 100 --orders 1000
```

## Demonstrate tenant isolation

Connect using a non-owner application role in a production-style deployment, then set the current tenant for the session:

```sql
SELECT set_config(
    'app.current_tenant_id',
    '00000000-0000-0000-0000-000000000000',
    false
);

SELECT * FROM app.orders;
```

The row-level security policy restricts results to the configured tenant.

## Useful queries

```sql
SELECT * FROM reporting.daily_sales ORDER BY sales_date DESC;

SELECT query, calls, total_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;

EXPLAIN (ANALYZE, BUFFERS)
SELECT order_number, status, total_amount
FROM app.orders
WHERE tenant_id = '00000000-0000-0000-0000-000000000000'
ORDER BY order_timestamp DESC
LIMIT 50;
```

## Stop or reset

Stop while retaining data:

```bash
docker compose down
```

Delete the container and named volume, then rebuild:

```bash
docker compose down -v
docker compose up -d
```

## Run tests

```bash
pytest -q
```


