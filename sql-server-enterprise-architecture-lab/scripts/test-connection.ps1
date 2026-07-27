$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

if (-not (Test-Path ".env")) {
    throw ".env was not found."
}

$envValues = @{}

Get-Content ".env" | ForEach-Object {
    $line = $_.Trim()

    if ($line -and -not $line.StartsWith("#")) {
        $parts = $line -split "=", 2

        if ($parts.Count -eq 2) {
            $envValues[$parts[0].Trim()] = $parts[1].Trim()
        }
    }
}

$dbName = $envValues["DB_NAME"]
$saPassword = $envValues["MSSQL_SA_PASSWORD"]

if ([string]::IsNullOrWhiteSpace($dbName)) {
    throw "DB_NAME is missing from .env."
}

if ([string]::IsNullOrWhiteSpace($saPassword)) {
    throw "MSSQL_SA_PASSWORD is missing from .env."
}

$containerName = "enterprisecommerce-sqlserver"

$containerStatus = docker inspect `
    --format "{{.State.Health.Status}}" `
    $containerName 2>$null

if ($LASTEXITCODE -ne 0) {
    throw "The SQL Server container '$containerName' was not found."
}

if ($containerStatus -ne "healthy") {
    throw "SQL Server is not healthy. Current status: $containerStatus"
}

$query = @"
SET NOCOUNT ON;

IF DB_ID(N'$dbName') IS NULL
BEGIN
    RAISERROR('Database $dbName does not exist.', 16, 1);
END;

SELECT
    @@SERVERNAME AS server_name,
    DB_NAME() AS database_name,
    SUSER_SNAME() AS login_name,
    'PASS' AS connection_status;
"@

docker exec `
    -e SQLCMDPASSWORD="$saPassword" `
    $containerName `
    /opt/mssql-tools18/bin/sqlcmd `
    -S localhost `
    -U sa `
    -d $dbName `
    -C `
    -b `
    -Q $query

if ($LASTEXITCODE -ne 0) {
    throw "SQL Server connection test failed."
}

Write-Host ""
Write-Host "SQL Server connection test passed."