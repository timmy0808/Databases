param([string]$TerraformDirectory = ".\\terraform")
$ErrorActionPreference = "Stop"
function TfOutput([string]$Name) {
  $chdirArgument = "-chdir=$TerraformDirectory"
  return (& terraform $chdirArgument output -raw $Name).Trim()
}

$taskArn = TfOutput "dms_task_arn"
$bucket = Read-Host "S3 bucket name for the premigration assessment report"
$roleArn = Read-Host "IAM role ARN that grants DMS write access to that bucket"
aws dms start-replication-task-assessment-run `
  --replication-task-arn $taskArn `
  --service-access-role-arn $roleArn `
  --result-location-bucket $bucket `
  --assessment-run-name "transplant-dms-$(Get-Date -Format yyyyMMddHHmmss)"
