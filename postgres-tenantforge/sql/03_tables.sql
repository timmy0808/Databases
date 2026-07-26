CREATE TABLE app.tenants (
    tenant_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_name TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'SUSPENDED', 'CLOSED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE app.users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES app.tenants(tenant_id) ON DELETE CASCADE,
    email CITEXT NOT NULL,
    display_name TEXT NOT NULL,
    role_name TEXT NOT NULL CHECK (role_name IN ('ADMIN', 'MANAGER', 'ANALYST', 'USER')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, email)
);

CREATE TABLE app.customers (
    customer_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES app.tenants(tenant_id) ON DELETE CASCADE,
    external_customer_id TEXT,
    full_name TEXT NOT NULL,
    email CITEXT,
    phone TEXT,
    customer_metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, external_customer_id)
);

CREATE TABLE app.products (
    product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES app.tenants(tenant_id) ON DELETE CASCADE,
    sku TEXT NOT NULL,
    product_name TEXT NOT NULL,
    category TEXT,
    unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    attributes JSONB NOT NULL DEFAULT '{}'::JSONB,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, sku)
);

CREATE TABLE app.orders (
    order_id UUID NOT NULL DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES app.tenants(tenant_id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES app.customers(customer_id),
    order_number TEXT NOT NULL,
    order_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status TEXT NOT NULL CHECK (status IN ('PENDING', 'PAID', 'SHIPPED', 'CANCELLED', 'REFUNDED')),
    total_amount NUMERIC(14,2) NOT NULL CHECK (total_amount >= 0),
    order_metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (order_id, order_timestamp),
    UNIQUE (tenant_id, order_number, order_timestamp)
) PARTITION BY RANGE (order_timestamp);

CREATE TABLE app.orders_2026_q3 PARTITION OF app.orders
FOR VALUES FROM ('2026-07-01') TO ('2026-10-01');

CREATE TABLE app.orders_default PARTITION OF app.orders DEFAULT;

CREATE TABLE app.order_items (
    order_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES app.tenants(tenant_id) ON DELETE CASCADE,
    order_id UUID NOT NULL,
    product_id UUID NOT NULL REFERENCES app.products(product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    line_total NUMERIC(14,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE app.payments (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES app.tenants(tenant_id) ON DELETE CASCADE,
    order_id UUID NOT NULL,
    payment_provider TEXT NOT NULL,
    provider_reference TEXT,
    amount NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
    status TEXT NOT NULL CHECK (status IN ('PENDING', 'AUTHORIZED', 'CAPTURED', 'FAILED', 'REFUNDED')),
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audit.change_log (
    audit_id BIGINT GENERATED ALWAYS AS IDENTITY,
    tenant_id UUID,
    table_name TEXT NOT NULL,
    operation TEXT NOT NULL,
    record_id TEXT,
    changed_by TEXT NOT NULL DEFAULT CURRENT_USER,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    old_values JSONB,
    new_values JSONB,
    PRIMARY KEY (audit_id, changed_at)
) PARTITION BY RANGE (changed_at);

CREATE TABLE audit.change_log_2026_q3 PARTITION OF audit.change_log
FOR VALUES FROM ('2026-07-01') TO ('2026-10-01');

CREATE TABLE audit.change_log_default PARTITION OF audit.change_log DEFAULT;
