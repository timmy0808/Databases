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

CREATE OR ALTER PROCEDURE sales.usp_CreateOrder
    @CustomerId bigint,
    @WarehouseId int,
    @Items nvarchar(max),
    @CorrelationId uniqueidentifier = NULL,
    @SalesOrderId bigint = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF ISJSON(@Items) <> 1
        THROW 50001, 'Items must be valid JSON.', 1;

    DECLARE @OrderNumber varchar(30) =
        CONCAT('SO-', FORMAT(SYSUTCDATETIME(), 'yyyyMMddHHmmssfff'));

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT sales.SalesOrder
        (
            OrderNumber, CustomerId, WarehouseId, OrderStatus
        )
        VALUES
        (
            @OrderNumber, @CustomerId, @WarehouseId, 'Pending'
        );

        SET @SalesOrderId = SCOPE_IDENTITY();

        DECLARE @ParsedItems table
        (
            ProductId bigint PRIMARY KEY,
            Quantity int NOT NULL
        );

        INSERT @ParsedItems(ProductId, Quantity)
        SELECT ProductId, Quantity
        FROM OPENJSON(@Items)
        WITH
        (
            ProductId bigint '$.productId',
            Quantity int '$.quantity'
        );

        IF NOT EXISTS (SELECT 1 FROM @ParsedItems)
            THROW 50002, 'At least one order item is required.', 1;

        IF EXISTS (SELECT 1 FROM @ParsedItems WHERE Quantity <= 0)
            THROW 50003, 'Item quantities must be positive.', 1;

        IF EXISTS
        (
            SELECT 1
            FROM @ParsedItems i
            LEFT JOIN inventory.Stock s WITH (UPDLOCK, HOLDLOCK)
              ON s.ProductId = i.ProductId
             AND s.WarehouseId = @WarehouseId
            WHERE s.ProductId IS NULL
               OR s.QuantityOnHand - s.QuantityReserved < i.Quantity
        )
            THROW 50004, 'Insufficient inventory.', 1;

        INSERT sales.SalesOrderItem
        (
            SalesOrderId, ProductId, Quantity, UnitPrice
        )
        SELECT
            @SalesOrderId, p.ProductId, i.Quantity, p.UnitPrice
        FROM @ParsedItems i
        JOIN catalog.Product p ON p.ProductId = i.ProductId
        WHERE p.IsActive = 1;

        UPDATE s
        SET QuantityReserved = s.QuantityReserved + i.Quantity
        FROM inventory.Stock s
        JOIN @ParsedItems i ON i.ProductId = s.ProductId
        WHERE s.WarehouseId = @WarehouseId;

        UPDATE o
        SET Subtotal = x.Subtotal,
            TaxAmount = ROUND(x.Subtotal * 0.0725, 2),
            OrderStatus = 'Confirmed'
        FROM sales.SalesOrder o
        CROSS APPLY
        (
            SELECT SUM(LineTotal) AS Subtotal
            FROM sales.SalesOrderItem oi
            WHERE oi.SalesOrderId = o.SalesOrderId
        ) x
        WHERE o.SalesOrderId = @SalesOrderId;

        INSERT audit.EventLog
        (
            LoginName, ApplicationName, EventType,
            EntityName, EntityId, Details, CorrelationId
        )
        VALUES
        (
            ORIGINAL_LOGIN(), APP_NAME(), 'OrderCreated',
            'sales.SalesOrder', CONVERT(varchar(100), @SalesOrderId),
            @Items, @CorrelationId
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE sales.usp_CancelOrder
    @SalesOrderId bigint,
    @Reason nvarchar(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM sales.SalesOrder WITH (UPDLOCK, HOLDLOCK)
            WHERE SalesOrderId = @SalesOrderId
              AND OrderStatus IN ('Pending','Confirmed','Paid')
        )
            THROW 50010, 'Order cannot be cancelled.', 1;

        UPDATE s
        SET QuantityReserved = s.QuantityReserved - oi.Quantity
        FROM inventory.Stock s
        JOIN sales.SalesOrder o
          ON o.WarehouseId = s.WarehouseId
        JOIN sales.SalesOrderItem oi
          ON oi.SalesOrderId = o.SalesOrderId
         AND oi.ProductId = s.ProductId
        WHERE o.SalesOrderId = @SalesOrderId;

        UPDATE sales.SalesOrder
        SET OrderStatus = 'Cancelled'
        WHERE SalesOrderId = @SalesOrderId;

        INSERT audit.EventLog
        (
            LoginName, ApplicationName, EventType,
            EntityName, EntityId, Details
        )
        VALUES
        (
            ORIGINAL_LOGIN(), APP_NAME(), 'OrderCancelled',
            'sales.SalesOrder', CONVERT(varchar(100), @SalesOrderId), @Reason
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
