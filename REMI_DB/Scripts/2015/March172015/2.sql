/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 3/3/2015 9:30:29 PM

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
PRINT N'Altering [Req].[ReqFieldData]'
GO
ALTER TABLE [Req].[ReqFieldData] ADD
[InstanceID] [int] NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Req].[ReqFieldSetupSibling]'
GO
CREATE TABLE [Req].[ReqFieldSetupSibling]
(
[ReqFieldSiblingID] [int] NOT NULL IDENTITY(1, 1),
[ReqFieldSetupID] [int] NOT NULL,
[DefaultDisplayNum] [int] NOT NULL CONSTRAINT [DF_ReqFieldSetupSibling_DefaultDisplayNum] DEFAULT ((1)),
[MaxDisplayNum] [int] NOT NULL CONSTRAINT [DF_ReqFieldSetupSibling_MaxDisplayNum] DEFAULT ((2))
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_ReqFieldSetupSibling] on [Req].[ReqFieldSetupSibling]'
GO
ALTER TABLE [Req].[ReqFieldSetupSibling] ADD CONSTRAINT [PK_ReqFieldSetupSibling] PRIMARY KEY CLUSTERED  ([ReqFieldSiblingID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Req].[RequestFieldSetup]'
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
	
	SELECT rfd.ReqFieldSetupID, ISNULL(rfd.InstanceID, 1) AS InstanceID, rfd.Value
	FROM Req.ReqFieldData rfd WITH(NOLOCK)
		INNER JOIN Req.ReqFieldSetup rfs WITH(NOLOCK) ON rfs.ReqFieldSetupID=rfd.ReqFieldSetupID
		INNER JOIN Req.ReqFieldSetupSibling rfss WITH(NOLOCK) ON rfss.ReqFieldSetupID=rfs.ReqFieldSetupID
	WHERE RequestID = @RequestID AND rfss.MaxDisplayNum> 1

	SELECT rfs.ReqFieldSetupID, @RequestType AS RequestType, rfs.Name, lft.[Values] AS FieldType, rfs.FieldTypeID, 
			lvt.[Values] AS ValidationType, rfs.FieldValidationID, ISNULL(rfs.IsRequired, 0) AS IsRequired, ISNULL(rfs.DisplayOrder, 0) AS DisplayOrder,
			rfs.ColumnOrder, ISNULL(rfs.Archived, 0) AS Archived, rfs.Description, rfs.OptionsTypeID, @RequestTypeID AS RequestTypeID,
			@RequestNumber AS RequestNumber, @RequestID AS RequestID, 
			CASE WHEN rfm.IntField = 'RequestLink' AND Value IS NULL THEN 'http://go/requests/' + @RequestNumber ELSE CASE WHEN ISNULL(rfss.DefaultDisplayNum, 1) = 1 THEN rfd.Value ELSE '' END END AS Value, 
			rfm.IntField, rfm.ExtField,
			CASE WHEN rfm.ID IS NOT NULL THEN 1 ELSE 0 END AS InternalField,
			CASE WHEN @RequestID = 0 THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END AS NewRequest, rt.IsExternal AS IsFromExternalSystem, rfs.Category,
			rfs.ParentReqFieldSetupID, rt.HasIntegration, rfsp.Name As ParentFieldSetupName, rfs.DefaultValue, 
			ISNULL(rfd.ReqFieldDataID, -1) AS ReqFieldDataID, rt.HasDistribution,
			CASE
				WHEN (SELECT MAX(InstanceID) FROM Req.ReqFieldData d WHERE d.RequestID=@RequestID AND d.ReqFieldSetupID=rfs.ReqFieldSetupID) > ISNULL(rfss.DefaultDisplayNum, 1)
				THEN (SELECT MAX(InstanceID) FROM Req.ReqFieldData d WHERE d.RequestID=@RequestID AND d.ReqFieldSetupID=rfs.ReqFieldSetupID)
				ELSE ISNULL(rfss.DefaultDisplayNum, 1)
				END AS DefaultDisplayNum, 
			ISNULL(rfss.MaxDisplayNum, 1) AS MaxDisplayNum 
	FROM Req.RequestType rt WITH(NOLOCK)
		INNER JOIN Lookups lrt WITH(NOLOCK) ON lrt.LookupID=rt.TypeID
		INNER JOIN Req.ReqFieldSetup rfs WITH(NOLOCK) ON rfs.RequestTypeID=rt.RequestTypeID                  
		INNER JOIN Lookups lft WITH(NOLOCK) ON lft.LookupID=rfs.FieldTypeID
		LEFT OUTER JOIN Lookups lvt WITH(NOLOCK) ON lvt.LookupID=rfs.FieldValidationID
		LEFT OUTER JOIN Req.ReqFieldSetupRole rfsr WITH(NOLOCK) ON rfsr.ReqFieldSetupID=rfs.ReqFieldSetupID
		LEFT OUTER JOIN Req.Request r WITH(NOLOCK) ON RequestNumber=@RequestNumber
		LEFT OUTER JOIN Req.ReqFieldMapping rfm WITH(NOLOCK) ON rfm.RequestTypeID=rt.RequestTypeID AND rfm.ExtField=rfs.Name AND ISNULL(rfm.IsActive, 0) = 1
		LEFT OUTER JOIN Req.ReqFieldSetup rfsp WITH(NOLOCK) ON rfsp.ReqFieldSetupID=rfs.ParentReqFieldSetupID
		LEFT OUTER JOIN Req.ReqFieldSetupSibling rfss WITH(NOLOCK) ON rfss.ReqFieldSetupID=rfs.ReqFieldSetupID
		LEFT OUTER JOIN Req.ReqFieldData rfd WITH(NOLOCK) ON rfd.ReqFieldSetupID=rfs.ReqFieldSetupID AND rfd.RequestID=r.RequestID AND ISNULL(rfd.InstanceID, 1) = 1
	WHERE (lrt.[Values] = @RequestType) AND 
		(
			(@IncludeArchived = @TrueBit)
			OR
			(@IncludeArchived = @FalseBit AND ISNULL(rfs.Archived, @FalseBit) = @FalseBit)
			OR
			(@IncludeArchived = @FalseBit AND rfd.Value IS NOT NULL AND ISNULL(rfs.Archived, @FalseBit) = @TrueBit)
		)
	ORDER BY 23, 9 ASC
END
GO
GRANT EXECUTE ON [Req].[RequestFieldSetup] TO REMI
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Req].[ReqFieldDataAudit]'
GO
ALTER TABLE [Req].[ReqFieldDataAudit] ADD
[ReqFieldDataID] [int] NULL,
[InstanceID] [int] NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Req].[vw_RequestDataAudit]'
GO
ALTER VIEW [req].[vw_RequestDataAudit] WITH SCHEMABINDING
AS
SELECT ISNULL((ROW_NUMBER() OVER (ORDER BY r.RequestNumber)), 0) AS ID, r.RequestNumber, fs.Name, fda.Value, fda.UserName, fda.InsertTime, 
	ISNULL(fda.InstanceID,1) AS RecordNum, CASE fda.Action WHEN 'U' THEN 'Updated' WHEN 'D' THEN 'Deleted' WHEN 'I' THEN 'Inserted' ELSE '' END AS Action
