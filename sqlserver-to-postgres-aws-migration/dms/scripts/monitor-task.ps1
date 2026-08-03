param([string]$TerraformDirectory = ".\\terraform")
$ErrorActionPreference = "Stop"
function TfOutput([string]$Name) {
  $chdirArgument = "-chdir=$TerraformDirectory"
  return (& terraform $chdirArgument output -raw $Name).Trim()
}

$taskArn = TfOutput "dms_task_arn"
aws dms describe-replication-tasks --filters Name=replication-task-arn,Values=$taskArn `
  --query "ReplicationTasks[0].{Status:Status,StopReason:StopReason,FullLoadProgress:ReplicationTaskStats.FullLoadProgressPercent,TablesLoaded:ReplicationTaskStats.TablesLoaded,TablesLoading:ReplicationTaskStats.TablesLoading,TablesErrored:ReplicationTaskStats.TablesErrored,Elapsed:ReplicationTaskStats.ElapsedTimeMillis}" `
  --output table
aws dms describe-table-statistics --replication-task-arn $taskArn `
  --query "TableStatistics[].{Schema:SchemaName,Table:TableName,State:TableState,FullLoadRows:FullLoadRows,Inserts:Inserts,Updates:Updates,Deletes:Deletes,Validation:ValidationState,ValidationFailures:ValidationFailedRecords}" `
  --output table
