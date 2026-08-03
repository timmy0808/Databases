resource "aws_cloudwatch_metric_alarm" "source_latency" {
  alarm_name          = "${local.name}-dms-source-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CDCLatencySource"
  namespace           = "AWS/DMS"
  period              = 300
  statistic           = "Average"
  threshold           = 300
  alarm_description   = "DMS source CDC latency exceeds five minutes"
  dimensions          = { ReplicationInstanceIdentifier = aws_dms_replication_instance.main.replication_instance_id, ReplicationTaskIdentifier = aws_dms_replication_task.main.replication_task_id }
}
resource "aws_cloudwatch_metric_alarm" "target_latency" {
  alarm_name          = "${local.name}-dms-target-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CDCLatencyTarget"
  namespace           = "AWS/DMS"
  period              = 300
  statistic           = "Average"
  threshold           = 300
  alarm_description   = "DMS target CDC latency exceeds five minutes"
  dimensions          = { ReplicationInstanceIdentifier = aws_dms_replication_instance.main.replication_instance_id, ReplicationTaskIdentifier = aws_dms_replication_task.main.replication_task_id }
}
