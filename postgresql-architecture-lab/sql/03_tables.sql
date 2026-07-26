\set ON_ERROR_STOP on

SET search_path TO app, public;

CREATE TABLE app.tenants (
    tenant_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_name TEXT NOT NULL,
    tenant_slug TEXT NOT NULL UNIQUE,
    plan_tier TEXT NOT NULL DEFAULT 'starter'
        CHECK (plan_tier IN ('starter', 'growth', 'enterprise')),
    settings JSONB NOT NULL DEFAULT '{}'::JSONB,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE app.users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES app.tenants(tenant_id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    display_name TEXT NOT NULL,
    user_role TEXT NOT NULL DEFAULT 'member'
        CHECK (user_role IN ('owner', 'admin', 'member', 'analyst')),
    profile JSONB NOT NULL DEFAULT '{}'::JSONB,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, user_id),
    UNIQUE (tenant_id, email)
);

CREATE TABLE app.customers (
    customer_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES app.tenants(tenant_id) ON DELETE CASCADE,
    customer_number TEXT NOT NULL,
    customer_name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    attributes JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, customer_id),
    UNIQUE (tenant_id, customer_number)
);

CREATE TABLE app.products (
    product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES app.tenants(tenant_id) ON DELETE CASCADE,
    sku TEXT NOT NULL,
    product_name TEXT NOT NULL,
    description TEXT,
    unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0),
    inventory_quantity INTEGER NOT NULL DEFAULT 0 CHECK (inventory_quantity >= 0),
    metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, product_id),
    UNIQUE (tenant_id, sku)
);

CREATE TABLE app.orders (
    order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES app.tenants(tenant_id) ON DELETE CASCADE,
    customer_id UUID NOT NULL,
    order_number TEXT NOT NULL,
    ordered_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL
        CHECK (status IN ('pending', 'paid', 'processing', 'shipped', 'completed', 'cancelled')),
    currency CHAR(3) NOT NULL DEFAULT 'USD'
        CHECK (currency = upper(currency)),
    subtotal NUMERIC(12, 2) NOT NULL CHECK (subtotal >= 0),
    tax_amount NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
    shipping_amount NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (shipping_amount >= 0),
    total_amount NUMERIC(12, 2)
        GENERATED ALWAYS AS (subtotal + tax_amount + shipping_amount) STORED,
    metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, order_id),
    UNIQUE (tenant_id, order_number),
    FOREIGN KEY (tenant_id, customer_id)
        REFERENCES app.customers(tenant_id, customer_id)
);

CREATE TABLE app.order_items (
    order_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES app.tenants(tenant_id) ON DELETE CASCADE,
    order_id UUID NOT NULL,
    product_id UUID NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0),
    discount_amount NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
    line_total NUMERIC(12, 2)
        GENERATED ALWAYS AS ((quantity * unit_price) - discount_amount) STORED,
    metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, order_item_id),
    FOREIGN KEY (tenant_id, order_id)
        REFERENCES app.orders(tenant_id, order_id) ON DELETE CASCADE,
    FOREIGN KEY (tenant_id, product_id)
        REFERENCES app.products(tenant_id, product_id),
    CHECK (discount_amount <= quantity * unit_price)
);

CREATE TABLE app.payments (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES app.tenants(tenant_id) ON DELETE CASCADE,
    order_id UUID NOT NULL,
    provider_reference TEXT,
    payment_method TEXT NOT NULL
        CHECK (payment_method IN ('card', 'bank_transfer', 'wallet', 'invoice')),
    status TEXT NOT NULL
        CHECK (status IN ('pending', 'authorized', 'captured', 'failed', 'refunded')),
    amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    currency CHAR(3) NOT NULL DEFAULT 'USD'
        CHECK (currency = upper(currency)),
    processed_at TIMESTAMPTZ,
    metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, payment_id),
    UNIQUE (tenant_id, provider_reference),
    FOREIGN KEY (tenant_id, order_id)
        REFERENCES app.orders(tenant_id, order_id)
);

COMMENT ON COLUMN app.orders.metadata IS
    'Optional source, coupon, shipping, and integration attributes.';
COMMENT ON COLUMN app.order_items.line_total IS
    'Database-generated quantity times unit price less discount.';

