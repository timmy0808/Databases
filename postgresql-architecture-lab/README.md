# PostgreSQL SaaS Architecture Lab

A portfolio lab for production-oriented PostgreSQL architecture. The database
models a multi-tenant order-management SaaS and is designed to demonstrate
tenant-safe relational modeling, PostgreSQL internals, performance engineering,
security, observability, and recovery.

## Milestone 1: local database foundation

The current milestone provides:

- PostgreSQL 17 in Docker Compose with a persistent named volume
- `pg_stat_statements`, `pgcrypto`, and `btree_gist`
- Separate `app`, `audit`, and `reporting` schemas
- Tenants, users, customers, products, orders, order items, and payments
- UUID keys, checks, generated columns, JSONB, and referential integrity
- Composite foreign keys that prevent cross-tenant relationships
- Deterministic sample data generated with Python's standard library
- A health check and useful starter queries

Future milestones will add indexing experiments, row-level security, audit
triggers and pgAudit, partitioning, masked views, monitoring, backup/PITR, and
replication demonstrations.

## Architecture

```text
Application / DBeaver
          |
          v
PostgreSQL 17
  +-- app          transactional SaaS data
  +-- audit        security and change history
  +-- reporting    curated views and materialized views
          |
          +-- pg_stat_statements
          +-- persistent Docker volume
```

## Quick start

### 1. Configure

PowerShell:

```powershell
Copy-Item .env.example .env
```

Change the password in `.env`. The committed default is intended only to make
the lab easy to start locally.

### 2. Generate sample data

The repository includes generated sample data. Rebuild it deterministically:

```powershell
python src/generate_data.py --force
```

Useful options:

```powershell
python src/generate_data.py --tenants 3 --customers 20 --products 30 --orders 100 --force
```

### 3. Start PostgreSQL

```powershell
docker compose up -d
docker compose ps
```

Initialization scripts run in filename order only when the data volume is first
created.

### 4. Connect

Use DBeaver, pgAdmin, or `psql`:

| Setting | Value |
|---|---|
| Host | `localhost` |
| Port | value of `POSTGRES_PORT` (default `5432`) |
| Database | value of `POSTGRES_DB` (default `saas_lab`) |
| Username | value of `POSTGRES_USER` (default `lab_admin`) |
| Password | value of `POSTGRES_PASSWORD` |

CLI connection through the container:

```powershell
docker compose exec postgres psql -U lab_admin -d saas_lab
```

### 5. Verify

```sql
SELECT tenant_id, tenant_name, plan_tier
FROM app.tenants;

SELECT t.tenant_name, count(*) AS order_count, sum(o.total_amount) AS revenue
FROM app.orders AS o
JOIN app.tenants AS t USING (tenant_id)
GROUP BY t.tenant_name
ORDER BY revenue DESC;

SELECT query, calls, total_exec_time, mean_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

## Persistence and reset behavior

Stopping containers preserves data:

```powershell
docker compose down
docker compose up -d
```

To intentionally delete the local database and rerun every initialization
script:

```powershell
docker compose down --volumes
docker compose up -d
```

`down --volumes` is destructive. Do not use it for data you need to retain.

## Repository layout

```text
.
├── .env.example
├── docker-compose.yml
├── README.md
├── sql/
│   ├── 01_extensions.sql
│   ├── 02_schema.sql
│   ├── 03_tables.sql
│   ├── 04_sample_data.sql
│   └── 05_sample_queries.sql
├── src/
│   └── generate_data.py
└── tests/
    └── test_generate_data.py
```

## Design decisions

- **Shared-schema multi-tenancy:** economical and realistic for many SaaS
  systems; row-level security will become the defense-in-depth boundary.
- **Composite foreign keys:** `(tenant_id, entity_id)` ensures references stay
  within the same tenant even before RLS is introduced.
- **UUID primary keys:** safe for distributed ID generation and imports.
- **Generated order-item totals:** the database owns the multiplication rule.
- **JSONB metadata:** supports optional integration-specific attributes without
  weakening the relational core.
- **Money as `numeric`:** avoids floating-point rounding errors.

## Roadmap

1. Index laboratory with B-tree, GIN, GiST, BRIN, partial, composite, and
   covering index comparisons.
2. Least-privilege roles, tenant context, row-level security, and masked views.
3. Trigger-based audit history, pgAudit, and monthly range partitioning.
4. Prometheus, postgres_exporter, Grafana dashboards, and blocking-query labs.
5. Logical/physical backup exercises and a documented point-in-time recovery.
6. PgBouncer, TLS, health checks, and replication/failover concepts.

