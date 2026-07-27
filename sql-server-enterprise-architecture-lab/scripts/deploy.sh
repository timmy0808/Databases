#!/usr/bin/env bash
set -Eeuo pipefail

SERVER="sqlserver"
SA_PASSWORD="${MSSQL_SA_PASSWORD:?MSSQL_SA_PASSWORD is required}"
export DB_NAME="${DB_NAME:-EnterpriseCommerce}"
export APP_LOGIN_PASSWORD="${APP_LOGIN_PASSWORD:?APP_LOGIN_PASSWORD is required}"
export REPORT_LOGIN_PASSWORD="${REPORT_LOGIN_PASSWORD:?REPORT_LOGIN_PASSWORD is required}"

SQLCMD="/opt/mssql-tools18/bin/sqlcmd"
[[ -x "$SQLCMD" ]] || SQLCMD="/opt/mssql-tools/bin/sqlcmd"
[[ -x "$SQLCMD" ]] || { echo "ERROR: sqlcmd was not found in the deployment image." >&2; exit 20; }

sqlcmd_base=("$SQLCMD" -S "$SERVER" -U sa -P "$SA_PASSWORD" -C -I -b -r1)
current_step="initialization"

on_error() {
  rc=$?
  echo >&2
  echo "DEPLOYMENT FAILED" >&2
  echo "Step: ${current_step}" >&2
  echo "Exit code: ${rc}" >&2
  echo "Review the SQL error immediately above this message." >&2
  exit "$rc"
}
trap on_error ERR

run_sql_file() {
  local file="$1"
  current_step="$file"
  echo
  echo "================================================================"
  echo "Applying: $file"
  echo "================================================================"
  "${sqlcmd_base[@]}" -i "$file"
}

echo "Waiting for SQL Server..."
ready=false
for attempt in $(seq 1 60); do
  if "${sqlcmd_base[@]}" -Q "SET NOCOUNT ON; SELECT 1;" >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 2
done

if [[ "$ready" != true ]]; then
  echo "ERROR: SQL Server did not accept a connection after 120 seconds." >&2
  exit 21
fi

# Prove sqlcmd scripting variables are supplied through the environment before
# running migrations. This avoids fragile multi-value -v command arguments.
current_step="SQLCMD variable validation"
validation_file="/tmp/validate_variables.sql"
cat > "$validation_file" <<'SQL'
SET NOCOUNT ON;
IF N'$(DB_NAME)' = N'' THROW 50001, 'DB_NAME was not supplied to sqlcmd.', 1;
IF N'$(APP_LOGIN_PASSWORD)' = N'' THROW 50002, 'APP_LOGIN_PASSWORD was not supplied to sqlcmd.', 1;
IF N'$(REPORT_LOGIN_PASSWORD)' = N'' THROW 50003, 'REPORT_LOGIN_PASSWORD was not supplied to sqlcmd.', 1;
SELECT N'$(DB_NAME)' AS TargetDatabase, CAST('PASS' AS varchar(10)) AS VariableValidation;
GO
SQL
"${sqlcmd_base[@]}" -i "$validation_file"

migration_files=(
  /sql/deployment/00_create_database.sql
  /sql/deployment/01_schemas.sql
  /sql/deployment/02_tables.sql
  /sql/deployment/03_indexes.sql
  /sql/deployment/04_security.sql
  /sql/deployment/05_procedures.sql
  /sql/deployment/06_reporting.sql
  /sql/deployment/07_cdc.sql
  /sql/deployment/08_monitoring.sql
  /sql/deployment/09_backup.sql
  /sql/deployment/10_seed_data.sql
)

for file in "${migration_files[@]}"; do
  run_sql_file "$file"
done

run_sql_file /tests/verify_deployment.sql
run_sql_file /tests/order_workflow_test.sql
run_sql_file /tests/smoke_test.sql

current_step="complete"
echo
echo "================================================================"
echo "DEPLOYMENT COMPLETE AND VERIFIED"
echo "Database: $DB_NAME"
echo "================================================================"
