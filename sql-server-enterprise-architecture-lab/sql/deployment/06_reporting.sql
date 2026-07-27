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

CREATE OR ALTER VIEW reporting.vw_OrderSummary
AS
SELECT
    o.SalesOrderId,
    o.OrderNumber,
    o.OrderDate,
    o.OrderStatus,
    c.CustomerNumber,
    CONCAT(c.FirstName, N' ', c.LastName) AS CustomerName,
    w.WarehouseCode,
    o.Subtotal,
    o.TaxAmount,
    o.TotalAmount
FROM sales.SalesOrder o
JOIN sales.Customer c ON c.CustomerId = o.CustomerId
JOIN inventory.Warehouse w ON w.WarehouseId = o.WarehouseId;
GO

CREATE OR ALTER VIEW reporting.vw_InventoryAvailability
AS
SELECT
    w.WarehouseCode,
    p.SKU,
    p.ProductName,
    s.QuantityOnHand,
    s.QuantityReserved,
    s.QuantityOnHand - s.QuantityReserved AS QuantityAvailable
FROM inventory.Stock s
JOIN inventory.Warehouse w ON w.WarehouseId = s.WarehouseId
JOIN catalog.Product p ON p.ProductId = s.ProductId;
GO
