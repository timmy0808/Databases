# Architecture

TenantForge is a PostgreSQL reference implementation for a multi-tenant SaaS order platform.

```mermaid
flowchart LR
    A[Application or API] --> B[Connection Pool]
    B --> C[(PostgreSQL)]
    C --> D[app schema]
    C --> E[audit schema]
    C --> F[reporting schema]
    D --> G[Row-Level Security]
    D --> H[Partitioned Orders]
    D --> I[JSONB + GIN Indexes]
    E --> J[Trigger-based Change Log]
```

Each business row includes `tenant_id`. The application sets `app.current_tenant_id` for the current database session, and PostgreSQL row-level security policies enforce tenant isolation.
