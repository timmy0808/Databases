CREATE INDEX idx_users_tenant_role
    ON app.users (tenant_id, role_name)
    WHERE is_active = TRUE;

CREATE INDEX idx_customers_tenant_email
    ON app.customers (tenant_id, email);

CREATE INDEX idx_customers_metadata_gin
    ON app.customers USING GIN (customer_metadata);

CREATE INDEX idx_products_tenant_category
    ON app.products (tenant_id, category)
    INCLUDE (product_name, unit_price);

CREATE INDEX idx_products_attributes_gin
    ON app.products USING GIN (attributes);

CREATE INDEX idx_orders_tenant_timestamp
    ON app.orders (tenant_id, order_timestamp DESC)
    INCLUDE (status, total_amount);

CREATE INDEX idx_orders_metadata_gin
    ON app.orders USING GIN (order_metadata);

CREATE INDEX idx_order_items_tenant_order
    ON app.order_items (tenant_id, order_id);

CREATE INDEX idx_payments_tenant_order
    ON app.payments (tenant_id, order_id);
