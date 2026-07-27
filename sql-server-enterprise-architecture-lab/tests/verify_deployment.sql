SET NOCOUNT ON;
SET XACT_ABORT ON;
USE [$(DB_NAME)];

DECLARE @Errors table (Problem nvarchar(4000));

;WITH ExpectedSchemas(name) AS
(
    SELECT name FROM (VALUES
      (N'audit'),(N'catalog'),(N'finance'),(N'hr'),
      (N'inventory'),(N'ops'),(N'reporting'),(N'sales')
    ) v(name)
)
INSERT @Errors(Problem)
SELECT CONCAT(N'Missing schema: ', e.name)
FROM ExpectedSchemas e
WHERE SCHEMA_ID(e.name) IS NULL;

;WITH ExpectedObjects(name, type) AS
(
    SELECT * FROM (VALUES
      (N'sales.Customer', N'U'),
      (N'catalog.Product', N'U'),
      (N'inventory.Warehouse', N'U'),
      (N'inventory.Stock', N'U'),
      (N'sales.SalesOrder', N'U'),
      (N'sales.SalesOrderItem', N'U'),
      (N'finance.Payment', N'U'),
      (N'sales.Shipment', N'U'),
      (N'audit.EventLog', N'U'),
      (N'sales.usp_CreateOrder', N'P'),
      (N'sales.usp_CancelOrder', N'P'),
      (N'reporting.vw_OrderSummary', N'V'),
      (N'reporting.vw_InventoryAvailability', N'V'),
      (N'ops.vw_LongRunningQueries', N'V'),
      (N'ops.vw_IndexUsage', N'V'),
      (N'ops.usp_BackupDatabase', N'P')
    ) v(name,type)
)
INSERT @Errors(Problem)
SELECT CONCAT(N'Missing object: ', name)
FROM ExpectedObjects
WHERE OBJECT_ID(name, type) IS NULL;

IF (SELECT COUNT(*) FROM sales.Customer) < 2 INSERT @Errors VALUES(N'Customer seed data missing.');
IF (SELECT COUNT(*) FROM catalog.Product) < 4 INSERT @Errors VALUES(N'Product seed data missing.');
IF (SELECT COUNT(*) FROM inventory.Warehouse) < 2 INSERT @Errors VALUES(N'Warehouse seed data missing.');
IF (SELECT COUNT(*) FROM inventory.Stock) < 8 INSERT @Errors VALUES(N'Inventory seed data missing.');

IF EXISTS (SELECT 1 FROM @Errors)
BEGIN
    SELECT Problem FROM @Errors;
    THROW 51000, 'Deployment verification failed.', 1;
END;

SELECT
    DB_NAME() AS DatabaseName,
    (SELECT COUNT(*) FROM sys.schemas WHERE name IN
      ('audit','catalog','finance','hr','inventory','ops','reporting','sales')) AS LabSchemaCount,
    (SELECT COUNT(*) FROM sales.Customer) AS CustomerCount,
    (SELECT COUNT(*) FROM catalog.Product) AS ProductCount,
    (SELECT COUNT(*) FROM inventory.Warehouse) AS WarehouseCount,
    (SELECT COUNT(*) FROM inventory.Stock) AS StockCount,
    CAST('PASS' AS varchar(10)) AS DeploymentStatus;
