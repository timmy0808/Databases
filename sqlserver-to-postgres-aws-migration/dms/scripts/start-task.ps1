param(
  [string]$TerraformDirectory = ".\\terraform",
  [ValidateSet("start-replication", "resume-processing", "reload-target")]
  [string]$StartType = "start-replication"
)
$ErrorActionPreference = "Stop"
function TfOutput([string]$Name) {
  $chdirArgument = "-chdir=$TerraformDirectory"
  return (& terraform $chdirArgument output -raw $Name).Trim()
}

$taskArn = TfOutput "dms_task_arn"
aws dms start-replication-task --replication-task-arn $taskArn --start-replication-task-type $StartType
