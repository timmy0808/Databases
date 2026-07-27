# Architecture

```mermaid
flowchart LR
    APP[Order Management API] -->|Stored procedures| SQL[(SQL Server)]
    BI[Reporting / BI] -->|Read-only views| SQL
    DBA[DBA / Architect] -->|Monitoring and administration| SQL

    subgraph SQL_Server[EnterpriseCommerce Database]
        SALES[sales]
        CATALOG[catalog]
        INV[inventory]
        FIN[finance]
        AUDIT[audit]
        REPORT[reporting]
        OPS[ops]

        SALES --> CATALOG
        SALES --> INV
        FIN --> SALES
        REPORT --> SALES
        REPORT --> INV
        SALES --> AUDIT
    end

    SQL --> BACKUP[(Backup Volume)]
    SQL --> QS[Query Store]
    SQL --> CDC[Change Data Capture]
```

## Production reference architecture

The local Docker deployment is a single-node development lab. A production design
would normally place SQL Server on dedicated infrastructure, use Availability
Groups or a managed SQL platform for high availability, separate data/log/backup
storage, integrate enterprise identity, encrypt connections, centralize secrets,
ship audit logs to a SIEM, and test backup restoration regularly.
