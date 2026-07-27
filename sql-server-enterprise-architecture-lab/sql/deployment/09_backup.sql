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

CREATE OR ALTER PROCEDURE ops.usp_BackupDatabase
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DatabaseName sysname = DB_NAME();
    DECLARE @FileName nvarchar(4000) =
        CONCAT(
            N'/var/opt/mssql/backups/',
            @DatabaseName,
            N'_',
            FORMAT(SYSUTCDATETIME(), 'yyyyMMdd_HHmmss'),
            N'.bak'
        );

    BACKUP DATABASE [$(DB_NAME)]
    TO DISK = @FileName
    WITH COMPRESSION, CHECKSUM, STATS = 10;

    RESTORE VERIFYONLY
    FROM DISK = @FileName
    WITH CHECKSUM;
END;
GO
