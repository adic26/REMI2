/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 3/3/2015 1:59:33 PM

*/
SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#tmpErrors')) DROP TABLE #tmpErrors
GO
CREATE TABLE #tmpErrors (Error int)
GO
SET XACT_ABORT ON
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO
BEGIN TRANSACTION
GO
PRINT N'Dropping foreign keys from [Req].[ReqFieldData]'
GO
ALTER TABLE [Req].[ReqFieldData] DROP CONSTRAINT[FK_ReqFieldData_Request]
ALTER TABLE [Req].[ReqFieldData] DROP CONSTRAINT[FK_ReqFieldData_ReqFieldSetup]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Dropping constraints from [Req].[ReqFieldData]'
GO
ALTER TABLE [Req].[ReqFieldData] DROP CONSTRAINT [PK_ReqFieldData]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Req].[RequestType]'
GO
EXEC sp_rename N'[Req].[RequestType].[HasApproval]', N'HasDistribution', 'COLUMN'
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Req].[ReqFieldData]'
GO
ALTER TABLE [Req].[ReqFieldData] ADD
[ReqFieldDataID] [int] NOT NULL IDENTITY(1, 1)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_ReqFieldData] on [Req].[ReqFieldData]'
GO
ALTER TABLE [Req].[ReqFieldData] ADD CONSTRAINT [PK_ReqFieldData] PRIMARY KEY CLUSTERED  ([ReqFieldDataID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Req].[RequestGet]'
GO
ALTER PROCEDURE [Req].[RequestGet] @RequestTypeID INT, @Department NVARCHAR(150)
AS
BEGIN
	DECLARE @Count INT
	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + rfm.IntField
		FROM Req.ReqFieldSetup rfs WITH(NOLOCK)
			INNER JOIN Req.ReqFieldMapping rfm WITH(NOLOCK) ON rfm.ExtField = rfs.Name AND rfm.RequestTypeID=@RequestTypeID
		WHERE rfs.RequestTypeID=@RequestTypeID
		ORDER BY '],[' +  rfm.IntField
		FOR XML PATH('')), 1, 2, '') + ']','[na]')
		
	SELECT @Count = COUNT(*)
	FROM Req.Request r WITH(NOLOCK)
		INNER JOIN Req.ReqFieldData rfd WITH(NOLOCK) ON rfd.RequestID=r.RequestID
		INNER JOIN Req.ReqFieldSetup rfs WITH(NOLOCK) ON rfs.ReqFieldSetupID=rfd.ReqFieldSetupID
		INNER JOIN Req.RequestType rt WITH(NOLOCK) ON rt.RequestTypeID=rfs.RequestTypeID
	WHERE rt.RequestTypeID=@RequestTypeID

	IF (@Count > 0)
	BEGIN
		SET @sql = 'SELECT ''http://go/requests/'' + CONVERT(VARCHAR, RequestNumber) AS RequestID, RequestNumber AS RequestNumber, [RequestStatus] AS STATUS, [ProductGroup] AS PRODUCT, [ProductType] AS PRODUCTTYPE,
			[AccessoryGroup] AS ACCESSORYGROUPNAME, [TestCenterLocation] AS TESTCENTER, [Department] AS DEPARTMENT, [SampleSize] AS SAMPLESIZE,
			[RequestedTest] AS Job, [RequestPurpose] AS PURPOSE, [CPRNumber] AS CPR, CONVERT(DateTime, REPLACE([ReportRequiredBy], ''-'','' '')) AS [Report Required By],
			[Priority] AS PRIORITY, [Requestor] AS REQUESTOR, CONVERT(DateTime, REPLACE([DateCreated], ''-'','' '')) AS CRE_DATE
			FROM 
				(
				SELECT r.RequestID, r.RequestNumber, rfd.Value, rfm.IntField
				FROM Req.Request r WITH(NOLOCK)
					INNER JOIN Req.ReqFieldData rfd WITH(NOLOCK) ON rfd.RequestID=r.RequestID
					INNER JOIN Req.ReqFieldSetup rfs WITH(NOLOCK) ON rfs.ReqFieldSetupID=rfd.ReqFieldSetupID
					INNER JOIN Req.RequestType rt WITH(NOLOCK) ON rt.RequestTypeID=rfs.RequestTypeID
					INNER JOIN Req.ReqFieldMapping rfm WITH(NOLOCK) ON rfm.ExtField = rfs.Name
				WHERE rt.RequestTypeID=' + CONVERT(NVARCHAR, @RequestTypeID) + '
				) req PIVOT (MAX(Value) FOR IntField IN (' + @rows + ')) AS pvt
			WHERE [Department] = ''' + @Department + ''' AND
				[RequestStatus] IN (''Submitted'',''PM Review'',''Assigned'') '

		PRINT @sql
		EXEC (@sql)
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Req].[ReqDistribution]'
GO
CREATE TABLE [Req].[ReqDistribution]
(
[DistributionID] [int] NOT NULL IDENTITY(1, 1),
[RequestID] [int] NOT NULL,
[UserName] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_ReqDistribution] on [Req].[ReqDistribution]'
GO
ALTER TABLE [Req].[ReqDistribution] ADD CONSTRAINT [PK_ReqDistribution] PRIMARY KEY CLUSTERED  ([DistributionID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [Req].[ReqDistribution]'
GO
ALTER TABLE [Req].[ReqDistribution] ADD CONSTRAINT [FK_ReqDistribution_Request] FOREIGN KEY ([RequestID]) REFERENCES [Req].[Request] ([RequestID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [Req].[ReqFieldData]'
GO
ALTER TABLE [Req].[ReqFieldData] ADD CONSTRAINT [FK_ReqFieldData_Request] FOREIGN KEY ([RequestID]) REFERENCES [Req].[Request] ([RequestID])
ALTER TABLE [Req].[ReqFieldData] ADD CONSTRAINT [FK_ReqFieldData_ReqFieldSetup] FOREIGN KEY ([ReqFieldSetupID]) REFERENCES [Req].[ReqFieldSetup] ([ReqFieldSetupID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
COMMIT TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO