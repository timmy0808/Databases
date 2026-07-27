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

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Customer_Email')
    CREATE UNIQUE INDEX IX_Customer_Email ON sales.Customer(Email);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesOrder_Customer_OrderDate')
    CREATE INDEX IX_SalesOrder_Customer_OrderDate
    ON sales.SalesOrder(CustomerId, OrderDate DESC)
    INCLUDE (OrderStatus, TotalAmount, WarehouseId);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesOrder_Status_Date')
    CREATE INDEX IX_SalesOrder_Status_Date
    ON sales.SalesOrder(OrderStatus, OrderDate)
    INCLUDE (CustomerId, TotalAmount);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_OrderItem_Product')
    CREATE INDEX IX_OrderItem_Product
    ON sales.SalesOrderItem(ProductId)
    INCLUDE (SalesOrderId, Quantity, UnitPrice, LineTotal);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_EventLog_EventTime')
    CREATE INDEX IX_EventLog_EventTime
    ON audit.EventLog(EventTime DESC)
    INCLUDE (EventType, EntityName, LoginName);
GO
