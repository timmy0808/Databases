# Changelog

## 3.1.0

- Corrected password validation from a project-specific 12-character minimum to SQL Server-compatible 8-character minimum.
- Kept uppercase, lowercase, number, and special-character validation.
- Updated validation messages, example environment values, and documentation.
- Confirmed the previous malformed multi-value `sqlcmd -v` pattern is absent.

## 3.0.0

- Rebuilt the deployment layer around one root `deploy.ps1` command.
- Replaced fragile multi-variable `sqlcmd -v` invocation with SQLCMD environment variables.
- Added explicit SQLCMD variable validation before migrations.
- Added `-Reset` for intentional clean initialization.
- Added per-migration progress output and failure-step reporting.
- Added timestamped deployment logs.
- Updated all tests to honor `DB_NAME`.
- Removed the separate first-time deployment script.
- Expanded first-time deployment and DBeaver documentation.

