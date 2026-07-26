CREATE OR REPLACE FUNCTION audit.capture_row_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, audit
AS $$
DECLARE
    v_tenant_id UUID;
    v_record_id TEXT;
BEGIN
    v_tenant_id := COALESCE(
        CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN (to_jsonb(OLD)->>'tenant_id')::UUID END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN (to_jsonb(NEW)->>'tenant_id')::UUID END
    );

    v_record_id := COALESCE(
        CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD)->>TG_ARGV[0] END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW)->>TG_ARGV[0] END
    );

    INSERT INTO audit.change_log (
        tenant_id, table_name, operation, record_id, old_values, new_values
    )
    VALUES (
        v_tenant_id,
        TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
        TG_OP,
        v_record_id,
        CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) END
    );

    RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER customers_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON app.customers
FOR EACH ROW EXECUTE FUNCTION audit.capture_row_change('customer_id');

CREATE TRIGGER products_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON app.products
FOR EACH ROW EXECUTE FUNCTION audit.capture_row_change('product_id');

CREATE TRIGGER orders_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON app.orders
FOR EACH ROW EXECUTE FUNCTION audit.capture_row_change('order_id');
