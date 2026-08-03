param([string]$TerraformDirectory = ".\\terraform")
$ErrorActionPreference = "Stop"
function TfOutput([string]$Name) {
  $chdirArgument = "-chdir=$TerraformDirectory"
  return (& terraform $chdirArgument output -raw $Name).Trim()
}

$taskArn = TfOutput "dms_task_arn"
aws dms stop-replication-task --replication-task-arn $taskArn
