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

IF OBJECT_ID(N'sales.Customer', N'U') IS NULL
BEGIN
    CREATE TABLE sales.Customer
    (
        CustomerId bigint IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Customer PRIMARY KEY,
        CustomerNumber varchar(20) NOT NULL
            CONSTRAINT UQ_Customer_CustomerNumber UNIQUE,
        FirstName nvarchar(100) NOT NULL,
        LastName nvarchar(100) NOT NULL,
        Email nvarchar(320) NOT NULL,
        Phone varchar(30) NULL,
        Status varchar(20) NOT NULL
            CONSTRAINT CK_Customer_Status CHECK (Status IN ('Active','Inactive','Suspended')),
        CreatedAt datetime2(3) NOT NULL
            CONSTRAINT DF_Customer_CreatedAt DEFAULT SYSUTCDATETIME(),
        ModifiedAt datetime2(3) NOT NULL
            CONSTRAINT DF_Customer_ModifiedAt DEFAULT SYSUTCDATETIME(),
        ValidFrom datetime2(3) GENERATED ALWAYS AS ROW START NOT NULL,
        ValidTo datetime2(3) GENERATED ALWAYS AS ROW END NOT NULL,
        PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
    )
    WITH
    (
        SYSTEM_VERSIONING = ON
        (
            HISTORY_TABLE = sales.CustomerHistory,
            DATA_CONSISTENCY_CHECK = ON
        )
    );
END;
GO

IF OBJECT_ID(N'catalog.Product', N'U') IS NULL
BEGIN
    CREATE TABLE catalog.Product
    (
        ProductId bigint IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Product PRIMARY KEY,
        SKU varchar(40) NOT NULL
            CONSTRAINT UQ_Product_SKU UNIQUE,
        ProductName nvarchar(200) NOT NULL,
        UnitPrice decimal(19,4) NOT NULL
            CONSTRAINT CK_Product_UnitPrice CHECK (UnitPrice >= 0),
        IsActive bit NOT NULL CONSTRAINT DF_Product_IsActive DEFAULT 1,
        CreatedAt datetime2(3) NOT NULL CONSTRAINT DF_Product_CreatedAt DEFAULT SYSUTCDATETIME()
    );
END;
GO

IF OBJECT_ID(N'inventory.Warehouse', N'U') IS NULL
BEGIN
    CREATE TABLE inventory.Warehouse
    (
        WarehouseId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Warehouse PRIMARY KEY,
        WarehouseCode varchar(20) NOT NULL CONSTRAINT UQ_Warehouse_Code UNIQUE,
        WarehouseName nvarchar(150) NOT NULL,
        RegionCode varchar(10) NOT NULL,
        IsActive bit NOT NULL CONSTRAINT DF_Warehouse_IsActive DEFAULT 1
    );
END;
GO

IF OBJECT_ID(N'inventory.Stock', N'U') IS NULL
BEGIN
    CREATE TABLE inventory.Stock
    (
        WarehouseId int NOT NULL,
        ProductId bigint NOT NULL,
        QuantityOnHand int NOT NULL CONSTRAINT CK_Stock_QOH CHECK (QuantityOnHand >= 0),
        QuantityReserved int NOT NULL CONSTRAINT CK_Stock_Reserved CHECK (QuantityReserved >= 0),
        RowVersion rowversion NOT NULL,
        CONSTRAINT PK_Stock PRIMARY KEY (WarehouseId, ProductId),
        CONSTRAINT FK_Stock_Warehouse FOREIGN KEY (WarehouseId)
            REFERENCES inventory.Warehouse(WarehouseId),
        CONSTRAINT FK_Stock_Product FOREIGN KEY (ProductId)
            REFERENCES catalog.Product(ProductId),
        CONSTRAINT CK_Stock_Reservation CHECK (QuantityReserved <= QuantityOnHand)
    );
END;
GO

