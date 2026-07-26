from __future__ import annotations

import unittest

from src import generate_data


class GenerateDataTests(unittest.TestCase):
    def test_generation_is_deterministic(self) -> None:
        config = generate_data.Config(
            tenants=2, customers=2, products=3, orders=4, seed=42
        )
        self.assertEqual(
            generate_data.generate_sql(config), generate_data.generate_sql(config)
        )

    def test_generation_contains_all_core_entities(self) -> None:
        sql = generate_data.generate_sql(
            generate_data.Config(
                tenants=1, customers=1, products=2, orders=1, seed=42
            )
        )
        for table in (
            "app.tenants",
            "app.users",
            "app.customers",
            "app.products",
            "app.orders",
            "app.order_items",
            "app.payments",
        ):
            with self.subTest(table=table):
                self.assertIn(f"INSERT INTO {table}", sql)

    def test_generated_script_is_transactional(self) -> None:
        sql = generate_data.generate_sql(
            generate_data.Config(
                tenants=1, customers=1, products=2, orders=1, seed=7
            )
        )
        self.assertNotIn("GENERATED ALWAYS", sql)
        self.assertIn("BEGIN;", sql)
        self.assertIn("COMMIT;", sql)


if __name__ == "__main__":
    unittest.main()
