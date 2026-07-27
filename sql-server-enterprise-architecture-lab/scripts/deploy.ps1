[CmdletBinding()]
param(
    [switch]$Reset
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot
$LogDirectory = Join-Path $ProjectRoot "logs"
New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
$LogFile = Join-Path $LogDirectory ("deployment-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

function Invoke-Docker {
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [switch]$AllowFailure
    )

    & docker @Arguments
    $exitCode = $LASTEXITCODE

    if (-not $AllowFailure -and $exitCode -ne 0) {
        throw "Docker command failed: docker $($Arguments -join ' ')"
    }

    return $exitCode
}

function Get-EnvValues {
    param([Parameter(Mandatory)][string]$Path)

    $values = @{}
    foreach ($rawLine in Get-Content $Path) {
        $line = $rawLine.Trim()
        if (-not $line -or $line.StartsWith("#")) { continue }
        $parts = $line.Split("=", 2)
        if ($parts.Count -eq 2) {
            $values[$parts[0].Trim()] = $parts[1].Trim()
        }
    }
    return $values
}

function Assert-StrongPassword {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )

    if ($Value.Length -lt 8 -or
        $Value -notmatch '[A-Z]' -or
        $Value -notmatch '[a-z]' -or
        $Value -notmatch '\d' -or
        $Value -notmatch '[^A-Za-z0-9]') {
        throw "$Name must be at least 8 characters and contain uppercase, lowercase, a number, and a special character."
    }

    if ($Value.Contains('"')) {
        throw "$Name cannot contain a double-quote character because Docker Compose env-file parsing is ambiguous for that value."
    }
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker is not installed or is not available in PATH."
}

& docker info *> $null
if ($LASTEXITCODE -ne 0) {
    throw "Docker Desktop is not running or the Docker engine is unavailable."
}

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Created .env from .env.example." -ForegroundColor Yellow
    Write-Host "Edit the three passwords in .env, then rerun .\deploy.ps1."
    exit 2
}

$envValues = Get-EnvValues -Path ".env"
$required = @("MSSQL_SA_PASSWORD", "APP_LOGIN_PASSWORD", "REPORT_LOGIN_PASSWORD")
foreach ($name in $required) {
    if (-not $envValues.ContainsKey($name) -or [string]::IsNullOrWhiteSpace($envValues[$name])) {
        throw "$name is missing from .env."
    }
    Assert-StrongPassword -Name $name -Value $envValues[$name]
}

$examplePasswords = @(
    "ChangeThis!123",
    "ChangeApp!123",
    "ChangeReport!123"
)
foreach ($password in $examplePasswords) {
    if ($envValues.Values -contains $password) {
        throw "Replace all example passwords in .env before deployment."
    }
}

if ($Reset) {
    Write-Warning "RESET removes the EnterpriseCommerce container volume and all lab data."
    Invoke-Docker -Arguments @("compose", "down", "--volumes", "--remove-orphans") -AllowFailure | Out-Null

    foreach ($container in @("enterprisecommerce-sqlserver", "enterprisecommerce-deploy")) {
        $exists = & docker ps -a --filter "name=^/$container$" --format "{{.Names}}"
        if ($exists -eq $container) {
            Invoke-Docker -Arguments @("rm", "-f", $container) | Out-Null
        }
    }

    $volume = & docker volume ls --filter "name=^enterprisecommerce-sqlserver-data$" --format "{{.Name}}"
    if ($volume -eq "enterprisecommerce-sqlserver-data") {
        Invoke-Docker -Arguments @("volume", "rm", "enterprisecommerce-sqlserver-data") | Out-Null
    }
}

Write-Host "Starting SQL Server..." -ForegroundColor Cyan
Invoke-Docker -Arguments @("compose", "up", "-d", "sqlserver") | Out-Null

Write-Host "Waiting for SQL Server health check..." -ForegroundColor Cyan
$healthy = $false
for ($attempt = 1; $attempt -le 60; $attempt++) {
    $status = & docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' enterprisecommerce-sqlserver 2>$null
    if ($status -eq "healthy") {
        $healthy = $true
        break
    }
    if ($status -in @("unhealthy", "exited", "dead")) {
        & docker compose logs --tail 150 sqlserver
        throw "SQL Server entered status '$status'."
    }
    Start-Sleep -Seconds 2
}

if (-not $healthy) {
    & docker compose logs --tail 150 sqlserver
    throw "SQL Server did not become healthy."
}

Write-Host "Applying and verifying database migrations..." -ForegroundColor Cyan
Write-Host "Deployment log: $LogFile"

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"

& docker compose run --rm --no-deps db-deploy 2>&1 |
    Tee-Object -FilePath $logFile

$deployExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference

if ($deployExitCode -ne 0) {
    Write-Host ""
    Write-Host "Database deployment failed. Review the log:"
    Write-Host $logFile
    throw "Database deployment failed with exit code $deployExitCode."
}
$deploymentExitCode = $LASTEXITCODE

if ($deploymentExitCode -ne 0) {
    Write-Host "" 
    Write-Host "Database deployment failed. Review:" -ForegroundColor Red
    Write-Host $LogFile -ForegroundColor Yellow
    throw "Database deployment failed with exit code $deploymentExitCode."
}

Write-Host "" 
Write-Host "SQL Server lab deployed successfully." -ForegroundColor Green
& docker compose ps
Write-Host "" 
Write-Host "Connection:" -ForegroundColor Cyan
Write-Host "  Host: localhost"
$port = if ($envValues.ContainsKey('MSSQL_PORT')) { $envValues['MSSQL_PORT'] } else { '1433' }
$databaseName = if ($envValues.ContainsKey('DB_NAME')) { $envValues['DB_NAME'] } else { 'EnterpriseCommerce' }
Write-Host "  Port: $port"
Write-Host "  Database: $databaseName"
Write-Host "  User: sa"
Write-Host "  Encrypt: true"
Write-Host "  Trust server certificate: true"
