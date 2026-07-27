# SQL Server Enterprise Architecture Lab v3

A 2022 architecture lab with repeatable Docker deployment, ordered database migrations, security roles, CDC, Query Store, operational views, and automated verification.

## First-time deployment on Windows

### 1. Prerequisites

Install and start:

- Docker Desktop
- PowerShell 5.1 or PowerShell 7
- DBeaver, SQL Server Management Studio, or Azure Data Studio

Confirm Docker is available:

```powershell
docker version
docker compose version
```

`docker version` must show both Client and Server sections.


### 2. Create `.env`

```powershell
Copy-Item .env.example .env
notepad .env
```

Replace all three sample passwords. Each password must contain uppercase and lowercase letters, a number, a special character, and at least 8 characters.

```text
MSSQL_SA_PASSWORD=UseYourOwnStrongPassword_123!
MSSQL_PORT=1433
MSSQL_PID=Developer
DB_NAME=EnterpriseCommerce
APP_LOGIN_PASSWORD=UseAnotherStrongPassword_123!
REPORT_LOGIN_PASSWORD=UseAThirdStrongPassword_123!
```

Do not commit `.env`.

### 3. Deploy

For a newly downloaded project or a normal redeployment:

```powershell
.\deploy.ps1
```

When replacing an older broken version of this lab, perform one clean reset:

```powershell
.\deploy.ps1 -Reset
```

The reset option deletes the named Docker volume and all previous lab data.

A successful run ends with:

```text
DEPLOYMENT COMPLETE AND VERIFIED
SQL Server lab deployed successfully.
```

### 4. Test the connection

```powershell
.\scripts\test-connection.ps1
```

Expected result:

```text
ConnectionStatus  DatabaseName
----------------  ------------------
PASS              EnterpriseCommerce
```

## DBeaver connection

Use a SQL Server connection:

```text
Host: localhost
Port: 1433
Database: EnterpriseCommerce
Authentication: SQL Server Authentication
Username: sa
Password: MSSQL_SA_PASSWORD from .env
```

Driver properties:

```text
encrypt=true
trustServerCertificate=true
```

If `MSSQL_PORT` is changed in `.env`, use that host port in DBeaver.

## Everyday commands

Deploy or reapply idempotent migrations:

```powershell
.\deploy.ps1
```

Completely reset the lab:

```powershell
.\deploy.ps1 -Reset
```

Check status:

```powershell
docker compose ps
```

Read SQL Server logs:

```powershell
docker compose logs --tail 150 sqlserver
```

Stop while preserving data:

```powershell
docker compose stop
```

Start again:

```powershell
docker compose start
```

Remove containers while preserving the named volume:

```powershell
docker compose down
```

## Deployment workflow

The root `deploy.ps1` performs the following work:

1. Validates Docker and `.env`.
2. Validates password complexity.
3. Optionally resets containers and the named volume.
4. Starts SQL Server.
5. Waits for the container health check.
6. Runs ordered migrations through the deployment container.
7. Verifies SQLCMD environment-variable substitution.
8. Executes database object and seed-data verification.
9. Executes a transactional order workflow test and rolls it back.
10. Executes the smoke test.
11. Writes a timestamped deployment log to `logs/`.

## Project structure

```text
.
├── deploy.ps1                  # single Windows entry point
├── docker-compose.yml
├── .env.example
├── architecture/
├── docs/
├── scripts/
│   ├── deploy.ps1              # orchestration
│   ├── deploy.sh               # migration runner inside Docker
│   └── test-connection.ps1
├── sql/
│   ├── deployment/             # ordered, idempotent migrations
│   ├── demos/
│   └── optional/
├── tests/
├── backups/
└── logs/
```

## Database capabilities

- Domain schemas: `sales`, `catalog`, `inventory`, `finance`, `hr`, `audit`, `ops`, and `reporting`
- Temporal customer history
- Transactional order creation and cancellation
- Inventory reservation with concurrency controls
- Least-privilege application and reporting logins
- Change Data Capture
- Query Store
- Monitoring views
- Audit events
- Backup procedure
- Seed data and automated verification

## Run the order demo

Execute the complete contents of:

```text
sql/demos/01_create_order.sql
```

Then inspect:

```sql
SELECT * FROM sales.SalesOrder ORDER BY SalesOrderId DESC;
SELECT * FROM sales.SalesOrderItem ORDER BY SalesOrderItemId DESC;
SELECT * FROM audit.EventLog ORDER BY EventLogId DESC;
SELECT * FROM reporting.vw_InventoryAvailability;
```

## Troubleshooting

### Deployment failed

Read the newest file under `logs/`. The runner prints:

```text
DEPLOYMENT FAILED
Step: /sql/deployment/<failing-file>.sql
```

The SQL Server error is printed immediately above it.

### Login failed for `sa`

An existing volume may have been initialized with another password. Run once:

```powershell
.\deploy.ps1 -Reset
```

### Port 1433 is occupied

```powershell
Get-NetTCPConnection -LocalPort 1433 -ErrorAction SilentlyContinue
```

Change `.env` to:

```text
MSSQL_PORT=14330
```

Then redeploy and connect to port `14330`.

### Certificate error

Set both DBeaver driver properties:

```text
encrypt=true
trustServerCertificate=true
```

### SQL Server is unhealthy

```powershell
docker compose ps -a
docker compose logs --tail 200 sqlserver
```
