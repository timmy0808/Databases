# Panel demonstration

## Five-minute walkthrough

1. Show the SQL Server schema and call out `UNIQUEIDENTIFIER`, `DATETIME2`, `BIT`, JSON in `NVARCHAR(MAX)`, `ROWVERSION`, `IDENTITY`, and T-SQL `TOP`.
2. Show the converted PostgreSQL schema and explain what DMS migrates versus what must be converted separately.
3. Show Terraform resources and security-group flow.
4. Show the DMS task type: `full-load-and-cdc`.
5. Start or display the running task and table statistics.
6. Execute `004_demo_cdc_changes.sql` against SQL Server.
7. Show inserts, updates, and deletes arriving in PostgreSQL.
8. Show DMS validation and the independent validation report.
9. Explain cutover criteria, sequence handling, and rollback.

## Core message

> DMS minimizes downtime, but it does not remove the need for schema conversion, application remediation, business validation, operational rehearsal, or rollback planning.
