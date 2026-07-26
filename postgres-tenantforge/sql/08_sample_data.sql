WITH inserted_tenants AS (
    INSERT INTO app.tenants (tenant_name)
    VALUES ('Northstar Retail'), ('Summit Supply')
    ON CONFLICT (tenant_name) DO UPDATE SET tenant_name = EXCLUDED.tenant_name
    RETURNING tenant_id, tenant_name
)
INSERT INTO app.users (tenant_id, email, display_name, role_name)
SELECT tenant_id,
       lower(replace(tenant_name, ' ', '.')) || '@example.com',
       tenant_name || ' Admin',
       'ADMIN'
FROM inserted_tenants
ON CONFLICT (tenant_id, email) DO NOTHING;

DO $$
DECLARE
    northstar UUID;
    summit UUID;
    northstar_customer UUID;
    summit_customer UUID;
    northstar_product UUID;
    summit_product UUID;
    northstar_order UUID;
    summit_order UUID;
BEGIN
    SELECT tenant_id INTO northstar FROM app.tenants WHERE tenant_name = 'Northstar Retail';
    SELECT tenant_id INTO summit FROM app.tenants WHERE tenant_name = 'Summit Supply';

    INSERT INTO app.customers (tenant_id, external_customer_id, full_name, email, customer_metadata)
    VALUES
      (northstar, 'N-1001', 'Avery Stone', 'avery@example.com', '{"segment":"enterprise"}'),
      (summit, 'S-2001', 'Jordan Reed', 'jordan@example.com', '{"segment":"small-business"}')
    ON CONFLICT (tenant_id, external_customer_id) DO UPDATE SET full_name = EXCLUDED.full_name
    RETURNING customer_id INTO northstar_customer;

    SELECT customer_id INTO northstar_customer FROM app.customers WHERE tenant_id = northstar AND external_customer_id = 'N-1001';
    SELECT customer_id INTO summit_customer FROM app.customers WHERE tenant_id = summit AND external_customer_id = 'S-2001';

    INSERT INTO app.products (tenant_id, sku, product_name, category, unit_price, attributes)
    VALUES
      (northstar, 'NS-LAP-01', 'Field Laptop', 'Electronics', 1299.00, '{"warranty_years":3}'),
      (summit, 'SS-DRL-01', 'Cordless Drill', 'Tools', 189.00, '{"voltage":20}')
    ON CONFLICT (tenant_id, sku) DO UPDATE SET unit_price = EXCLUDED.unit_price;

    SELECT product_id INTO northstar_product FROM app.products WHERE tenant_id = northstar AND sku = 'NS-LAP-01';
    SELECT product_id INTO summit_product FROM app.products WHERE tenant_id = summit AND sku = 'SS-DRL-01';

    INSERT INTO app.orders (tenant_id, customer_id, order_number, order_timestamp, status, total_amount, order_metadata)
    VALUES
      (northstar, northstar_customer, 'NS-ORD-1001', '2026-07-15T10:00:00Z', 'PAID', 1299.00, '{"source":"web"}'),
      (summit, summit_customer, 'SS-ORD-2001', '2026-07-16T12:00:00Z', 'SHIPPED', 378.00, '{"source":"mobile"}')
    ON CONFLICT (tenant_id, order_number, order_timestamp) DO NOTHING;

    SELECT order_id INTO northstar_order FROM app.orders WHERE tenant_id = northstar AND order_number = 'NS-ORD-1001';
    SELECT order_id INTO summit_order FROM app.orders WHERE tenant_id = summit AND order_number = 'SS-ORD-2001';

    IF NOT EXISTS (SELECT 1 FROM app.order_items WHERE tenant_id = northstar AND order_id = northstar_order) THEN
        INSERT INTO app.order_items (tenant_id, order_id, product_id, quantity, unit_price)
        VALUES (northstar, northstar_order, northstar_product, 1, 1299.00);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM app.order_items WHERE tenant_id = summit AND order_id = summit_order) THEN
        INSERT INTO app.order_items (tenant_id, order_id, product_id, quantity, unit_price)
        VALUES (summit, summit_order, summit_product, 2, 189.00);
    END IF;
END $$;
