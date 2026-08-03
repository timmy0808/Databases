USE TransplantDiagnostics;
GO

DECLARE @CaseId UNIQUEIDENTIFIER = (
    SELECT TOP (1) TransplantCaseId
    FROM clinical.TransplantCase
    ORDER BY CreatedAt
);

DECLARE @InsertedId UNIQUEIDENTIFIER = NEWID();

INSERT INTO clinical.DiagnosticResult (
    DiagnosticResultId, TransplantCaseId, ResultType, ResultValue,
    ResultUnit, IsAbnormal, DiagnosticPayload
)
VALUES (
    @InsertedId, @CaseId, N'dms_cdc_insert', 14.250000,
    N'MFI', 0, N'{"migration_marker":"insert"}'
);

UPDATE clinical.DiagnosticResult
SET ResultValue = 24.900000,
    IsAbnormal = 1,
    DiagnosticPayload = N'{"migration_marker":"update"}',
    UpdatedAt = SYSUTCDATETIME()
WHERE DiagnosticResultId = @InsertedId;

INSERT INTO audit.AuditEvent(EntityType, EntityId, ActionType, ActorKey, EventPayload)
VALUES (N'DiagnosticResult', CONVERT(NVARCHAR(100), @InsertedId), 'UPDATE', N'dms-demo',
        N'{"migration_marker":"audit"}');

-- Create and delete a second row to demonstrate delete replication.
DECLARE @DeletedId UNIQUEIDENTIFIER = NEWID();
INSERT INTO clinical.DiagnosticResult (
    DiagnosticResultId, TransplantCaseId, ResultType, ResultValue,
    ResultUnit, IsAbnormal, DiagnosticPayload
)
VALUES (
    @DeletedId, @CaseId, N'dms_cdc_delete', 1.000000,
    N'unit', 0, N'{"migration_marker":"delete"}'
);
DELETE FROM clinical.DiagnosticResult WHERE DiagnosticResultId = @DeletedId;

SELECT @InsertedId AS InsertedAndUpdatedDiagnosticResultId,
       @DeletedId AS DeletedDiagnosticResultId;
GO
