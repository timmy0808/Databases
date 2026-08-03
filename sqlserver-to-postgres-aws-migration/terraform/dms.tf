resource "aws_dms_replication_subnet_group" "main" {
  replication_subnet_group_description = "${local.name} DMS subnets"
  replication_subnet_group_id          = "${local.name}-dms"
  subnet_ids                           = [aws_subnet.a.id, aws_subnet.b.id]

  depends_on = [aws_iam_role_policy_attachment.dms_vpc]
}
resource "aws_dms_replication_instance" "main" {
  replication_instance_id     = "${local.name}-dms"
  replication_instance_class  = var.dms_instance_class
  allocated_storage           = 100
  apply_immediately           = true
  auto_minor_version_upgrade  = true
  multi_az                    = false
  publicly_accessible         = false
  replication_subnet_group_id = aws_dms_replication_subnet_group.main.id
  vpc_security_group_ids      = [aws_security_group.dms.id]
  kms_key_arn                 = aws_kms_key.data.arn
}
resource "aws_dms_endpoint" "source" {
  endpoint_id                 = "${local.name}-sqlserver-source"
  endpoint_type               = "source"
  engine_name                 = "sqlserver"
  server_name                 = aws_instance.sqlserver.private_ip
  port                        = 1433
  database_name               = "TransplantDiagnostics"
  username                    = "sa"
  password                    = var.sqlserver_password
  ssl_mode                    = "none"
  extra_connection_attributes = "SetUpMsCdcForTables=true"
}
resource "aws_dms_endpoint" "target" {
  endpoint_id                 = "${local.name}-postgres-target"
  endpoint_type               = "target"
  engine_name                 = "postgres"
  server_name                 = aws_db_instance.postgres.address
  port                        = 5432
  database_name               = aws_db_instance.postgres.db_name
  username                    = aws_db_instance.postgres.username
  password                    = var.postgres_password
  ssl_mode                    = "require"
  extra_connection_attributes = "afterConnectScript=SET session_replication_role='replica'"
}
resource "aws_dms_replication_task" "main" {
  replication_task_id       = "${local.name}-full-load-cdc"
  migration_type            = "full-load-and-cdc"
  replication_instance_arn  = aws_dms_replication_instance.main.replication_instance_arn
  source_endpoint_arn       = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn       = aws_dms_endpoint.target.endpoint_arn
  table_mappings            = file("${path.module}/../dms/tasks/table-mappings.json")
  replication_task_settings = file("${path.module}/../dms/tasks/task-settings.json")
  depends_on = [
    aws_db_instance.postgres,
    aws_iam_role_policy_attachment.dms_cloudwatch_logs,
    aws_instance.sqlserver,
  ]
}
