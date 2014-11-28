/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 11/27/2014 11:50:21 AM

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
PRINT N'Creating [dbo].[ServicesAccess]'
GO
CREATE TABLE [dbo].[ServicesAccess]
(
[ServiceAccessID] [int] NOT NULL IDENTITY(1, 1),
[ServiceID] [int] NOT NULL,
[LookupID] [int] NOT NULL
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_ServicesAccess] on [dbo].[ServicesAccess]'
GO
ALTER TABLE [dbo].[ServicesAccess] ADD CONSTRAINT [PK_ServicesAccess] PRIMARY KEY CLUSTERED  ([ServiceAccessID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[Services]'
GO
CREATE TABLE [dbo].[Services]
(
[ServiceID] [int] NOT NULL IDENTITY(1, 1),
[ServiceName] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[IsActive] [bit] NOT NULL CONSTRAINT [DF_Services_IsActive] DEFAULT ((1))
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_Services] on [dbo].[Services]'
GO
ALTER TABLE [dbo].[Services] ADD CONSTRAINT [PK_Services] PRIMARY KEY CLUSTERED  ([ServiceID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispGetServicesAccessByID]'
GO
CREATE PROCEDURE dbo.remispGetServicesAccessByID @LookupID INT = NULL
AS
BEGIN
	DECLARE @TrueBit BIT
	SET @TrueBit = CONVERT(BIT, 1)
	
	SELECT s.ServiceID, s.ServiceName, sa.ServiceAccessID, ld.[Values]
	FROM dbo.Services s
		INNER JOIN dbo.ServicesAccess sa WITH (NOLOCK) ON sa.ServiceID=s.ServiceID
		INNER JOIN Lookups ld WITH(NOLOCK) ON ld.LookupID=sa.LookupID
	WHERE (@LookupID IS NULL OR sa.LookupID=@LookupID) AND ISNULL(s.IsActive, 0) = @TrueBit
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispGetServices]'
GO
CREATE PROCEDURE dbo.remispGetServices
AS
BEGIN
	SELECT s.ServiceID, s.ServiceName, ISNULL(s.IsActive, 1) AS IsActive
	FROM dbo.Services s
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[aspnet_GetPermissions]'
GO
CREATE PROCEDURE [dbo].[aspnet_GetPermissions] @ApplicationName nvarchar(256)
AS
BEGIN
	DECLARE @ApplicationId uniqueidentifier
	SELECT  @ApplicationId = NULL
	SELECT  @ApplicationId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
	
	IF (@ApplicationId IS NULL)
		RETURN

	SELECT p.PermissionID, p.Permission
	FROM aspnet_Permissions p
	ORDER BY p.Permission
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispGetUser]'
GO
ALTER PROCEDURE [dbo].[remispGetUser] @SearchBy INT, @SearchStr NVARCHAR(255)
AS	
	DECLARE @UserID INT
	DECLARE @UserName NVARCHAR(255)

	IF (@SearchBy = 0)
	BEGIN
		SELECT @UserID=ID, @UserName = u.LDAPLogin
		FROM Users u
		WHERE u.BadgeNumber=@SearchStr
	END
	ELSE IF (@SearchBy = 1)
	BEGIN
		SELECT @UserID=ID, @UserName = u.LDAPLogin
		FROM Users u
		WHERE u.LDAPLogin=@SearchStr
	END
	ELSE IF (@SearchBy = 2)
	BEGIN
		SELECT @UserID=ID, @UserName = u.LDAPLogin
		FROM Users u
		WHERE u.ID=@SearchStr
	END
	
	SELECT u.BadgeNumber, u.ConcurrencyID, u.ID, u.LastUser, u.LDAPLogin, ISNULL(u.IsActive, 1) AS IsActive, 
		u.DefaultPage, u.ByPassProduct
	FROM Users u
	WHERE u.ID=@UserID
	
	EXEC remispGetUserDetails @UserID
	
	EXEC remispGetUserTraining @UserID =@UserID, @ShowTrainedOnly = 1
	
	EXEC remispProductManagersSelectList @UserID

	EXEC Req.remispGetRequestTypes @UserName
	
	SELECT s.ServiceID, s.ServiceName, l.[Values] AS Department
	FROM UserDetails ud
		INNER JOIN Lookups l ON l.LookupID=ud.LookupID
		INNER JOIN LookupType lt ON lt.LookupTypeID=l.LookupTypeID
		INNER JOIN ServicesAccess sa ON sa.LookupID=l.LookupID
		INNER JOIN Services s ON sa.ServiceID=s.ServiceID 
	WHERE ud.UserID=@UserID AND lt.Name='Department' AND ISNULL(s.IsActive, 0) = 1
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding constraints to [dbo].[Services]'
GO
ALTER TABLE [dbo].[Services] ADD CONSTRAINT [IX_Services_ServiceName] UNIQUE NONCLUSTERED  ([ServiceName])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [dbo].[ServicesAccess]'
GO
ALTER TABLE [dbo].[ServicesAccess] ADD CONSTRAINT [FK_ServicesAccess_Services] FOREIGN KEY ([ServiceID]) REFERENCES [dbo].[Services] ([ServiceID])
ALTER TABLE [dbo].[ServicesAccess] ADD CONSTRAINT [FK_ServicesAccess_Lookups] FOREIGN KEY ([LookupID]) REFERENCES [dbo].[Lookups] ([LookupID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remispGetServicesAccessByID]'
GO
GRANT EXECUTE ON  [dbo].[remispGetServicesAccessByID] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispGetServices]'
GO
GRANT EXECUTE ON  [dbo].[remispGetServices] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[aspnet_GetPermissions]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_GetPermissions] TO [remi]
GO
INSERT INTO Services (ServiceName) VALUES ('Batch Tracking')
INSERT INTO Services (ServiceName) VALUES ('REMSTAR')
DECLARE @LookupID INT
SELECT @LookupID = LookupID FROM Lookups l INNER JOIN LookupType lt ON lt.LookupTypeID=l.LookupTypeID WHERE lt.Name='Department' AND l.[Values]='Product Validation'
INSERT INTO ServicesAccess (ServiceID, LookupID)
SELECT s.ServiceID, @LookupID
FROM Services s
go
create PROCEDURE [Req].[RequestForDashboard] @RequestTypeID INT, @SearchStr NVARCHAR(150)
AS
BEGIN
	DECLARE @Count INT
	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + rfm.IntField
		FROM Req.ReqFieldSetup rfs
			INNER JOIN Req.ReqFieldMapping rfm ON rfm.ExtField = rfs.Name AND rfm.RequestTypeID=@RequestTypeID
		WHERE rfs.RequestTypeID=@RequestTypeID
		ORDER BY '],[' +  rfm.IntField
		FOR XML PATH('')), 1, 2, '') + ']','[na]')
		
	SELECT @Count = COUNT(*)
	FROM Req.Request r
		INNER JOIN Req.ReqFieldData rfd ON rfd.RequestID=r.RequestID
		INNER JOIN Req.ReqFieldSetup rfs ON rfs.ReqFieldSetupID=rfd.ReqFieldSetupID
		INNER JOIN Req.RequestType rt ON rt.RequestTypeID=rfs.RequestTypeID
	WHERE rt.RequestTypeID=@RequestTypeID

	IF (@Count > 0)
	BEGIN
		SET @sql = 'SELECT RequestNumber AS RequestNumber, [RequestedTest] AS RequestedTest, [SampleSize] AS SAMPLESIZE, [ProductGroup] AS PRODUCT,
			[ProductType] AS PRODUCTTYPE, [AccessoryGroup] AS ACCESSORYGROUPNAME, [RequestStatus] AS STATUS, [RequestPurpose] AS PURPOSE, '
		
		IF (@rows LIKE '[ExecutiveSummary]')
		BEGIN
			SET @sql += ' [ExecutiveSummary] AS ExecutiveSummary, '
		END
		ELSE
		BEGIN
			SET @sql += ' NULL AS ExecutiveSummary, '
		END
			 
		SET @sql += ' [CPRNumber] AS CPR
			FROM 
				(
				SELECT r.RequestID, r.RequestNumber, rfd.Value, rfm.IntField
				FROM Req.Request r
					INNER JOIN Req.ReqFieldData rfd ON rfd.RequestID=r.RequestID
					INNER JOIN Req.ReqFieldSetup rfs ON rfs.ReqFieldSetupID=rfd.ReqFieldSetupID
					INNER JOIN Req.RequestType rt ON rt.RequestTypeID=rfs.RequestTypeID
					INNER JOIN Req.ReqFieldMapping rfm ON rfm.ExtField = rfs.Name
				WHERE rt.RequestTypeID=' + CONVERT(NVARCHAR, @RequestTypeID) + '
				) req PIVOT (MAX(Value) FOR IntField IN (' + @rows + ')) AS pvt
			WHERE [ProductGroup] = ''' + @SearchStr + ''' '

		PRINT @sql
		EXEC (@sql)
	END
END
GO
GRANT EXECUTE ON [Req].RequestForDashboard TO REMI
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
ROLLBACK TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO