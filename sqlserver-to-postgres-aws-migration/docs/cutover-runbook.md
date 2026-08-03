# Cutover runbook

## Entry criteria

- DMS full load complete for all selected tables.
- No suspended or errored tables.
- DMS validation failures are zero or formally dispositioned.
- Independent validation passes.
- Application test suite passes against PostgreSQL.
- Backup and rollback checkpoints are recorded.

## Procedure

1. Announce the maintenance window and freeze deployment changes.
2. Stop scheduled jobs and diagnostic producers that write to SQL Server.
3. Put the source application into maintenance or read-only mode.
4. Record the UTC freeze time.
5. Monitor `CDCLatencySource` and `CDCLatencyTarget` until both approach zero.
6. Confirm DMS has no unapplied changes and all table statistics are healthy.
7. Run final source/target row-count, aggregate, integrity, and marker checks.
8. Stop the DMS task using `stop-task.ps1` after final changes are applied.
9. Reset any PostgreSQL sequences that correspond to SQL Server identity columns.
10. Apply `002_post_full_load_constraints.sql` if not previously applied.
11. Run `ANALYZE` and critical performance smoke tests.
12. Update the application secret or connection configuration to PostgreSQL.
13. Start the application and execute clinical workflow smoke tests.
14. Obtain technical and business go-live approval.
15. Keep SQL Server read-only through the agreed stabilization period.

## Go/no-go rules

Rollback before accepting new PostgreSQL writes when validation fails, CDC does not drain, or critical application tests fail. Once new writes occur in PostgreSQL, rollback requires explicit bidirectional reconciliation planning.
