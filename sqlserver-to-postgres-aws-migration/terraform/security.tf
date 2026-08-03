resource "aws_kms_key" "data" {
  description             = "${local.name} lab data encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}
resource "aws_kms_alias" "data" {
  name          = "alias/${local.name}-data"
  target_key_id = aws_kms_key.data.key_id
}

resource "aws_secretsmanager_secret" "sqlserver" {
  name       = "${local.name}/sqlserver"
  kms_key_id = aws_kms_key.data.arn
}
resource "aws_secretsmanager_secret_version" "sqlserver" {
  secret_id     = aws_secretsmanager_secret.sqlserver.id
  secret_string = jsonencode({ username = "sa", password = var.sqlserver_password, database = "TransplantDiagnostics", port = 1433 })
}
resource "aws_secretsmanager_secret" "postgres" {
  name       = "${local.name}/postgres"
  kms_key_id = aws_kms_key.data.arn
}
resource "aws_secretsmanager_secret_version" "postgres" {
  secret_id     = aws_secretsmanager_secret.postgres.id
  secret_string = jsonencode({ username = "postgres", password = var.postgres_password, database = "transplant_diagnostics", port = 5432 })
}
