SET NOCOUNT ON;

IF DB_ID(N'$(DB_NAME)') IS NULL
    THROW 51000, 'Target database is missing.', 1;

USE [$(DB_NAME)];

IF OBJECT_ID(N'sales.SalesOrder', N'U') IS NULL
    THROW 51001, 'sales.SalesOrder is missing.', 1;

IF OBJECT_ID(N'sales.usp_CreateOrder', N'P') IS NULL
    THROW 51002, 'sales.usp_CreateOrder is missing.', 1;

IF NOT EXISTS (SELECT 1 FROM catalog.Product)
    THROW 51003, 'Seed products are missing.', 1;

IF NOT EXISTS (SELECT 1 FROM sys.database_query_store_options WHERE actual_state_desc = 'READ_WRITE')
    THROW 51004, 'Query Store is not read-write.', 1;

SELECT
    DB_NAME() AS DatabaseName,
    @@VERSION AS SqlServerVersion,
    COUNT(*) AS ProductCount
FROM catalog.Product;
GO
