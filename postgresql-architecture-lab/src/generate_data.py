"""Generate deterministic SQL seed data for the PostgreSQL SaaS lab."""

from __future__ import annotations

import argparse
import json
import random
import uuid
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path


NAMESPACE = uuid.UUID("77a68a17-6355-47db-a4b1-43f839b1695d")
DEFAULT_OUTPUT = Path(__file__).resolve().parents[1] / "sql" / "04_sample_data.sql"


def stable_uuid(*parts: object) -> uuid.UUID:
    return uuid.uuid5(NAMESPACE, ":".join(str(part) for part in parts))


def sql_text(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def sql_json(value: dict[str, object]) -> str:
    return sql_text(json.dumps(value, separators=(",", ":"), sort_keys=True)) + "::JSONB"


def money(value: Decimal) -> str:
    return str(value.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))


@dataclass(frozen=True)
class Config:
    tenants: int
    customers: int
    products: int
    orders: int
    seed: int


def generate_sql(config: Config) -> str:
    rng = random.Random(config.seed)
    lines = [
        r"\set ON_ERROR_STOP on",
        "",
        "BEGIN;",
        "SET search_path TO app, public;",
        "",
        "TRUNCATE app.payments, app.order_items, app.orders, app.products,",
        "         app.customers, app.users, app.tenants CASCADE;",
        "",
    ]
    base_time = datetime(2026, 7, 1, 12, 0, tzinfo=UTC)
    sources = ("web", "mobile", "api")
    shipping_methods = ("standard", "express", "pickup")
    statuses = ("paid", "processing", "shipped", "completed")

    for tenant_number in range(1, config.tenants + 1):
        tenant_id = stable_uuid("tenant", tenant_number)
        tenant_slug = f"tenant-{tenant_number:02d}"
        lines.append(
            "INSERT INTO app.tenants "
            "(tenant_id, tenant_name, tenant_slug, plan_tier, settings) VALUES "
            f"('{tenant_id}', 'Demo Tenant {tenant_number:02d}', "
            f"'{tenant_slug}', "
            f"'{('growth', 'enterprise', 'starter')[(tenant_number - 1) % 3]}', "
            f"{sql_json({'timezone': 'America/Denver', 'currency': 'USD'})});"
        )

        user_id = stable_uuid("user", tenant_number, 1)
        lines.append(
            "INSERT INTO app.users "
            "(user_id, tenant_id, email, display_name, user_role) VALUES "
            f"('{user_id}', '{tenant_id}', "
            f"'owner@{tenant_slug}.example', 'Tenant {tenant_number} Owner', 'owner');"
        )

        customer_ids: list[uuid.UUID] = []
        for customer_number in range(1, config.customers + 1):
            customer_id = stable_uuid("customer", tenant_number, customer_number)
            customer_ids.append(customer_id)
            lines.append(
                "INSERT INTO app.customers "
                "(customer_id, tenant_id, customer_number, customer_name, email, attributes) VALUES "
                f"('{customer_id}', '{tenant_id}', 'C-{customer_number:05d}', "
                f"'Customer {tenant_number}-{customer_number}', "
                f"'customer{customer_number}@{tenant_slug}.example', "
                f"{sql_json({'segment': ('consumer', 'business')[customer_number % 2]})});"
            )

        products: list[tuple[uuid.UUID, Decimal]] = []
        for product_number in range(1, config.products + 1):
            product_id = stable_uuid("product", tenant_number, product_number)
            unit_price = Decimal(10 + product_number * 3) + Decimal("0.99")
            products.append((product_id, unit_price))
            lines.append(
                "INSERT INTO app.products "
                "(product_id, tenant_id, sku, product_name, unit_price, "
                "inventory_quantity, metadata) VALUES "
                f"('{product_id}', '{tenant_id}', 'SKU-{product_number:05d}', "
                f"'Product {tenant_number}-{product_number}', {money(unit_price)}, "
                f"{100 + product_number}, "
                f"{sql_json({'category': ('office', 'electronics', 'home')[product_number % 3]})});"
            )

        for order_number in range(1, config.orders + 1):
            order_id = stable_uuid("order", tenant_number, order_number)
            customer_id = customer_ids[(order_number - 1) % len(customer_ids)]
            ordered_at = base_time + timedelta(
                days=(order_number - 1) % 28,
                minutes=tenant_number * 17 + order_number,
            )
            selected_products = rng.sample(products, k=min(2, len(products)))
            line_values: list[tuple[uuid.UUID, Decimal, int]] = []
            subtotal = Decimal("0")
            for product_id, unit_price in selected_products:
                quantity = rng.randint(1, 4)
                line_values.append((product_id, unit_price, quantity))
                subtotal += unit_price * quantity

            tax = subtotal * Decimal("0.0825")
            shipping = Decimal("0") if subtotal >= 100 else Decimal("8.00")
            source = sources[(tenant_number + order_number) % len(sources)]
            shipping_method = shipping_methods[order_number % len(shipping_methods)]
            metadata = {
                "source": source,
                "shipping_method": shipping_method,
            }
            if order_number % 5 == 0:
                metadata["coupon"] = "WELCOME10"

            lines.append(
                "INSERT INTO app.orders "
                "(order_id, tenant_id, customer_id, order_number, ordered_at, "
                "status, subtotal, tax_amount, shipping_amount, metadata) VALUES "
                f"('{order_id}', '{tenant_id}', '{customer_id}', "
                f"'ORD-{tenant_number:02d}-{order_number:06d}', "
                f"'{ordered_at.isoformat()}', "
                f"'{statuses[order_number % len(statuses)]}', {money(subtotal)}, "
                f"{money(tax)}, {money(shipping)}, {sql_json(metadata)});"
            )

            for item_number, (product_id, unit_price, quantity) in enumerate(line_values, 1):
                order_item_id = stable_uuid(
                    "order-item", tenant_number, order_number, item_number
                )
                lines.append(
                    "INSERT INTO app.order_items "
                    "(order_item_id, tenant_id, order_id, product_id, quantity, unit_price) VALUES "
                    f"('{order_item_id}', '{tenant_id}', '{order_id}', "
                    f"'{product_id}', {quantity}, {money(unit_price)});"
                )

            payment_id = stable_uuid("payment", tenant_number, order_number)
            payment_total = subtotal + tax + shipping
            lines.append(
                "INSERT INTO app.payments "
                "(payment_id, tenant_id, order_id, provider_reference, "
                "payment_method, status, amount, processed_at) VALUES "
                f"('{payment_id}', '{tenant_id}', '{order_id}', "
                f"'pay_{tenant_number:02d}_{order_number:06d}', 'card', 'captured', "
                f"{money(payment_total)}, '{(ordered_at + timedelta(minutes=2)).isoformat()}');"
            )

        lines.append("")

    lines.extend(
        [
            "COMMIT;",
            "",
            r"\echo 'Sample SaaS data loaded successfully.'",
            "",
        ]
    )
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tenants", type=int, default=2)
    parser.add_argument("--customers", type=int, default=5, help="customers per tenant")
    parser.add_argument("--products", type=int, default=8, help="products per tenant")
    parser.add_argument("--orders", type=int, default=12, help="orders per tenant")
    parser.add_argument("--seed", type=int, default=20260724)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--force", action="store_true", help="overwrite an existing output")
    args = parser.parse_args()
    for name in ("tenants", "customers", "products", "orders"):
        if getattr(args, name) < 1:
            parser.error(f"--{name} must be at least 1")
    return args


def main() -> None:
    args = parse_args()
    output = args.output.resolve()
    if output.exists() and not args.force:
        raise SystemExit(f"{output} already exists; pass --force to replace it")
    output.parent.mkdir(parents=True, exist_ok=True)
    config = Config(
        tenants=args.tenants,
        customers=args.customers,
        products=args.products,
        orders=args.orders,
        seed=args.seed,
    )
    output.write_text(generate_sql(config), encoding="utf-8", newline="\n")
    print(f"Wrote {output}")


if __name__ == "__main__":
    main()

