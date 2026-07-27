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

/*
Run after loading a substantial volume of order-item data.
A nonclustered columnstore index supports analytics while retaining
the rowstore primary key for transactional access.
*/
IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'sales.SalesOrderItem')
      AND name = N'NCCI_SalesOrderItem_Analytics'
)
BEGIN
    CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_SalesOrderItem_Analytics
    ON sales.SalesOrderItem
    (
        SalesOrderId,
        ProductId,
        Quantity,
        UnitPrice,
        LineTotal
    );
END;
GO
