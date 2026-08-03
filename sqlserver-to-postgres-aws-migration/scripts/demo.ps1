$ErrorActionPreference = "Stop"
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
docker compose up -d
Write-Host "After both databases are healthy, run:"
Write-Host "  py scripts/bootstrap.py"
Write-Host "  py -m generator.generate_data --cases 100 --results 5000"
Write-Host "  py -m migration.full_load"
Write-Host "  py -m validation.run_validation"
Write-Host "Then add/update SQL Server rows and run: py -m migration.cdc_worker --once"
