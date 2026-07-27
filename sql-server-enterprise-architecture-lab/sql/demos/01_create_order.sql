/*
DBeaver-safe demo: execute this file as one statement.
The outer sp_executesql call prevents the editor from splitting local variables
into separate SQL Server batches.
*/
EXEC sys.sp_executesql N'
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;

USE EnterpriseCommerce;

DECLARE @CustomerId bigint =
(
    SELECT CustomerId
    FROM sales.Customer
    WHERE CustomerNumber = ''CUST-1001''
);

DECLARE @WarehouseId int =
(
    SELECT WarehouseId
    FROM inventory.Warehouse
    WHERE WarehouseCode = ''SLC-01''
);

DECLARE @Product1 bigint =
(
    SELECT ProductId
    FROM catalog.Product
    WHERE SKU = ''LAPTOP-001''
);

DECLARE @Product2 bigint =
(
    SELECT ProductId
    FROM catalog.Product
    WHERE SKU = ''DOCK-001''
);

IF @CustomerId IS NULL OR @WarehouseId IS NULL OR @Product1 IS NULL OR @Product2 IS NULL
    THROW 52000, ''Required seed data is missing. Run the deployment first.'', 1;

DECLARE @Items nvarchar(max) = CONCAT(
    ''[{"productId":'', @Product1, '',"quantity":1},'',
    ''{"productId":'', @Product2, '',"quantity":2}]''
);
DECLARE @SalesOrderId bigint;

EXEC sales.usp_CreateOrder
    @CustomerId = @CustomerId,
    @WarehouseId = @WarehouseId,
    @Items = @Items,
    @CorrelationId = NULL,
    @SalesOrderId = @SalesOrderId OUTPUT;

SELECT @SalesOrderId AS CreatedSalesOrderId;
SELECT * FROM reporting.vw_OrderSummary WHERE SalesOrderId = @SalesOrderId;
SELECT * FROM sales.SalesOrderItem WHERE SalesOrderId = @SalesOrderId;
SELECT * FROM audit.EventLog WHERE EntityId = CONVERT(varchar(100), @SalesOrderId);
';
