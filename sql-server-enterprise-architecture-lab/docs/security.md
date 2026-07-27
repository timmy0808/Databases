# Security Model

## Principals

- `enterprise_app`: application login with membership in `app_executor`.
- `enterprise_report`: reporting login with membership in `report_reader`.
- `app_executor`: executes approved procedures and reads product catalog data.
- `report_reader`: reads curated reporting views, not finance or audit schemas.

The application should call stored procedures rather than receive broad table
permissions. Production credentials belong in a secret manager, never in source
control. The `sa` account is used only for lab deployment and administration.

## Local login examples

Application:

```text
Server: localhost,1433
Database: EnterpriseCommerce
User: enterprise_app
Password: value of APP_LOGIN_PASSWORD
Trust server certificate: true
```

Reporting:

```text
Server: localhost,1433
Database: EnterpriseCommerce
User: enterprise_report
Password: value of REPORT_LOGIN_PASSWORD
Trust server certificate: true
```
