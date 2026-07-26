from __future__ import annotations

import argparse
import os
import random
import uuid
from datetime import UTC, datetime, timedelta
from decimal import Decimal

import psycopg
from faker import Faker

fake = Faker()


def get_connection() -> psycopg.Connection:
    return psycopg.connect(
        host=os.getenv("PGHOST", "localhost"),
        port=os.getenv("PGPORT", "5432"),
        dbname=os.getenv("POSTGRES_DB", "tenantforge"),
        user=os.getenv("POSTGRES_USER", "tenantforge_admin"),
        password=os.getenv("POSTGRES_PASSWORD", "change_me"),
    )


def generate(tenants: int, customers_per_tenant: int, orders_per_tenant: int) -> None:
    with get_connection() as conn:
        with conn.cursor() as cur:
            for tenant_number in range(1, tenants + 1):
                tenant_name = f"Demo Tenant {tenant_number:02d}"
                cur.execute(
                    """
                    INSERT INTO app.tenants (tenant_name)
                    VALUES (%s)
                    ON CONFLICT (tenant_name) DO UPDATE SET tenant_name = EXCLUDED.tenant_name
                    RETURNING tenant_id
                    """,
                    (tenant_name,),
                )
                tenant_id = cur.fetchone()[0]

                customer_ids: list[uuid.UUID] = []
                for customer_number in range(customers_per_tenant):
                    external_id = f"C-{tenant_number:02d}-{customer_number:05d}"
                    cur.execute(
                        """
                        INSERT INTO app.customers (
                            tenant_id, external_customer_id, full_name, email, customer_metadata
                        )
                        VALUES (%s, %s, %s, %s, %s)
                        ON CONFLICT (tenant_id, external_customer_id)
                        DO UPDATE SET full_name = EXCLUDED.full_name
                        RETURNING customer_id
                        """,
                        (
                            tenant_id,
                            external_id,
                            fake.name(),
                            fake.unique.email(),
                            psycopg.types.json.Jsonb({"segment": random.choice(["consumer", "business", "enterprise"])}),
                        ),
                    )
                    customer_ids.append(cur.fetchone()[0])

                product_ids: list[tuple[uuid.UUID, Decimal]] = []
                for product_number in range(20):
                    price = Decimal(random.randint(1000, 250000)) / Decimal("100")
                    sku = f"SKU-{tenant_number:02d}-{product_number:03d}"
                    cur.execute(
                        """
                        INSERT INTO app.products (
                            tenant_id, sku, product_name, category, unit_price, attributes
                        )
                        VALUES (%s, %s, %s, %s, %s, %s)
                        ON CONFLICT (tenant_id, sku)
                        DO UPDATE SET unit_price = EXCLUDED.unit_price
                        RETURNING product_id, unit_price
                        """,
                        (
                            tenant_id,
                            sku,
                            fake.catch_phrase(),
                            random.choice(["Electronics", "Home", "Tools", "Office"]),
                            price,
                            psycopg.types.json.Jsonb({"color": fake.color_name()}),
                        ),
                    )
                    product_ids.append(cur.fetchone())

                for order_number in range(orders_per_tenant):
                    customer_id = random.choice(customer_ids)
                    product_id, unit_price = random.choice(product_ids)
                    quantity = random.randint(1, 5)
                    order_timestamp = datetime.now(UTC) - timedelta(days=random.randint(0, 60))
                    total = unit_price * quantity
                    order_ref = f"ORD-{tenant_number:02d}-{order_number:07d}"

                    cur.execute(
                        """
                        INSERT INTO app.orders (
                            tenant_id, customer_id, order_number, order_timestamp,
                            status, total_amount, order_metadata
                        )
                        VALUES (%s, %s, %s, %s, %s, %s, %s)
                        ON CONFLICT (tenant_id, order_number, order_timestamp) DO NOTHING
                        RETURNING order_id
                        """,
                        (
                            tenant_id,
                            customer_id,
                            order_ref,
                            order_timestamp,
                            random.choice(["PAID", "SHIPPED", "CANCELLED"]),
                            total,
                            psycopg.types.json.Jsonb({"source": random.choice(["web", "mobile", "api"])}),
                        ),
                    )
                    result = cur.fetchone()
                    if result:
                        cur.execute(
                            """
                            INSERT INTO app.order_items (
                                tenant_id, order_id, product_id, quantity, unit_price
                            )
                            VALUES (%s, %s, %s, %s, %s)
                            """,
                            (tenant_id, result[0], product_id, quantity, unit_price),
                        )

        conn.commit()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate TenantForge demonstration data")
    parser.add_argument("--tenants", type=int, default=3)
    parser.add_argument("--customers", type=int, default=100)
    parser.add_argument("--orders", type=int, default=1000)
    args = parser.parse_args()
    generate(args.tenants, args.customers, args.orders)
