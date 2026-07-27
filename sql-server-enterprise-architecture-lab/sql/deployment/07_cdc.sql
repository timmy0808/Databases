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

IF EXISTS (SELECT 1 FROM sys.databases WHERE database_id = DB_ID() AND is_cdc_enabled = 0)
BEGIN
    EXEC sys.sp_cdc_enable_db;
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM cdc.change_tables
    WHERE source_object_id = OBJECT_ID(N'sales.SalesOrder')
)
BEGIN
    EXEC sys.sp_cdc_enable_table
        @source_schema = N'sales',
        @source_name = N'SalesOrder',
        @role_name = NULL,
        @supports_net_changes = 1;
END;
GO