IF OBJECT_ID(N'sales.SalesOrder', N'U') IS NULL
BEGIN
    CREATE TABLE sales.SalesOrder
    (
        SalesOrderId bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_SalesOrder PRIMARY KEY,
        OrderNumber varchar(30) NOT NULL CONSTRAINT UQ_SalesOrder_OrderNumber UNIQUE,
        CustomerId bigint NOT NULL,
        WarehouseId int NOT NULL,
        OrderStatus varchar(20) NOT NULL
            CONSTRAINT CK_SalesOrder_Status CHECK
            (OrderStatus IN ('Pending','Confirmed','Paid','Shipped','Cancelled')),
        OrderDate datetime2(3) NOT NULL CONSTRAINT DF_SalesOrder_OrderDate DEFAULT SYSUTCDATETIME(),
        Subtotal decimal(19,4) NOT NULL CONSTRAINT DF_SalesOrder_Subtotal DEFAULT 0,
        TaxAmount decimal(19,4) NOT NULL CONSTRAINT DF_SalesOrder_Tax DEFAULT 0,
        TotalAmount AS (Subtotal + TaxAmount) PERSISTED,
        CreatedBy sysname NOT NULL CONSTRAINT DF_SalesOrder_CreatedBy DEFAULT ORIGINAL_LOGIN(),
        CONSTRAINT FK_SalesOrder_Customer FOREIGN KEY (CustomerId)
            REFERENCES sales.Customer(CustomerId),
        CONSTRAINT FK_SalesOrder_Warehouse FOREIGN KEY (WarehouseId)
            REFERENCES inventory.Warehouse(WarehouseId)
    );
END;
GO

IF OBJECT_ID(N'sales.SalesOrderItem', N'U') IS NULL
BEGIN
    CREATE TABLE sales.SalesOrderItem
    (
        SalesOrderItemId bigint IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_SalesOrderItem PRIMARY KEY,
        SalesOrderId bigint NOT NULL,
        ProductId bigint NOT NULL,
        Quantity int NOT NULL CONSTRAINT CK_OrderItem_Quantity CHECK (Quantity > 0),
        UnitPrice decimal(19,4) NOT NULL CONSTRAINT CK_OrderItem_UnitPrice CHECK (UnitPrice >= 0),
        LineTotal AS (CONVERT(decimal(19,4), Quantity * UnitPrice)) PERSISTED,
        CONSTRAINT UQ_OrderItem_Order_Product UNIQUE (SalesOrderId, ProductId),
        CONSTRAINT FK_OrderItem_Order FOREIGN KEY (SalesOrderId)
            REFERENCES sales.SalesOrder(SalesOrderId),
        CONSTRAINT FK_OrderItem_Product FOREIGN KEY (ProductId)
            REFERENCES catalog.Product(ProductId)
    );
END;
GO

IF OBJECT_ID(N'finance.Payment', N'U') IS NULL
BEGIN
    CREATE TABLE finance.Payment
    (
        PaymentId bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_Payment PRIMARY KEY,
        SalesOrderId bigint NOT NULL,
        PaymentReference varchar(80) NOT NULL CONSTRAINT UQ_Payment_Reference UNIQUE,
        Amount decimal(19,4) NOT NULL CONSTRAINT CK_Payment_Amount CHECK (Amount > 0),
        PaymentStatus varchar(20) NOT NULL
            CONSTRAINT CK_Payment_Status CHECK (PaymentStatus IN ('Authorized','Settled','Failed','Refunded')),
        PaidAt datetime2(3) NULL,
        CONSTRAINT FK_Payment_Order FOREIGN KEY (SalesOrderId)
            REFERENCES sales.SalesOrder(SalesOrderId)
    );
END;
GO

IF OBJECT_ID(N'sales.Shipment', N'U') IS NULL
BEGIN
    CREATE TABLE sales.Shipment
    (
        ShipmentId bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_Shipment PRIMARY KEY,
        SalesOrderId bigint NOT NULL,
        TrackingNumber varchar(100) NULL,
        Carrier varchar(50) NULL,
        ShipmentStatus varchar(20) NOT NULL
            CONSTRAINT CK_Shipment_Status CHECK (ShipmentStatus IN ('Pending','Packed','Shipped','Delivered','Returned')),
        ShippedAt datetime2(3) NULL,
        DeliveredAt datetime2(3) NULL,
        CONSTRAINT FK_Shipment_Order FOREIGN KEY (SalesOrderId)
            REFERENCES sales.SalesOrder(SalesOrderId)
    );
END;
GO

IF OBJECT_ID(N'audit.EventLog', N'U') IS NULL
BEGIN
    CREATE TABLE audit.EventLog
    (
        EventLogId bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_EventLog PRIMARY KEY,
        EventTime datetime2(3) NOT NULL CONSTRAINT DF_EventLog_Time DEFAULT SYSUTCDATETIME(),
        LoginName sysname NOT NULL,
        ApplicationName nvarchar(128) NULL,
        EventType varchar(50) NOT NULL,
        EntityName sysname NULL,
        EntityId varchar(100) NULL,
        Details nvarchar(max) NULL,
        CorrelationId uniqueidentifier NULL
    );
END;
GO
