param([string]$TerraformDirectory = ".\\terraform")
$ErrorActionPreference = "Stop"
function TfOutput([string]$Name) {
  $chdirArgument = "-chdir=$TerraformDirectory"
  return (& terraform $chdirArgument output -raw $Name).Trim()
}

$replicationArn = TfOutput "dms_replication_instance_arn"
$sourceArn = TfOutput "dms_source_endpoint_arn"
$targetArn = TfOutput "dms_target_endpoint_arn"

foreach ($endpoint in @($sourceArn, $targetArn)) {
  aws dms test-connection --replication-instance-arn $replicationArn --endpoint-arn $endpoint | Out-Null
}

Write-Host "Endpoint tests started. Waiting for completion..."
do {
  Start-Sleep -Seconds 10
  $result = aws dms describe-connections --filters Name=replication-instance-arn,Values=$replicationArn | ConvertFrom-Json
  $result.Connections | Select-Object EndpointIdentifier, Status, LastFailureMessage | Format-Table -AutoSize
  $pending = @($result.Connections | Where-Object { $_.Status -in @("testing", "deleting") }).Count
} while ($pending -gt 0)

if (@($result.Connections | Where-Object Status -ne "successful").Count -gt 0) { throw "One or more endpoint tests failed." }
