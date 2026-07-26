CREATE OR REPLACE VIEW reporting.daily_sales AS
SELECT
    tenant_id,
    order_timestamp::DATE AS sales_date,
    COUNT(*) AS order_count,
    SUM(total_amount) AS gross_sales,
    AVG(total_amount) AS average_order_value
FROM app.orders
WHERE status IN ('PAID', 'SHIPPED')
GROUP BY tenant_id, order_timestamp::DATE;

CREATE OR REPLACE VIEW reporting.customer_lifetime_value AS
SELECT
    c.tenant_id,
    c.customer_id,
    c.full_name,
    COUNT(o.order_id) AS completed_orders,
    COALESCE(SUM(o.total_amount), 0) AS lifetime_value
FROM app.customers c
LEFT JOIN app.orders o
  ON o.tenant_id = c.tenant_id
 AND o.customer_id = c.customer_id
 AND o.status IN ('PAID', 'SHIPPED')
GROUP BY c.tenant_id, c.customer_id, c.full_name;
