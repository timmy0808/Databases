resource "aws_db_subnet_group" "postgres" {
  name       = "${local.name}-postgres"
  subnet_ids = [aws_subnet.a.id, aws_subnet.b.id]
}
resource "aws_db_parameter_group" "postgres" {
  name   = "${local.name}-postgres16"
  family = "postgres16"
  parameter {
    name  = "log_connections"
    value = "1"
  }
  parameter {
    name  = "log_disconnections"
    value = "1"
  }
}
resource "aws_db_instance" "postgres" {
  identifier                      = "${local.name}-postgres"
  engine                          = "postgres"
  engine_version                  = var.postgres_engine_version
  instance_class                  = var.postgres_instance_class
  allocated_storage               = var.postgres_allocated_storage
  max_allocated_storage           = 200
  storage_type                    = "gp3"
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.data.arn
  db_name                         = "transplant_diagnostics"
  username                        = "postgres"
  password                        = var.postgres_password
  port                            = 5432
  multi_az                        = var.multi_az
  publicly_accessible             = false
  db_subnet_group_name            = aws_db_subnet_group.postgres.name
  vpc_security_group_ids          = [aws_security_group.postgres.id]
  parameter_group_name            = aws_db_parameter_group.postgres.name
  backup_retention_period         = 7
  deletion_protection             = false
  skip_final_snapshot             = true
  apply_immediately               = true
  performance_insights_enabled    = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
}
