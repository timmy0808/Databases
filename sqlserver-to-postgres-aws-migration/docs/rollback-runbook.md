# Rollback runbook

## Safe rollback window

The cleanest rollback is before users create new data in PostgreSQL. Preserve SQL Server as the system of record until go-live approval.

## Procedure

1. Stop the PostgreSQL-backed application immediately.
2. Determine whether PostgreSQL received any business writes after cutover.
3. When no new writes exist, restore the SQL Server application configuration and resume source writers.
4. When new PostgreSQL writes exist, do not blindly reconnect SQL Server. Export and reconcile the delta under an approved recovery plan.
5. Record the rollback reason, timestamps, DMS task status, validation evidence, and affected records.
6. Correct the issue and repeat the migration rehearsal before another cutover.
