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

IF NOT EXISTS (SELECT 1 FROM inventory.Warehouse)
BEGIN
    INSERT inventory.Warehouse(WarehouseCode, WarehouseName, RegionCode)
    VALUES
        ('SLC-01', N'Salt Lake Distribution Center', 'WEST'),
        ('DFW-01', N'Dallas Distribution Center', 'CENTRAL');
END;

IF NOT EXISTS (SELECT 1 FROM catalog.Product)
BEGIN
    INSERT catalog.Product(SKU, ProductName, UnitPrice)
    VALUES
        ('LAPTOP-001', N'Enterprise Laptop', 1499.00),
        ('MONITOR-001', N'27-inch Monitor', 399.00),
        ('DOCK-001', N'USB-C Dock', 179.00),
        ('KEYBOARD-001', N'Mechanical Keyboard', 129.00);
END;

IF NOT EXISTS (SELECT 1 FROM sales.Customer)
BEGIN
    INSERT sales.Customer
    (
        CustomerNumber, FirstName, LastName, Email, Phone, Status
    )
    VALUES
        ('CUST-1001', N'Avery', N'Johnson', N'avery@example.com', '801-555-0101', 'Active'),
        ('CUST-1002', N'Jordan', N'Lee', N'jordan@example.com', '214-555-0102', 'Active');
END;

IF NOT EXISTS (SELECT 1 FROM inventory.Stock)
BEGIN
    INSERT inventory.Stock(WarehouseId, ProductId, QuantityOnHand, QuantityReserved)
    SELECT w.WarehouseId, p.ProductId, 100, 0
    FROM inventory.Warehouse w
    CROSS JOIN catalog.Product p;
END;
GO
