SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO

USE [$(DB_NAME)];
GO

BEGIN TRANSACTION;

BEGIN TRY
    DECLARE @CustomerId bigint =
    (
        SELECT CustomerId FROM sales.Customer WHERE CustomerNumber = 'CUST-1001'
    );
    DECLARE @WarehouseId int =
    (
        SELECT WarehouseId FROM inventory.Warehouse WHERE WarehouseCode = 'SLC-01'
    );
    DECLARE @Product1 bigint =
    (
        SELECT ProductId FROM catalog.Product WHERE SKU = 'LAPTOP-001'
    );
    DECLARE @Product2 bigint =
    (
        SELECT ProductId FROM catalog.Product WHERE SKU = 'DOCK-001'
    );
    DECLARE @Items nvarchar(max) = CONCAT(
        '[{"productId":', @Product1, ',"quantity":1},',
        '{"productId":', @Product2, ',"quantity":2}]'
    );
    DECLARE @SalesOrderId bigint;

    EXEC sales.usp_CreateOrder
        @CustomerId = @CustomerId,
        @WarehouseId = @WarehouseId,
        @Items = @Items,
        @CorrelationId = NULL,
        @SalesOrderId = @SalesOrderId OUTPUT;

    IF @SalesOrderId IS NULL THROW 51100, 'Order procedure returned no ID.', 1;
    IF NOT EXISTS (SELECT 1 FROM sales.SalesOrder WHERE SalesOrderId = @SalesOrderId AND OrderStatus = 'Confirmed')
        THROW 51101, 'Confirmed order was not created.', 1;
    IF (SELECT COUNT(*) FROM sales.SalesOrderItem WHERE SalesOrderId = @SalesOrderId) <> 2
        THROW 51102, 'Expected two order items.', 1;
    IF NOT EXISTS (SELECT 1 FROM audit.EventLog WHERE EntityId = CONVERT(varchar(100), @SalesOrderId) AND EventType = 'OrderCreated')
        THROW 51103, 'Order audit event was not created.', 1;

    SELECT @SalesOrderId AS TestedSalesOrderId, CAST('PASS' AS varchar(10)) AS OrderWorkflowStatus;
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
