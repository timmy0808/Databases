USE master;
GO

ALTER DATABASE TransplantDiagnostics SET RECOVERY FULL;
GO

-- AWS DMS uses SQL Server transactional replication for tables with primary
-- keys. A self-managed SQL Server source must have a local Distributor before
-- DMS can create its publication and articles.
IF NOT EXISTS (SELECT 1 FROM sys.servers WHERE is_distributor = 1)
BEGIN
    DECLARE @distributor SYSNAME = @@SERVERNAME;
    EXEC sys.sp_adddistributor @distributor = @distributor;
END;
GO

IF DB_ID(N'distribution') IS NULL
BEGIN
    EXEC sys.sp_adddistributiondb
        @database = N'distribution',
        @security_mode = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM msdb.dbo.MSdistpublishers
    WHERE name = @@SERVERNAME
)
BEGIN
    DECLARE @publisher SYSNAME = @@SERVERNAME;
    EXEC sys.sp_adddistpublisher
        @publisher = @publisher,
        @distribution_db = N'distribution',
        @security_mode = 1,
        @working_directory = N'/var/opt/mssql/data/ReplData';
END;
GO

-- A full database backup establishes the log chain required for reliable CDC.
-- The Linux container path is mapped inside the SQL Server container.
BACKUP DATABASE TransplantDiagnostics
TO DISK = '/var/opt/mssql/backup/TransplantDiagnostics_full.bak'
WITH INIT, COMPRESSION, CHECKSUM;
GO

-- AWS DMS uses SQL Server replication for tables with primary keys and can use
-- MS-CDC where required. Every migrated business table in this lab has a PK.
EXEC sys.sp_replicationdboption
    @dbname = N'TransplantDiagnostics',
    @optname = N'publish',
    @value = N'true';
GO

SELECT name, recovery_model_desc, is_published
FROM sys.databases
WHERE name = N'TransplantDiagnostics';
GO
