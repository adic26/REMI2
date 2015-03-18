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
CREATE TABLE [dbo].[LookupsHierarchy](
	[LookupsHierarchyID] [int] IDENTITY(1,1) NOT NULL,
	[ParentLookupTypeID] [int] NOT NULL,
	[ChildLookupTypeID] [int] NOT NULL,
	[ParentLookupID] [int] NOT NULL,
	[ChildLookupID] [int] NOT NULL,
	[RequestTypeID] [int] NOT NULL,
 CONSTRAINT [PK_LookupsHierarchy] PRIMARY KEY CLUSTERED 
(
	[LookupsHierarchyID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LookupsHierarchy]  WITH CHECK ADD  CONSTRAINT [FK_LookupsHierarchy_Lookups] FOREIGN KEY([ParentLookupID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO
ALTER TABLE [dbo].[LookupsHierarchy] CHECK CONSTRAINT [FK_LookupsHierarchy_Lookups]
GO
ALTER TABLE [dbo].[LookupsHierarchy]  WITH CHECK ADD  CONSTRAINT [FK_LookupsHierarchy_Lookups1] FOREIGN KEY([ChildLookupID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO
ALTER TABLE [dbo].[LookupsHierarchy] CHECK CONSTRAINT [FK_LookupsHierarchy_Lookups1]
GO
ALTER TABLE [dbo].[LookupsHierarchy]  WITH CHECK ADD  CONSTRAINT [FK_LookupsHierarchy_LookupType] FOREIGN KEY([ParentLookupTypeID])
REFERENCES [dbo].[LookupType] ([LookupTypeID])
GO
ALTER TABLE [dbo].[LookupsHierarchy] CHECK CONSTRAINT [FK_LookupsHierarchy_LookupType]
GO
ALTER TABLE [dbo].[LookupsHierarchy]  WITH CHECK ADD  CONSTRAINT [FK_LookupsHierarchy_LookupType1] FOREIGN KEY([ChildLookupTypeID])
REFERENCES [dbo].[LookupType] ([LookupTypeID])
GO
ALTER TABLE [dbo].[LookupsHierarchy] CHECK CONSTRAINT [FK_LookupsHierarchy_LookupType1]
GO
ALTER TABLE [dbo].[LookupsHierarchy]  WITH CHECK ADD  CONSTRAINT [FK_LookupsHierarchy_RequestType] FOREIGN KEY([RequestTypeID])
REFERENCES [Req].[RequestType] ([RequestTypeID])
GO
ALTER TABLE [dbo].[LookupsHierarchy] CHECK CONSTRAINT [FK_LookupsHierarchy_RequestType]
GO
ALTER TABLE Req.ReqFieldSetup ADD ParentReqFieldSetupID INT NULL
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
ALTER PROCEDURE [Req].[RequestGet] @RequestTypeID INT, @Department NVARCHAR(150)
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
		SET @sql = 'SELECT ''http://go/reqapp/'' + CONVERT(VARCHAR, RequestNumber) AS RequestID, RequestNumber AS RequestNumber, [RequestStatus] AS STATUS, [ProductGroup] AS PRODUCT, [ProductType] AS PRODUCTTYPE,
			[AccessoryGroup] AS ACCESSORYGROUPNAME, [TestCenterLocation] AS TESTCENTER, [Department] AS DEPARTMENT, [SampleSize] AS SAMPLESIZE,
			[RequestedTest] AS Job, [RequestPurpose] AS PURPOSE, [CPRNumber] AS CPR, CONVERT(DateTime, REPLACE([ReportRequiredBy], ''-'','' '')) AS [Report Required By],
			[Priority] AS PRIORITY, [Requestor] AS REQUESTOR, CONVERT(DateTime, REPLACE([DateCreated], ''-'','' '')) AS CRE_DATE
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
			WHERE [Department] = ''' + @Department + ''' AND
				[RequestStatus] IN (''Submitted'',''PM Review'',''Assigned'') '

		PRINT @sql
		EXEC (@sql)
	END
END
GO
GRANT EXECUTE ON [Req].[RequestGet] TO REMI
GO
ALTER PROCEDURE remispGetLookups @Type NVARCHAR(150), @ProductID INT = NULL, @ParentID INT = NULL, @ParentLookupType NVARCHAR(150) = NULL, @ParentLookup NVARCHAR(150) = NULL, @RequestTypeID INT = NULL
AS
BEGIN
	DECLARE @LookupTypeID INT
	DECLARE @ParentLookupTypeID INT
	DECLARE @HierarchyExists BIT
	SET @HierarchyExists = CONVERT(BIT, 0)
	DECLARE @ParentLookupID INT
	SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name=@Type
	SELECT @ParentLookupTypeID = LookupTypeID FROM LookupType WHERE Name=@ParentLookupType
	SELECT @ParentLookupID = LookupID FROM Lookups WHERE LookupTypeID=@ParentLookupTypeID AND Lookups.[Values]=@ParentLookup
	
	SET @HierarchyExists = ISNULL((SELECT TOP 1 CONVERT(BIT, 1) 
	FROM LookupsHierarchy lh
	WHERE lh.ParentLookupTypeID=@ParentLookupTypeID AND lh.ChildLookupTypeID=@LookupTypeID
		AND lh.ParentLookupID=@ParentLookupID AND lh.RequestTypeID=@RequestTypeID), CONVERT(BIT, 0))

	SELECT l.LookupID, @Type AS [Type], l.[Values] As LookupType, CASE WHEN pl.ID IS NOT NULL THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END As HasAccess, 
		l.Description, ISNULL(l.ParentID, 0) AS ParentID, p.[Values] AS Parent
	INTO #type
	FROM Lookups l
		LEFT OUTER JOIN ProductLookups pl ON pl.ProductID=@ProductID AND l.LookupID=pl.LookupID
		LEFT OUTER JOIN Lookups p ON p.LookupID=l.ParentID
	WHERE l.LookupTypeID=@LookupTypeID AND l.IsActive=1 AND 
		(
			(@ParentID IS NOT NULL AND ISNULL(@ParentID, 0) <> 0 AND ISNULL(l.ParentID, 0) = ISNULL(@ParentID, 0))
			OR
			(@ParentID IS NULL OR ISNULL(@ParentID, 0) = 0)
		)
		AND
		(
			(l.LookupID IN (SELECT ChildLookupID 
						FROM LookupsHierarchy lh 
						WHERE lh.ParentLookupTypeID=@ParentLookupTypeID AND lh.ChildLookupTypeID=@LookupTypeID
							AND lh.ParentLookupID=@ParentLookupID AND lh.RequestTypeID=@RequestTypeID
						)
			) 
			OR
			@HierarchyExists = CONVERT(BIT, 0)
		)
		
	; WITH cte AS
	(
		SELECT LookupID, [Type], LookupType, HasAccess, Description, ISNULL(ParentID, 0) AS ParentID, Parent,
			cast(row_number()over(partition by ParentID order by LookupType) as varchar(max)) as [path],
			0 as level,
			row_number()over(partition by ParentID order by LookupType) / power(10.0,0) as x
		FROM #type
		WHERE ISNULL(ParentID, 0) = 0
		UNION ALL
		SELECT t.LookupID, t.[Type], t.LookupType, t.HasAccess, t.Description, t.ParentID, t.Parent,
		[path] +'-'+ cast(row_number() over(partition by t.ParentID order by t.LookupType) as varchar(max)),
		level+1,
		x + row_number()over(partition by t.ParentID order by t.LookupType) / power(10.0,level+1)
		FROM cte
			INNER JOIN #type t on cte.LookupID = t.ParentID
	)
	select LookupID, [Type], LookupType, HasAccess, Description, ParentID, (CONVERT(NVARCHAR, ParentID) + '-' + Parent) AS Parent, x, (CONVERT(NVARCHAR, LookupID) + '-' + LookupType) AS DisplayText
	FROM cte
	UNION ALL
	SELECT 0 AS LookupID, @Type AS [Type], '' As LookupType, CONVERT(BIT, 0) As HasAccess, NULL AS Description, 0 AS ParentID, NULL AS Parent, NULL AS x, '' AS DisplayText
	ORDER BY x		
		
	DROP TABLE #type
END
GO
GRANT EXECUTE ON remispGetLookups TO REMI
GO
ALTER PROCEDURE [Req].[RequestFieldSetup] @RequestTypeID INT, @IncludeArchived BIT = 0, @RequestNumber NVARCHAR(12) = NULL
AS
BEGIN
	DECLARE @RequestID INT
	DECLARE @TrueBit BIT
	DECLARE @FalseBit BIT
	DECLARE @RequestType NVARCHAR(150)
	SET @RequestID = 0
	SET @TrueBit = CONVERT(BIT, 1)
	SET @FalseBit = CONVERT(BIT, 0)

	SELECT @RequestType=lrt.[values] FROM Req.RequestType rt INNER JOIN Lookups lrt ON lrt.LookupID=rt.TypeID WHERE rt.RequestTypeID=@RequestTypeID

	IF (@RequestNumber IS NOT NULL)
		BEGIN
			SELECT @RequestID = RequestID FROM Req.Request WHERE RequestNumber=@RequestNumber
		END
	ELSE
		BEGIN
			SELECT @RequestNumber = REPLACE(RequestNumber, @RequestType + '-' + Right(Year(getDate()),2) + '-', '') + 1 
			FROM Req.Request 
			WHERE RequestNumber LIKE @RequestType + '-' + Right(Year(getDate()),2) + '-%'
			
			IF (LEN(@RequestNumber) < 4)
			BEGIN
				SET @RequestNumber = REPLICATE('0', 4-LEN(@RequestNumber)) + @RequestNumber
			END
		
			IF (@RequestNumber IS NULL)
				SET @RequestNumber = '0001'
		
			SET @RequestNumber = @RequestType + '-' + Right(Year(getDate()),2) + '-' + @RequestNumber
		END

	SELECT rfs.ReqFieldSetupID, @RequestType AS RequestType, rfs.Name, lft.[Values] AS FieldType, rfs.FieldTypeID, 
			lvt.[Values] AS ValidationType, rfs.FieldValidationID, ISNULL(rfs.IsRequired, 0) AS IsRequired, rfs.DisplayOrder, 
			rfs.ColumnOrder, ISNULL(rfs.Archived, 0) AS Archived, rfs.Description, rfs.OptionsTypeID, @RequestTypeID AS RequestTypeID,
			@RequestNumber AS RequestNumber, @RequestID AS RequestID, 
			CASE WHEN rfm.IntField = 'RequestLink' AND Value IS NULL THEN 'http://go/reqapp/' + @RequestNumber ELSE rfd.Value END AS Value, 
			rfm.IntField, rfm.ExtField,
			CASE WHEN rfm.ID IS NOT NULL THEN 1 ELSE 0 END AS InternalField,
			CASE WHEN @RequestID = 0 THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END AS NewRequest, Req.RequestType.IsExternal AS IsFromExternalSystem, rfs.Category,
			rfs.ParentReqFieldSetupID, Req.RequestType.HasIntegration
	FROM Req.RequestType
		INNER JOIN Lookups lrt ON lrt.LookupID=Req.RequestType.TypeID
		INNER JOIN Req.ReqFieldSetup rfs ON rfs.RequestTypeID=Req.RequestType.RequestTypeID                  
		INNER JOIN Lookups lft ON lft.LookupID=rfs.FieldTypeID
		LEFT OUTER JOIN Lookups lvt ON lvt.LookupID=rfs.FieldValidationID
		LEFT OUTER JOIN Req.ReqFieldSetupRole ON Req.ReqFieldSetupRole.ReqFieldSetupID=rfs.ReqFieldSetupID
		LEFT OUTER JOIN Req.Request ON RequestNumber=@RequestNumber
		LEFT OUTER JOIN Req.ReqFieldData rfd ON rfd.ReqFieldSetupID=rfs.ReqFieldSetupID AND rfd.RequestID=Req.Request.RequestID
		LEFT OUTER JOIN Req.ReqFieldMapping rfm ON rfm.RequestTypeID=Req.RequestType.RequestTypeID AND rfm.ExtField=rfs.Name AND ISNULL(rfm.IsActive, 0) = 1
	WHERE (lrt.[Values] = @RequestType) AND
		(
			(@IncludeArchived = @TrueBit)
			OR
			(@IncludeArchived = @FalseBit AND ISNULL(rfs.Archived, @FalseBit) = @FalseBit)
			OR
			(@IncludeArchived = @FalseBit AND rfd.Value IS NOT NULL AND ISNULL(rfs.Archived, @FalseBit) = @TrueBit)
		)
	ORDER BY Category, ISNULL(rfs.DisplayOrder, 0) ASC
END
GO
GRANT EXECUTE ON [Req].[RequestFieldSetup] TO REMI
GO
ALTER PROCEDURE Req.remispGetRequestTypes @UserName NVARCHAR(255)
AS
BEGIN
	SELECT lt.[Values] AS RequestType, l.[Values] AS Department, rta.IsActive, rt.HasIntegration
	FROM Req.RequestTypeAccess rta
		INNER JOIN Lookups l ON rta.LookupID=l.LookupID
		INNER JOIN Req.RequestType rt ON rt.RequestTypeID=rta.RequestTypeID
		INNER JOIN Lookups lt ON rt.TypeID=lt.LookupID
		INNER JOIN UserDetails ud ON ud.LookupID = l.LookupID
		INNER JOIN Users u ON u.ID=ud.UserID
	WHERE u.LDAPLogin=@UserName
END
GO
GRANT EXECUTE ON Req.remispGetRequestTypes TO REMI
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