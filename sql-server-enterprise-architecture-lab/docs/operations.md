# Operations Runbook

## Start and deploy

```bash
docker compose up -d sqlserver
docker compose run --rm db-deploy
```

## View status and logs

```bash
docker compose ps
docker compose logs -f sqlserver
```

## Backup

```sql
EXEC ops.usp_BackupDatabase;
```

Backups appear in the local `backups/` folder.

## Recovery exercise

1. Create a full backup.
2. Copy the backup to a separate test location.
3. Restore it under a different database name.
4. Run integrity and smoke tests.
5. Record recovery time and data-loss objectives.

## Monitoring

```sql
SELECT * FROM ops.vw_LongRunningQueries;
SELECT * FROM ops.vw_IndexUsage;
SELECT * FROM sys.database_query_store_options;
```

## Reset the lab

```bash
docker compose down -v
docker compose up -d sqlserver
docker compose run --rm db-deploy
```

Resetting deletes the Docker volume and all database data.
