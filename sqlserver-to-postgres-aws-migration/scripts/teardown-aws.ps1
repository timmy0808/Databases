[CmdletBinding()]
param(
  [string]$TerraformDirectory = (Join-Path $PSScriptRoot "..\terraform"),
  [switch]$AutoApprove
)

$ErrorActionPreference = "Stop"

$terraformPath = (Resolve-Path -LiteralPath $TerraformDirectory).Path
$statePath = Join-Path $terraformPath "terraform.tfstate"

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
  throw "Terraform is not installed or is not available on PATH."
}

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
  throw "AWS CLI is not installed or is not available on PATH."
}

if (-not (Test-Path -LiteralPath $statePath)) {
  throw "Terraform state was not found at $statePath. Refusing to run because the script cannot identify the managed AWS resources."
}

$identity = aws sts get-caller-identity --output json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) {
  throw "Unable to read the current AWS identity. Check AWS CLI authentication."
}

Push-Location $terraformPath
try {
  $resources = @(terraform state list)
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to read Terraform state."
  }

  if ($resources.Count -eq 0) {
    Write-Host "Terraform state contains no managed resources. Nothing to destroy."
    return
  }

  Write-Host "AWS account: $($identity.Account)"
  Write-Host "AWS identity: $($identity.Arn)"
  Write-Host "Terraform directory: $terraformPath"
  Write-Host "Managed resources scheduled for destruction: $($resources.Count)"
  $resources | ForEach-Object { Write-Host "  - $_" }

  if (-not $AutoApprove) {
    Write-Warning "This destroys the AWS resources managed by this Terraform state, including EC2, RDS, DMS, KMS, Secrets Manager, networking, logs-related configuration, and alarms."
    $confirmation = Read-Host "Type DESTROY to continue"
    if ($confirmation -cne "DESTROY") {
      Write-Host "Teardown cancelled. No resources were destroyed."
      return
    }
  }

  $destroyArguments = @("destroy", "-input=false")
  if ($AutoApprove) {
    $destroyArguments += "-auto-approve"
  }

  & terraform @destroyArguments
  if ($LASTEXITCODE -ne 0) {
    throw "Terraform destroy failed. Review the output and rerun the script; Terraform will continue from the remaining state."
  }

  Write-Host "Terraform teardown completed successfully."
  Write-Host "The pre-existing EC2 key pair and local files were not deleted because Terraform does not manage them."
}
finally {
  Pop-Location
}
