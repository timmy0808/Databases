output "sqlserver_public_ip" { value = aws_instance.sqlserver.public_ip }
output "sqlserver_private_ip" { value = aws_instance.sqlserver.private_ip }
output "postgres_endpoint" { value = aws_db_instance.postgres.address }
output "dms_replication_instance_arn" { value = aws_dms_replication_instance.main.replication_instance_arn }
output "dms_source_endpoint_arn" { value = aws_dms_endpoint.source.endpoint_arn }
output "dms_target_endpoint_arn" { value = aws_dms_endpoint.target.endpoint_arn }
output "dms_task_arn" { value = aws_dms_replication_task.main.replication_task_arn }
output "ssh_tunnel_command" {
  value = "ssh -i <key.pem> -L 5433:${aws_db_instance.postgres.address}:5432 ubuntu@${aws_instance.sqlserver.public_ip}"
}
