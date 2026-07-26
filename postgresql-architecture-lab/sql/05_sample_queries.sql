\set ON_ERROR_STOP on

-- Inventory of initialized objects.
SELECT extname, extversion
FROM pg_extension
WHERE extname IN ('pgcrypto', 'pg_stat_statements', 'btree_gist')
ORDER BY extname;

-- Revenue and order volume by tenant.
SELECT
    t.tenant_name,
    count(o.order_id) AS order_count,
    coalesce(sum(o.total_amount), 0) AS revenue
FROM app.tenants AS t
LEFT JOIN app.orders AS o USING (tenant_id)
GROUP BY t.tenant_id, t.tenant_name
ORDER BY revenue DESC;

-- Demonstrate JSONB containment; a GIN index is added in the index milestone.
SELECT order_number, ordered_at, total_amount, metadata
FROM app.orders
WHERE metadata @> '{"source": "mobile"}'::JSONB
ORDER BY ordered_at DESC;

-- Validate computed totals against order-item totals.
SELECT
    o.order_number,
    o.subtotal,
    sum(oi.line_total) AS calculated_subtotal,
    o.subtotal = sum(oi.line_total) AS totals_match
FROM app.orders AS o
JOIN app.order_items AS oi
  ON oi.tenant_id = o.tenant_id
 AND oi.order_id = o.order_id
GROUP BY o.order_id
ORDER BY o.order_number;

-- Initial performance visibility.
SELECT
    query,
    calls,
    round(total_exec_time::NUMERIC, 2) AS total_exec_ms,
    round(mean_exec_time::NUMERIC, 2) AS mean_exec_ms,
    rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;

