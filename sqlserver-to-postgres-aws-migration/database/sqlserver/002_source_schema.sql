USE TransplantDiagnostics;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'clinical') EXEC('CREATE SCHEMA clinical');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'audit') EXEC('CREATE SCHEMA audit');
GO

CREATE TABLE clinical.Patient (
    PatientId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    ExternalPatientKey NVARCHAR(64) NOT NULL UNIQUE,
    BirthYear SMALLINT NULL,
    BloodType VARCHAR(3) NULL,
    CreatedAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    VersionNumber ROWVERSION
);

CREATE TABLE clinical.Donor (
    DonorId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    ExternalDonorKey NVARCHAR(64) NOT NULL UNIQUE,
    DonorType VARCHAR(20) NOT NULL CHECK (DonorType IN ('living','deceased')),
    BloodType VARCHAR(3) NULL,
    CreatedAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    VersionNumber ROWVERSION
);

CREATE TABLE clinical.TransplantCase (
    TransplantCaseId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    PatientId UNIQUEIDENTIFIER NOT NULL,
    DonorId UNIQUEIDENTIFIER NOT NULL,
    OrganType VARCHAR(20) NOT NULL,
    CaseStatus VARCHAR(20) NOT NULL DEFAULT 'active',
    TransplantDate DATE NULL,
    CreatedAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    VersionNumber ROWVERSION,
    CONSTRAINT FK_TransplantCase_Patient FOREIGN KEY (PatientId) REFERENCES clinical.Patient(PatientId),
    CONSTRAINT FK_TransplantCase_Donor FOREIGN KEY (DonorId) REFERENCES clinical.Donor(DonorId)
);

CREATE TABLE clinical.DiagnosticResult (
    DiagnosticResultId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    TransplantCaseId UNIQUEIDENTIFIER NOT NULL,
    ResultType NVARCHAR(100) NOT NULL,
    ResultValue DECIMAL(18,6) NULL,
    ResultUnit NVARCHAR(30) NULL,
    IsAbnormal BIT NOT NULL DEFAULT 0,
    DiagnosticPayload NVARCHAR(MAX) NULL,
    RecordedAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    VersionNumber ROWVERSION,
    CONSTRAINT FK_DiagnosticResult_Case FOREIGN KEY (TransplantCaseId) REFERENCES clinical.TransplantCase(TransplantCaseId),
    CONSTRAINT CK_DiagnosticResult_JSON CHECK (DiagnosticPayload IS NULL OR ISJSON(DiagnosticPayload)=1)
);

CREATE TABLE audit.AuditEvent (
    AuditEventId BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EntityType NVARCHAR(50) NOT NULL,
    EntityId NVARCHAR(100) NOT NULL,
    ActionType VARCHAR(20) NOT NULL,
    ActorKey NVARCHAR(100) NOT NULL,
    EventPayload NVARCHAR(MAX) NULL,
    OccurredAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_AuditEvent_JSON CHECK (EventPayload IS NULL OR ISJSON(EventPayload)=1)
);

CREATE INDEX IX_DiagnosticResult_Case_RecordedAt
ON clinical.DiagnosticResult(TransplantCaseId, RecordedAt DESC);

CREATE INDEX IX_AuditEvent_Entity_OccurredAt
ON audit.AuditEvent(EntityType, EntityId, OccurredAt DESC);
GO

CREATE OR ALTER PROCEDURE clinical.GetRecentDiagnostics
    @CaseId UNIQUEIDENTIFIER,
    @MaximumRows INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@MaximumRows)
        DiagnosticResultId, TransplantCaseId, ResultType, ResultValue,
        ResultUnit, IsAbnormal, DiagnosticPayload, RecordedAt
    FROM clinical.DiagnosticResult
    WHERE TransplantCaseId=@CaseId
    ORDER BY RecordedAt DESC;
END;
GO