FROM Req.ReqFieldDataAudit fda
	INNER JOIN Req.Request r ON fda.RequestID=r.RequestID
	INNER JOIN Req.ReqFieldSetup fs ON fs.ReqFieldSetupID=fda.ReqFieldSetupID
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [Req].[ReqFieldSetupSibling]'
GO
ALTER TABLE [Req].[ReqFieldSetupSibling] ADD CONSTRAINT [FK_ReqFieldSetupSibling_ReqFieldSetup] FOREIGN KEY ([ReqFieldSetupID]) REFERENCES [Req].[ReqFieldSetup] ([ReqFieldSetupID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering trigger [Req].[ReqFieldDataAuditInsertUpdate] on [Req].[ReqFieldData]'
GO
ALTER TRIGGER [Req].[ReqFieldDataAuditInsertUpdate] ON  [Req].[ReqFieldData] after insert, update
AS 
BEGIN
SET NOCOUNT ON;
 
Declare @action char(1)
DECLARE @count INT
  
--check if this is an insert or an update

If Exists(Select * From Inserted) and Exists(Select * From Deleted) --Update, both tables referenced
begin
	Set @action= 'U'
end
else
begin
	If Exists(Select * From Inserted) --insert, only one table referenced
	Begin
		Set @action= 'I'
	end
	if not Exists(Select * From Inserted) and not Exists(Select * From Deleted)--nothing changed, get out of here
	Begin
		RETURN
	end
end

select @count= count(*) from
(
   select Value, InstanceID from Inserted
   except
   select Value, InstanceID from Deleted
) a

if ((@count) >0)
begin
	insert into Req.ReqFieldDataAudit (RequestID,ReqFieldSetupID,Value,InsertTime,Action, UserName, ReqFieldDataID, InstanceID)
	Select RequestID,ReqFieldSetupID,Value,InsertTime, @action,lastuser, ReqFieldDataID, InstanceID from inserted
END
END

GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating trigger [Req].[ReqFieldDataAuditDelete] on [Req].[ReqFieldData]'
GO
CREATE TRIGGER Req.[ReqFieldDataAuditDelete] ON  Req.ReqFieldData
	for  delete
AS 
BEGIN
	SET NOCOUNT ON;

	If not Exists(Select * From Deleted) 
		return	 --No delete action, get out of here
	
	insert into Req.ReqFieldDataAudit (RequestID,ReqFieldSetupID,Value,InsertTime,Action, UserName, ReqFieldDataID, InstanceID)
	Select RequestID,ReqFieldSetupID,Value,InsertTime, 'D', lastuser, ReqFieldDataID, InstanceID from deleted
END
GO
DELETE FROM Req.ReqFieldMapping WHERE IntField='Select...'
GO
DECLARE @LookupTypeID INT
DECLARE @MaxLookupID INT
SELECT @LookupTypeID=LookupTypeID FROM LookupType WHERE Name='FieldTypes'
SELECT @MaxLookupID = MAX(LookupID) +1 FROM Lookups
INSERT INTO Lookups (LookupID,LookupTypeID,[Values],IsActive) VALUES (@MaxLookupID,@LookupTypeID,'Attachment',1)
GO
ALTER PROCEDURE [dbo].[remispTestsSelectListByType] @TestType int, @IncludeArchived BIT = 0, @UserID INT, @RequestTypeID INT
AS
BEGIN
	CREATE TABLE #Tests (TestID INT)
	
	IF (@UserID = 0)
	BEGIN
		INSERT INTO #Tests (TestID)
		SELECT t.ID AS TestID
		FROM Tests t
	END
	ELSE
	BEGIN
		INSERT INTO #Tests (TestID)
		SELECT DISTINCT ta.TestID
		FROM UserDetails ud
			INNER JOIN Lookups l ON l.LookupID=ud.LookupID
			INNER JOIN LookupType lt ON lt.LookupTypeID=l.LookupTypeID
			INNER JOIN TestsAccess ta ON ta.LookupID=ud.LookupID
			INNER JOIN Req.RequestTypeAccess rta ON rta.LookupID = ta.LookupID
		WHERE lt.Name='Department' AND (@RequestTypeID = 0 OR rta.RequestTypeID=@RequestTypeID) AND (@UserID = 0 OR ud.UserID=@UserID)
	END
	
	SELECT t.Comment,t.ConcurrencyID,t.Duration,t.ID,t.LastUser,t.ResultBasedOntime,t.TestName,t.TestType,t.WILocation, dbo.remifnTestCanDelete(t.ID) AS CanDelete, t.IsArchived,
		(SELECT TestStageName FROM TestStages WHERE TestID=t.ID) As TestStage, (SELECT JobName FROM Jobs WHERE ID IN (SELECT JobID FROM TestStages WHERE TestID=t.ID)) As JobName,
		t.Owner, t.Trainee, t.DegradationVal
	FROM Tests t
	WHERE TestType = @TestType
		AND ((@TestType = 1 AND t.ID IN (SELECT tt.TestID FROM #Tests tt) ) OR @TestType <> 1)
		AND
		(
			(@IncludeArchived = 0 AND ISNULL(t.IsArchived, 0) = 0)
			OR
			(@IncludeArchived = 1)
		)
	ORDER BY TestName
	
	SELECT t.id, tlt.id, tlt.TrackingLocationTypeName    
	FROM trackinglocationtypes as tlt, TrackingLocationsForTests as tlfort, Tests as t
	WHERE tlfort.testid = t.id and tlt.ID = tlfort.TrackingLocationtypeID
		AND t.TestType = @TestType
	ORDER BY tlt.TrackingLocationTypeName asc
	
	DROP TABLE #Tests
END
GO
GRANT EXECUTE ON remispTestsSelectListByType TO REMI
GO
ALTER PROCEDURE remispGetLookups @Type NVARCHAR(150), @ProductID INT = NULL, @ParentID INT = NULL, @ParentLookupType NVARCHAR(150) = NULL, @ParentLookup NVARCHAR(150) = NULL, @RequestTypeID INT = NULL,
	@ShowAdminSelected BIT = 0, @ShowArchived BIT = 0
AS
BEGIN
	DECLARE @LookupTypeID INT
	DECLARE @ParentLookupTypeID INT
	DECLARE @HierarchyExists BIT
	DECLARE @ParentLookupID INT
	SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name=@Type
	SELECT @ParentLookupTypeID = LookupTypeID FROM LookupType WHERE Name=@ParentLookupType
	SELECT @ParentLookupID = LookupID FROM Lookups WHERE LookupTypeID=@ParentLookupTypeID AND Lookups.[Values]=@ParentLookup
	SET @HierarchyExists = CONVERT(BIT, 0)
	
	SET @HierarchyExists = ISNULL((SELECT TOP 1 CONVERT(BIT, 1) 
	FROM LookupsHierarchy lh
	WHERE lh.ParentLookupTypeID=@ParentLookupTypeID AND lh.ChildLookupTypeID=@LookupTypeID
		AND lh.ParentLookupID=@ParentLookupID AND lh.RequestTypeID=@RequestTypeID), CONVERT(BIT, 0))
	
	DECLARE @NotSetSelected BIT
	SET @NotSetSelected = CONVERT(BIT, 0)
	
	IF EXISTS (SELECT 1 FROM LookupsHierarchy lh WHERE lh.ParentLookupTypeID=@ParentLookupTypeID AND lh.ChildLookupTypeID=@LookupTypeID AND lh.ParentLookupID=@ParentLookupID AND lh.RequestTypeID=@RequestTypeID AND lh.ChildLookupID=0)
		SET @NotSetSelected = CONVERT(BIT, 1)	

	SELECT l.LookupID, @Type AS [Type], l.[Values] As LookupType, CASE WHEN pl.ID IS NOT NULL THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END As HasAccess, 
		l.Description, ISNULL(l.ParentID, 0) AS ParentID, p.[Values] AS Parent, CASE WHEN lh.ChildLookupID =l.LookupID THEN 1 ELSE 0 END AS RequestAssigned, l.IsActive
	INTO #type
	FROM Lookups l
		LEFT OUTER JOIN ProductLookups pl ON pl.ProductID=@ProductID AND l.LookupID=pl.LookupID
		LEFT OUTER JOIN Lookups p ON p.LookupID=l.ParentID
		LEFT OUTER JOIN LookupsHierarchy lh ON lh.ParentLookupTypeID=@ParentLookupTypeID AND lh.ChildLookupTypeID=@LookupTypeID
			AND lh.ParentLookupID=@ParentLookupID AND lh.RequestTypeID=@RequestTypeID AND lh.ChildLookupID=l.LookupID
	WHERE l.LookupTypeID=@LookupTypeID 
		AND 
			(
				@ShowArchived = 1
				OR
				(@ShowArchived = 0 AND l.IsActive=1)
			)
		AND 
		(
			(@ParentID IS NOT NULL AND ISNULL(@ParentID, 0) <> 0 AND ISNULL(l.ParentID, 0) = ISNULL(@ParentID, 0))
			OR
			(@ParentID IS NULL OR ISNULL(@ParentID, 0) = 0)
		)
		AND
		(
			(
				@ShowAdminSelected = 1
				OR
				(l.LookupID IN (SELECT ChildLookupID 
							FROM LookupsHierarchy lh 
							WHERE lh.ParentLookupTypeID=@ParentLookupTypeID AND lh.ChildLookupTypeID=@LookupTypeID
								AND lh.ParentLookupID=@ParentLookupID AND lh.RequestTypeID=@RequestTypeID
							)
				) 
				OR
				@HierarchyExists = CONVERT(BIT, 0)
			)
		)
		
	; WITH cte AS
	(
		SELECT LookupID, [Type], LookupType, HasAccess, Description, ISNULL(ParentID, 0) AS ParentID, Parent, RequestAssigned, IsActive,
			cast(row_number()over(partition by ParentID order by LookupType) as varchar(max)) as [path],
			0 as level,
			row_number()over(partition by ParentID order by LookupType) / power(10.0,0) as x
		FROM #type
		WHERE ISNULL(ParentID, 0) = 0
		UNION ALL
		SELECT t.LookupID, t.[Type], t.LookupType, t.HasAccess, t.Description, t.ParentID, t.Parent, cte.RequestAssigned, cte.IsActive,
		[path] +'-'+ cast(row_number() over(partition by t.ParentID order by t.LookupType) as varchar(max)),
		level+1,
		x + row_number()over(partition by t.ParentID order by t.LookupType) / power(10.0,level+1)
		FROM cte
			INNER JOIN #type t on cte.LookupID = t.ParentID
	)
	select LookupID, [Type], LookupType, HasAccess, Description, ParentID, (CONVERT(NVARCHAR, ParentID) + '-' + Parent) AS Parent, x, (CONVERT(NVARCHAR, LookupID) + '-' + LookupType) AS DisplayText, RequestAssigned, IsActive
	FROM cte
	UNION ALL
	SELECT 0 AS LookupID, @Type AS [Type], '' As LookupType, CONVERT(BIT, 0) As HasAccess, NULL AS Description, 0 AS ParentID, NULL AS Parent, NULL AS x, '' AS DisplayText, @NotSetSelected AS RequestAssigned, 1 AS IsActive
	ORDER BY x		
		
	DROP TABLE #type
END
GO
GRANT EXECUTE ON remispGetLookups TO REMI
GO
ALTER PROCEDURE [dbo].[remispGetTestsAccess] @TestID INT = 0
AS
BEGIN
	SELECT 0 AS TestAccessID, '' AS TestName, '' As Department
	UNION
	SELECT ta.TestAccessID, t.TestName, l.[Values] As Department
	FROM TestsAccess ta
		INNER JOIN Tests t ON t.ID=ta.TestID
		INNER JOIN Lookups l ON l.LookupID=ta.LookupID
	WHERE (@TestID > 0 AND ta.TestID=@TestID) OR (@TestID = 0)
	ORDER BY 1
END
GO
GRANT EXECUTE ON [dbo].[remispGetJobAccess] TO REMI
GO
ALTER PROCEDURE dbo.remispGetServicesAccessByID @LookupID INT = NULL
AS
BEGIN
	DECLARE @TrueBit BIT
	SET @TrueBit = CONVERT(BIT, 1)
	
	SELECT 0 AS ServiceID, '' AS ServiceName, 0 AS ServiceAccessID, '' AS [Values]
	UNION
	SELECT s.ServiceID, s.ServiceName, sa.ServiceAccessID, ld.[Values]
	FROM dbo.Services s
		INNER JOIN dbo.ServicesAccess sa WITH (NOLOCK) ON sa.ServiceID=s.ServiceID
		INNER JOIN Lookups ld WITH(NOLOCK) ON ld.LookupID=sa.LookupID
	WHERE (@LookupID IS NULL OR sa.LookupID=@LookupID) AND ISNULL(s.IsActive, 0) = @TrueBit
END
GO
GRANT EXECUTE ON dbo.remispGetServicesAccessByID TO REMI
GO
ALTER PROCEDURE remispMenuAccessByDepartment @Name NVARCHAR(150) = NULL, @DepartmentID INT = NULL
AS
BEGIN
	SELECT '' AS Name, '' AS Department, '' AS Url, 0 AS MenuID, 0 AS MenuDepartmentID
	UNION
	SELECT m.Name, l.[Values] AS Department, m.Url, m.MenuID, md.MenuDepartmentID
	FROM Menu m
		INNER JOIN MenuDepartment md ON m.MenuID=md.MenuID
		INNER JOIN Lookups l ON l.LookupID=md.DepartmentID
	WHERE (md.DepartmentID = @DepartmentID OR ISNULL(@DepartmentID, 0) = 0)
		AND (m.Name=@Name OR LTRIM(RTRIM(ISNULL(@Name, '')))  = '')
	ORDER BY 2, 1
END
GO
GRANT EXECUTE ON remispMenuAccessByDepartment TO REMI
GO
ALTER PROCEDURE [dbo].[remispUsersDeleteSingleItem] @userIDToDelete nvarchar(255), @UserID INT
AS
	UPDATE UsersProducts 
	SET LastUser = (SELECT LDAPLogin FROM Users WHERE ID=@UserID) 
	FROM UsersProducts
	WHERE UserID = @userIDToDelete
	
	UPDATE Users 
	SET LastUser = (SELECT LDAPLogin FROM Users WHERE ID=@UserID)
	WHERE ID = @userIDToDelete

	DELETE FROM UsersProducts WHERE UserID = @userIDToDelete
	DELETE FROM UserSearchFilter WHERE UserID = @userIDToDelete
	DELETE FROM UserDetails WHERE UserID=@userIDToDelete
	DELETE FROM UserTraining WHERE UserID=@userIDToDelete
	DELETE FROM users WHERE ID = @userIDToDelete
GO
ALTER PROCEDURE [dbo].remispJobsList @UserID INT, @RequestTypeID INT, @DepartmentID INT
AS
BEGIN
	DECLARE @TrueBit BIT
	SET @TrueBit = CONVERT(BIT, 1)
	
	IF (@UserID = 0 AND @RequestTypeID = 0)
	BEGIN
		SELECT j.ID, j.JobName, j.IsActive, j.ContinueOnFailures, j.LastUser, j.NoBSN, j.TechnicalOperationsTest, j.ProcedureLocation, j.MechanicalTest,
			j.WILocation, j.OperationsTest, j.Comment
		FROM Jobs j
		WHERE j.IsActive=@TrueBit
		ORDER BY j.JobName
	END
	ELSE
	BEGIN
		CREATE TABLE #JobAccess (JobID INT)
		INSERT INTO #JobAccess(JobID)
		SELECT ja.JobID
		FROM UserDetails ud WITH(NOLOCK)
			INNER JOIN Lookups l WITH(NOLOCK) ON l.LookupID=ud.LookupID
			INNER JOIN LookupType lt WITH(NOLOCK) ON lt.LookupTypeID=l.LookupTypeID AND lt.Name='Department'
			INNER JOIN JobAccess ja WITH(NOLOCK) ON ja.LookupID=ud.LookupID
			INNER JOIN Req.RequestTypeAccess rta WITH(NOLOCK) ON rta.LookupID = ja.LookupID
		WHERE (@UserID = 0 OR ud.UserID=@UserID) AND (@RequestTypeID = 0 OR rta.RequestTypeID=@RequestTypeID)
			AND (@DepartmentID = 0 OR rta.LookupID=@DepartmentID)
	
		SELECT j.ID, j.JobName, j.IsActive, j.ContinueOnFailures, j.LastUser, j.NoBSN, j.TechnicalOperationsTest, j.ProcedureLocation, j.MechanicalTest,
			j.WILocation, j.OperationsTest, j.Comment
		FROM Jobs j
		WHERE j.IsActive=@TrueBit AND (j.ID IN (SELECT JobID FROM #JobAccess))
		ORDER BY j.JobName
		
		DROP TABLE #JobAccess
	END
END
Go
GRANT EXECUTE ON remispJobsList TO REMI
GO
ALTER PROCEDURE [Req].[RequestDataAudit] @RequestNumber NVARCHAR(11)
AS
BEGIN
	SELECT *
	FROM Req.vw_RequestDataAudit
	WHERE RequestNumber=@RequestNumber
	ORDER BY InsertTime ASC
END
GO
GRANT EXECUTE ON [Req].[RequestDataAudit] TO REMI
GO
update Req.ReqFieldDataAudit set InstanceID=1
update a
set a.ReqFieldDataID=d.ReqFieldDataID
from Req.ReqFieldDataAudit a
inner join Req.ReqFieldData d on d.RequestID=a.RequestID
where a.ReqFieldDataID is null
GO
ALTER PROCEDURE [dbo].[remispGetJobAccess] @JobID INT = 0
AS
BEGIN
	SELECT 0 AS JobAccessID, '' AS JobName, '' As Department
	UNION
	SELECT ja.JobAccessID, j.JobName, l.[Values] As Department
	FROM JobAccess ja
		INNER JOIN Jobs j ON j.ID=ja.JobID
		INNER JOIN Lookups l ON l.LookupID=ja.LookupID
	WHERE (@JobID > 0 AND ja.JobID=@JobID) OR (@JobID = 0)
	ORDER BY 2
END
GO
GRANT EXECUTE ON [dbo].[remispGetJobAccess] TO REMI
GO
ALTER PROCEDURE Relab.remispGetObservationSummary @BatchID INT
AS
BEGIN
	DECLARE @RowID INT
	DECLARE @ID INT
	DECLARE @BatchUnitNumber INT
	DECLARE @query NVARCHAR(4000)
	CREATE TABLE #Observations (Observation NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL, UnitsAffected INT)

	SELECT ROW_NUMBER() OVER (ORDER BY tu.ID) AS RowID, tu.BatchUnitNumber, tu.ID
	INTO #units
	FROM TestUnits tu WITH(NOLOCK)
	WHERE BatchID=@BatchID

	INSERT INTO #Observations
	SELECT Relab.ResultsObservation (m.ID) AS Observation, COUNT(DISTINCT tu.ID) AS UnitsAffected
	FROM Relab.ResultsMeasurements m WITH(NOLOCK)
		INNER JOIN Relab.Results r WITH(NOLOCK) ON r.ID=m.ResultID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID=r.TestStageID
		INNER JOIN Tests t WITH(NOLOCK) ON t.ID=r.TestID
		INNER JOIN Lookups lm WITH(NOLOCK) ON lm.LookupID=m.MeasurementTypeID
		INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
		LEFT OUTER JOIN JobOrientation jo WITH(NOLOCK) ON jo.ID=b.OrientationID
		LEFT OUTER JOIN Relab.ResultsMeasurementsFiles mf WITH(NOLOCK) ON mf.ResultMeasurementID=m.ID
	WHERE MeasurementTypeID IN (SELECT LookupID FROM Lookups WHERE LookupTypeID=7 AND [values] = 'Observation') AND b.ID=@BatchID
	GROUP BY Relab.ResultsObservation (m.ID)
	
	SELECT @RowID = MIN(RowID) FROM #units
				
	WHILE (@RowID IS NOT NULL)
	BEGIN
		SET @query = ''
		SELECT @BatchUnitNumber=BatchUnitNumber, @ID=ID FROM #units WITH(NOLOCK) WHERE RowID=@RowID
		
		EXECUTE ('ALTER TABLE #Observations ADD [' + @BatchUnitNumber + '] NVARCHAR(10) NULL')
		
		SET @query = 'UPDATE #Observations SET [' + CONVERT(VARCHAR,@BatchUnitNumber) + '] = ISNULL((
			SELECT TOP 1 REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(ts.TestStageName,''''),''drops'',''''),''drop'',''''),''tumbles'',''''),''tumble'','''')
			FROM Relab.ResultsMeasurements m WITH(NOLOCK)
				INNER JOIN Relab.Results r WITH(NOLOCK) ON r.ID=m.ResultID
				INNER JOIN TestUnits tu WITH(NOLOCK) ON r.TestUnitID=tu.ID
				INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID=r.TestStageID
				INNER JOIN Tests t WITH(NOLOCK) ON t.ID=r.TestID
				INNER JOIN Lookups lm WITH(NOLOCK) ON lm.LookupID=m.MeasurementTypeID
				INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
				LEFT OUTER JOIN JobOrientation jo WITH(NOLOCK) ON jo.ID=b.OrientationID
				LEFT OUTER JOIN Relab.ResultsMeasurementsFiles mf WITH(NOLOCK) ON mf.ResultMeasurementID=m.ID
			WHERE MeasurementTypeID IN (SELECT LookupID FROM Lookups WHERE LookupTypeID=7 
				AND [values] = ''Observation'') AND b.ID=' + CONVERT(VARCHAR, @BatchID) + ' 
				AND tu.batchunitnumber=' + CONVERT(VARCHAR,@BatchUnitNumber) + ' 
				AND Relab.ResultsObservation (m.ID) = #Observations.Observation
			ORDER BY ts.ProcessOrder ASC
		), ''-'')'
		
		EXECUTE (@query)
			
		SELECT @RowID = MIN(RowID) FROM #units WITH(NOLOCK) WHERE RowID > @RowID
	END
	
	DECLARE @units NVARCHAR(4000)
	SELECT @units = ISNULL(STUFF((
	SELECT '], [' + CONVERT(VARCHAR, tu.BatchUnitNumber)
	FROM TestUnits tu WITH(NOLOCK)
	WHERE BatchID=@BatchID
	FOR XML PATH('')), 1, 2, '') + ']','[na]')
	
	SET @query = 'SELECT Observation, ' + @units + ', UnitsAffected FROM #Observations'
	EXECUTE (@query)

	DROP TABLE #Observations
	DROP TABLE #units
END
GO
GRANT EXECUTE ON Relab.remispGetObservationSummary TO REMI
GO
ALTER PROCEDURE [dbo].[remispSaveLookup] @LookupType NVARCHAR(150), @Value NVARCHAR(150), @IsActive INT = 1, @Description NVARCHAR(200) = NULL, @ParentID INT = NULL, @Success AS BIT = NULL OUTPUT
AS
BEGIN
	DECLARE @LookupID INT
	DECLARE @LookupTypeID INT
	SELECT @LookupID = MAX(LookupID) + 1 FROM Lookups
	SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name=@LookupType

	IF (@ParentID = 0)
	BEGIN
		SET @ParentID = NULL
	END
	
	IF LTRIM(RTRIM(@Value)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups WHERE LookupTypeID=@LookupTypeID AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@Value)))
	BEGIN
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values], IsActive, Description, ParentID) 
		VALUES (@LookupID, @LookupTypeID, LTRIM(RTRIM(@Value)), @IsActive, @Description, @ParentID)
	
		IF (@LookupType = 'Products')
		BEGIN
			INSERT INTO Products (LookupID) Values (@LookupID)
		END
		
		SET @Success = 1
	END
	ELSE
	BEGIN
		UPDATE Lookups
		SET IsActive=@IsActive, Description=@Description, ParentID=@ParentID
		WHERE LookupTypeID=@LookupTypeID AND [values]=LTRIM(RTRIM(@Value))
		
		IF NOT EXISTS (SELECT 1 FROM Products p INNER JOIN Lookups l ON l.LookupID=p.LookupID WHERE LookupTypeID=@LookupTypeID AND [values]=LTRIM(RTRIM(@Value)))
		BEGIN
			INSERT INTO Products (LookupID) Values (@LookupID)
		END
		
		SET @Success = 1
	END

	PRINT @Success
END
GO
GRANT EXECUTE ON remispSaveLookup TO Remi
GO
ALTER PROCEDURE [dbo].[remispTestStagesSelectList] @JobName nvarchar(400) = null, @TestStageType int = null, @ShowArchived BIT = 0, @JobID INT = 0
AS
	BEGIN
		DECLARE @TrueBit BIT
		DECLARE @FalseBit BIT
		SET @FalseBit = CONVERT(BIT, 0)
		SET @TrueBit = CONVERT(BIT, 1)
		
		SELECT ts.Comment,ts.ConcurrencyID,ts.ID,ts.processorder,ts.JobID,ts.LastUser,ts.TestID,ts.TestStageName,ts.TestStageType,j.jobname, 
			ISNULL(ts.IsArchived, 0) AS IsArchived, dbo.remifnTestStageCanDelete(ts.ID) AS CanDelete
		FROM teststages ts
			INNER JOIN Jobs j ON ts.JobID=j.ID
		WHERE (ts.TestStageType = @TestStageType or @TestStageType is null)
			AND (@ShowArchived = @TrueBit OR (@ShowArchived = @FalseBit AND ISNULL(ts.IsArchived, 0) = @FalseBit))
			AND ISNULL(j.IsActive, 0) = @TrueBit
			AND 
				(
					(@JobID > 0 AND j.ID=@JobID)
					OR
					(@JobName IS NOT NULL AND j.JobName=@JobName)
					OR
					(@JobName IS NULL AND @JobID=0)
				)
		ORDER BY JobName, ProcessOrder
	END
Go
GRANT EXECUTE ON remispTestStagesSelectList TO REMI
GO
ALTER PROCEDURE [Relab].[remispResultsStatus] @BatchID INT
AS
BEGIN
	DECLARE @Status NVARCHAR(18)
	
	SELECT CASE WHEN r.PassFail = 0 THEN 'Fail' ELSE 'Pass' END AS Result, COUNT(*) AS NumRecords
	INTO #ResultCount
	FROM Relab.Results r
		INNER JOIN TestUnits tu ON tu.ID=r.TestUnitID
	WHERE tu.BatchID=@BatchID
	GROUP BY r.PassFail
	
	SELECT CASE WHEN rs.PassFail = 1 THEN 'Pass' WHEN rs.PassFail=2 THEN 'Fail' ELSE 'No Result' END AS Result, 
		rs.ApprovedBy, rs.ApprovedDate
	INTO #ResultOverride
	FROM Relab.ResultsStatus rs
	WHERE rs.BatchID=@BatchID
	ORDER BY ResultStatusID DESC
	
	IF ((SELECT COUNT(*) FROM #ResultOverride) > 0)
		BEGIN
			SELECT TOP 1 @Status = Result FROM #ResultOverride
		END
	ELSE
		BEGIN
			IF EXISTS ((SELECT 1 FROM #ResultCount WHERE Result='Fail'))
				SET @Status = 'Preliminary Fail'
			ELSE IF EXISTS ((SELECT 1 FROM #ResultCount WHERE Result='Pass'))
				SET @Status = 'Preliminary Pass'
			ELSE
				SET @Status = 'No Result'
		END
	
	SELECT * FROM #ResultCount
	SELECT * FROM #ResultOverride
		
	SELECT @Status AS FinalStatus
	
	DROP TABLE #ResultCount
	DROP TABLE #ResultOverride
END
GO
GRANT EXECUTE ON [Relab].[remispResultsStatus] TO Remi
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