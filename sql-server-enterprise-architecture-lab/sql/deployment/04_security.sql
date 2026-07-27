SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO

USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'enterprise_app')
BEGIN
    DECLARE @sql nvarchar(max) =
        N'CREATE LOGIN enterprise_app WITH PASSWORD = ' +
        QUOTENAME(N'$(APP_LOGIN_PASSWORD)', '''') +
        N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;';
    EXEC sys.sp_executesql @sql;
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'enterprise_report')
BEGIN
    DECLARE @sql nvarchar(max) =
        N'CREATE LOGIN enterprise_report WITH PASSWORD = ' +
        QUOTENAME(N'$(REPORT_LOGIN_PASSWORD)', '''') +
        N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;';
    EXEC sys.sp_executesql @sql;
END;
GO

USE [$(DB_NAME)];
GO


SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'enterprise_app')
    CREATE USER enterprise_app FOR LOGIN enterprise_app;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'enterprise_report')
    CREATE USER enterprise_report FOR LOGIN enterprise_report;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'app_executor')
    CREATE ROLE app_executor;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'report_reader')
    CREATE ROLE report_reader;

ALTER ROLE app_executor ADD MEMBER enterprise_app;
ALTER ROLE report_reader ADD MEMBER enterprise_report;

GRANT EXECUTE ON SCHEMA::sales TO app_executor;
GRANT EXECUTE ON SCHEMA::inventory TO app_executor;
GRANT SELECT ON SCHEMA::catalog TO app_executor;

GRANT SELECT ON SCHEMA::reporting TO report_reader;
DENY SELECT ON SCHEMA::finance TO report_reader;
DENY SELECT ON SCHEMA::audit TO report_reader;
GO
