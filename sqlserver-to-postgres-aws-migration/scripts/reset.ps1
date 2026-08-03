docker compose down -v
Remove-Item .env -ErrorAction SilentlyContinue
Write-Host "Environment removed."
