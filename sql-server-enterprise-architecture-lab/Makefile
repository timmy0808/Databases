.PHONY: deploy up down reset logs status verify demo backup

deploy:
	docker compose up -d sqlserver
	docker compose run --rm db-deploy

up: deploy

down:
	docker compose down

reset:
	docker compose down -v
	docker compose up -d sqlserver
	docker compose run --rm db-deploy

logs:
	docker compose logs -f sqlserver

status:
	docker compose ps

verify:
	cat tests/verify_deployment.sql | docker compose exec -T sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$$MSSQL_SA_PASSWORD" -C -I -b

backup:
	docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$$MSSQL_SA_PASSWORD" -C -I -d EnterpriseCommerce -Q "EXEC ops.usp_BackupDatabase;"
