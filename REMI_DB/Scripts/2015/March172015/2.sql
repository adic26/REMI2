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
ALTER PROCEDURE dbo.remispGetContacts @ProductID INT
AS
BEGIN
	DECLARE @TSDContact NVARCHAR(255)
	
	SELECT @TSDContact = p.TSDContact
	FROM Products p
	WHERE p.ID=@ProductID
	
	SELECT us.LDAPLogin, @TSDContact AS TSDContact
	FROM aspnet_Users u
		INNER JOIN aspnet_UsersInRoles ur ON u.UserId=ur.UserId
		INNER JOIN aspnet_Roles r ON r.RoleId=ur.RoleId
		INNER JOIN Users us ON us.LDAPLogin = u.UserName
		INNER JOIN UsersProducts up ON up.UserID=us.ID
	WHERE r.RoleName='ProjectManager' AND CONVERT(BIT, r.hasProductCheck) = 1 AND up.ProductID=@ProductID
END
GO
GRANT EXECUTE ON [dbo].remispGetContacts TO REMI
GO
ALTER PROCEDURE Relab.remispGetObservations @BatchID INT
AS
BEGIN
	SELECT b.QRANumber, tu.BatchUnitNumber, (SELECT TOP 1 ts2.TestStageName
								FROM Relab.Results r2
									INNER JOIN TestStages ts2 ON ts2.ID=r2.TestStageID AND ts2.TestStageType=2
								WHERE r2.TestUnitID=r.TestUnitID
								ORDER BY ts2.ProcessOrder DESC
								) AS MaxStage, 
			ts.TestStageName, [Relab].[ResultsObservation] (m.ID) AS Observation, 
			(SELECT T.c.value('@Description', 'varchar(MAX)')
			FROM jo.Definition.nodes('/Orientations/Orientation') T(c)
			WHERE T.c.value('@Unit', 'varchar(MAX)') = tu.BatchUnitNumber AND ts.TestStageName LIKE T.c.value('@Drop', 'varchar(MAX)') + ' %') AS Orientation, 
			m.Comment, (CASE WHEN (SELECT COUNT(*) FROM Relab.ResultsMeasurementsFiles rmf WHERE rmf.ResultMeasurementID=m.ID) > 0 THEN 1 ELSE 0 END) AS HasFiles, m.ID AS MeasurementID
	FROM Relab.ResultsMeasurements m
		INNER JOIN Relab.Results r ON r.ID=m.ResultID
		INNER JOIN TestUnits tu ON r.TestUnitID=tu.ID
		INNER JOIN TestStages ts ON ts.ID=r.TestStageID
		INNER JOIN Tests t ON t.ID=r.TestID
		INNER JOIN Lookups lm ON lm.LookupID=m.MeasurementTypeID
		INNER JOIN Batches b ON b.ID=tu.BatchID
		LEFT OUTER JOIN JobOrientation jo ON jo.ID=b.OrientationID
	WHERE MeasurementTypeID IN (SELECT LookupID FROM Lookups WHERE LookupTypeID=7 AND [values] = 'Observation')
		AND b.ID=@BatchID AND ISNULL(m.Archived,0) = 0
	ORDER BY tu.BatchUnitNumber, ts.ProcessOrder
END
GO
GRANT EXECUTE ON Relab.remispGetObservations TO REMI
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
		AND ISNULL(m.Archived, 0) = 0
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
				AND ISNULL(m.Archived, 0) = 0
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
ALTER PROCEDURE [Req].[GetRequestSetupInfo] @ProductID INT, @JobID INT, @BatchID INT, @TestStageType INT, @BlankSelected INT, @UserID INT, @RequestTypeID INT
AS
BEGIN
	SELECT ta.TestID
	INTO #Tests
	FROM UserDetails ud
		INNER JOIN Lookups l ON l.LookupID=ud.LookupID
		INNER JOIN LookupType lt ON lt.LookupTypeID=l.LookupTypeID
		INNER JOIN TestsAccess ta ON ta.LookupID=ud.LookupID
		INNER JOIN Req.RequestTypeAccess rta ON rta.LookupID = ta.LookupID
	WHERE (@UserID = 0 OR ud.UserID=@UserID) AND lt.Name='Department' AND (@RequestTypeID = 0 OR rta.RequestTypeID=@RequestTypeID)

	IF NOT EXISTS(SELECT 1 FROM Req.RequestSetup rs INNER JOIN Tests t ON t.ID=rs.TestID WHERE BatchID=@BatchID AND t.TestType=@TestStageType)
	BEGIN
		IF EXISTS(SELECT 1 FROM Req.RequestSetup rs INNER JOIN Tests t ON t.ID=rs.TestID WHERE JobID=@JobID AND ProductID=@ProductID AND t.TestType=@TestStageType)
		BEGIN
			SELECT ts.ID As TestStageID, ts.TestStageName, t.ID AS TestID, t.TestName, CASE WHEN rs.ID IS NULL THEN CONVERT(BIT, 0) ELSE CONVERT(BIT, 1) END AS Selected
			FROM Jobs j
				INNER JOIN TestStages ts ON j.ID=ts.JobID
				INNER JOIN Tests t WITH(NOLOCK) ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
				LEFT OUTER JOIN Req.RequestSetup rs ON rs.JobID=@JobID AND rs.ProductID=@ProductID AND rs.TestID=t.ID AND rs.TestStageID=ts.ID
			WHERE j.ID=@JobID AND ts.TestStageType=@TestStageType AND ts.ProcessOrder >= 0 AND ISNULL(ts.IsArchived, 0) = 0 AND ISNULL(t.IsArchived, 0) = 0
				AND (@TestStageType <> 1 OR (@TestStageType = 1 AND t.ID IN (SELECT TestID FROM #Tests)))
				AND ISNULL(j.IsActive, 1) = 1
			ORDER BY ts.ProcessOrder, t.TestName
		END
		ELSE IF @BlankSelected = 0 AND EXISTS(SELECT 1 FROM Req.RequestSetup rs INNER JOIN Tests t ON t.ID=rs.TestID WHERE JobID=@JobID AND ProductID IS NULL AND t.TestType=@TestStageType)
		BEGIN
			SELECT ts.ID As TestStageID, ts.TestStageName, t.ID AS TestID, t.TestName, CASE WHEN rs.ID IS NULL THEN CONVERT(BIT, 0) ELSE CONVERT(BIT, 1) END AS Selected
			FROM Jobs j
				INNER JOIN TestStages ts ON j.ID=ts.JobID
				INNER JOIN Tests t WITH(NOLOCK) ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
				LEFT OUTER JOIN Req.RequestSetup rs ON rs.JobID=@JobID AND rs.ProductID IS NULL AND rs.TestID=t.ID AND rs.TestStageID=ts.ID
			WHERE j.ID=@JobID AND ts.TestStageType=@TestStageType AND ts.ProcessOrder >= 0 AND ISNULL(ts.IsArchived, 0) = 0 AND ISNULL(t.IsArchived, 0) = 0
				AND (@TestStageType <> 1 OR (@TestStageType = 1 AND t.ID IN (SELECT TestID FROM #Tests)))
				AND ISNULL(j.IsActive, 1) = 1
			ORDER BY ts.ProcessOrder, t.TestName
		END
		ELSE
		BEGIN
			SELECT ts.ID As TestStageID, ts.TestStageName, t.ID AS TestID, t.TestName, CASE WHEN @BlankSelected = 1 THEN CONVERT(BIT, 0) ELSE CONVERT(BIT, 1) END AS Selected
			FROM Jobs j
				INNER JOIN TestStages ts ON j.ID=ts.JobID
				INNER JOIN Tests t WITH(NOLOCK) ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
			WHERE j.ID=@JobID AND ts.TestStageType=@TestStageType AND ts.ProcessOrder >= 0 AND ISNULL(ts.IsArchived, 0) = 0 AND ISNULL(t.IsArchived, 0) = 0
				AND (@TestStageType <> 1 OR (@TestStageType = 1 AND t.ID IN (SELECT TestID FROM #Tests)))
				AND ISNULL(j.IsActive, 1) = 1
			ORDER BY ts.ProcessOrder, t.TestName
		END
	END
	ELSE
	BEGIN
		SELECT ts.ID As TestStageID, ts.TestStageName, t.ID AS TestID, t.TestName, CASE WHEN rs.ID IS NULL THEN CONVERT(BIT, 0) ELSE CONVERT(BIT, 1) END AS Selected
		FROM Jobs j
			INNER JOIN TestStages ts ON j.ID=ts.JobID
			INNER JOIN Tests t WITH(NOLOCK) ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
			LEFT OUTER JOIN Req.RequestSetup rs ON rs.TestID=t.ID 
											AND rs.BatchID=@BatchID 
											AND rs.TestStageID=ts.ID 
											AND 
											(
												(ISNULL(rs.ProductID,0)=ISNULL(@ProductID,0))
												OR
												(rs.ProductID IS NULL)
											)
		WHERE j.ID=@JobID AND ts.TestStageType=@TestStageType AND ts.ProcessOrder >= 0 AND ISNULL(ts.IsArchived, 0) = 0 AND ISNULL(t.IsArchived, 0) = 0
			AND (@TestStageType <> 1 OR (@TestStageType = 1 AND t.ID IN (SELECT TestID FROM #Tests)))
			AND ISNULL(j.IsActive, 1) = 1
		ORDER BY ts.ProcessOrder, t.TestName		
	END
	
	DROP TABLE #Tests
END
GO
GRANT EXECUTE ON [Req].[GetRequestSetupInfo] TO REMI
GO
ALTER VIEW [dbo].[vw_GetTaskInfo]
AS
SELECT qranumber, processorder, BatchID,
	   tsname, 
	   tname, 
	   testtype, 
	   teststagetype, 
	   resultbasedontime, 
	   testunitsfortest, 
	   (SELECT CASE WHEN specifictestduration IS NULL THEN generictestduration ELSE specifictestduration END) AS expectedDuration,
	   TestStageID, TestWI, TestID, IsArchived, ISNULL(RecordExists, 0) AS RecordExists, TestIsArchived, ISNULL(TestRecordExists, 0) AS TestRecordExists,
TestCounts
FROM   
	(
		SELECT b.qranumber,b.ID AS BatchID,
		ts.processorder, ts.teststagename AS tsname, t.testname AS tname, t.testtype, ts.teststagetype, t.duration AS genericTestDuration, ts.ID AS TestStageID,t.ID AS TestID,
		t.WILocation As TestWI, ISNULL(ts.IsArchived, 0) AS IsArchived, ISNULL(t.IsArchived, 0) AS TestIsArchived, 
			t.resultbasedontime, 
			(
				SELECT bstd.duration 
				FROM   batchspecifictestdurations AS bstd WITH(NOLOCK)
				WHERE  bstd.testid = t.id 
					   AND bstd.batchid = b.id
			) AS specificTestDuration,
			(
				SELECT CONVERT(NVARCHAR, tur.BatchUnitNumber) + ':' + CONVERT(NVARCHAR, ISNULL((SELECT MAX(x.VerNum) FROM Relab.ResultsXML x WHERE x.ResultID=r.ID), 1)) + '-' + CONVERT(NVARCHAR, CASE WHEN tr.RelabVersion = 0 THEN 1 ELSE ISNULL(tr.RelabVersion,1) END) + ','
				FROM TestUnits tur
					LEFT OUTER JOIN Relab.Results r ON r.TestUnitID=tur.ID AND r.TestID=t.ID AND r.TestStageID=ts.ID
					LEFT OUTER JOIN TestRecords tr ON tr.TestID=r.TestID AND tr.TestStageID=r.TestStageID AND tr.TestUnitID=r.TestUnitID
				WHERE tur.BatchID=b.id
				FOR xml path ('')	
			) AS TestCounts,
			(				
				SELECT Cast(tu.batchunitnumber AS VARCHAR(MAX)) + ', ' 
				FROM testunits AS tu WITH(NOLOCK)
				WHERE tu.batchid = b.id 
					AND 
					(
						NOT EXISTS 
						(
							SELECT DISTINCT 1
							FROM vw_ExceptionsPivoted as pvt WITH(NOLOCK)
							where pvt.ID IN (SELECT ID FROM TestExceptions WITH(NOLOCK) WHERE LookupID=3 AND Value = tu.ID) AND
							(
								(pvt.TestStageID IS NULL AND pvt.Test = t.ID ) 
								OR 
								(pvt.Test IS NULL AND pvt.TestStageID = ts.id) 
								OR 
								(pvt.TestStageID = ts.id AND pvt.Test = t.ID)
								OR
								(pvt.TestStageID IS NULL AND pvt.Test IS NULL)
							)
						)
					)
				FOR xml path ('')
			) AS TestUnitsForTest,
			(SELECT TOP 1 1
			FROM TestRecords tr WITH(NOLOCK)
				INNER JOIN TestUnits tu ON tr.TestUnitID = tu.ID
			WHERE tr.TestStageID=ts.ID AND tu.BatchID=b.ID) AS RecordExists,
			(SELECT TOP 1 1
			FROM TestRecords tr WITH(NOLOCK)
				INNER JOIN TestUnits tu ON tr.TestUnitID = tu.ID
			WHERE tr.TestID=t.ID AND tu.BatchID=b.ID AND tr.TestStageID = ts.ID) AS TestRecordExists
		FROM TestStages ts WITH(NOLOCK)
		INNER JOIN Jobs j WITH(NOLOCK) ON ts.JobID=j.ID
		INNER JOIN Batches b WITH(NOLOCK) on j.jobname = b.jobname 
		INNER JOIN Tests t WITH(NOLOCK) ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
		INNER JOIN Products p WITH(NOLOCK) ON b.ProductID=p.ID
		WHERE EXISTS 
			(
				SELECT DISTINCT 1
				FROM Req.RequestSetup rs
				WHERE
					(
						(rs.JobID IS NULL )
						OR
						(rs.JobID IS NOT NULL AND rs.JobID = j.ID)
					)
					AND
					(
						(rs.ProductID IS NULL)
						OR
						(rs.ProductID IS NOT NULL AND rs.ProductID = p.ID)
					)
					AND
					(
						(rs.TestID IS NULL)
						OR
						(rs.TestID IS NOT NULL AND rs.TestID = t.ID)
					)
					AND
					(
						(rs.TestStageID IS NULL)
						OR
						(rs.TestStageID IS NOT NULL AND rs.TestStageID = ts.ID)
					)
					AND
					(
						(rs.BatchID IS NULL) AND NOT EXISTS(SELECT 1 
															FROM Req.RequestSetup rs2 
																INNER JOIN TestStages ts2 ON ts2.ID=rs2.TestStageID AND ts2.TestStageType=ts.TestStageType
															WHERE rs2.BatchID = b.ID )
						OR
						(rs.BatchID IS NOT NULL AND rs.BatchID = b.ID)
					)
			)
	) AS unitData
WHERE TestUnitsForTest IS NOT NULL AND 
	(
		(ISNULL(RecordExists,0) > 0 AND IsArchived = 1 AND ISNULL(TestRecordExists, 0) > 0 AND TestIsArchived = 1)
		OR
		(ISNULL(IsArchived, 0) = 0 AND ISNULL(TestIsArchived, 0) = 0)
		OR
		(ISNULL(RecordExists,0) > 0 AND IsArchived = 0 AND ISNULL(TestRecordExists, 0) > 0 AND TestIsArchived = 1)
		OR
		(ISNULL(RecordExists,0) > 0 AND IsArchived = 1 AND ISNULL(TestRecordExists, 0) > 0 AND TestIsArchived = 0)
	)
GO
ALTER PROCEDURE [remispBatchGetTaskInfo] @BatchID INT, @TestStageID INT = 0
AS
BEGIN
	DECLARE @BatchStatus INT
	SELECT @BatchStatus = BatchStatus FROM Batches WHERE ID=@BatchID

	IF (@BatchStatus = 5)
	BEGIN
		SELECT QRANumber, expectedDuration, processorder, resultbasedontime, tname As TestName, testtype, teststagetype, tsname AS TestStageName, testunitsfortest, TestID, TestStageID, IsArchived, 
			TestIsArchived, TestWI, '' AS TestCounts
		FROM vw_GetTaskInfoCompleted
		WHERE BatchID = @BatchID
			AND
			(
				(@TestStageID = 0)
				OR
				(@TestStageID <> 0 AND TestStageID=@TestStageID)
			)
		ORDER BY ProcessOrder
	END
	ELSE
	BEGIN
		SELECT QRANumber, expectedDuration, processorder, resultbasedontime, tname As TestName, testtype, teststagetype, tsname AS TestStageName, testunitsfortest, TestID, TestStageID, IsArchived, 
			TestIsArchived, TestWI, TestCounts
		FROM vw_GetTaskInfo 
		WHERE BatchID = @BatchID
			AND
			(
				(@TestStageID = 0)
				OR
				(@TestStageID <> 0 AND TestStageID=@TestStageID)
			)
		ORDER BY ProcessOrder
	END
END
GO
GRANT EXECUTE ON remispBatchGetTaskInfo TO Remi
GO
ALTER PROCEDURE [dbo].remispGetBatchDocuments @QRANumber nvarchar(11)
AS
BEGIN
	DECLARE @JobName NVARCHAR(400)
	DECLARE @ProductID INT
	DECLARE @ID INT
	SELECT @JobName = JobName, @ProductID = ProductID, @ID = ID FROM Batches WITH(NOLOCK) WHERE QRANumber=@QRANumber

	CREATE TABLE #view (QRANumber NVARCHAR(11), expectedDuration REAL, processorder INT, resultbasedontime INT, TestName NVARCHAR(400) COLLATE SQL_Latin1_General_CP1_CI_AS, testtype INT, teststagetype INT, TestStageName NVARCHAR(400), testunitsfortest NVARCHAR(MAX), TestID INT, TestStageID INT, IsArchived BIT, TestIsArchived BIT, TestWI NVARCHAR(400) COLLATE SQL_Latin1_General_CP1_CI_AS, TestCounts NVARCHAR(MAX))

	insert into #view (QRANumber, expectedDuration, processorder, resultbasedontime, TestName, testtype, teststagetype, TestStageName, testunitsfortest, TestID, TestStageID, IsArchived, TestIsArchived, TestWI, TestCounts)
	exec remispBatchGetTaskInfo @BatchID=@ID

	SELECT (j.JobName + ' WI') AS WIType, j.WILocation AS Location
	FROM Jobs j WITH(NOLOCK)
	WHERE j.JobName=@JobName AND LTRIM(RTRIM(ISNULL(j.WILocation, ''))) <> ''
	UNION
	SELECT DISTINCT TestName AS WIType, TestWI AS Location
	FROM #view WITH(NOLOCK)
	WHERE QRANumber=@QRANumber and processorder > 0 AND testtype IN (1,2) AND LTRIM(RTRIM(ISNULL(TestWI,''))) <> ''
	UNION
	SELECT (j.JobName + ' Procedure') AS WIType, j.ProcedureLocation AS Location
	FROM Jobs j WITH(NOLOCK)
	WHERE j.JobName=@JobName AND LTRIM(RTRIM(ISNULL(j.ProcedureLocation, ''))) <> ''
	UNION
	SELECT 'Specification' AS WIType, 'https://hwqaweb.rim.net/pls/trs/data_entry.main?req=QRA-ENG-SP-11-0001' AS Location
	UNION
	SELECT 'QAP' As WIType, p.QAPLocation AS Location
	FROM Products p WITH(NOLOCK)
	WHERE p.ID=@ProductID AND LTRIM(RTRIM(ISNULL(QAPLocation, ''))) <> ''

	DROP TABLE #view
END
GO
GRANT EXECUTE ON remispGetBatchDocuments TO REMI
GO
ALTER PROCEDURE [Req].[RequestSearch] @RequestTypeID INT, @tv dbo.SearchFields READONLY, @UserID INT = NULL
AS
BEGIN
	SET NOCOUNT ON
	CREATE TABLE dbo.#executeSQL (ID INT IDENTITY(1,1), sqlvar NTEXT)
	CREATE TABLE dbo.#Request (RequestID INT PRIMARY KEY, BatchID INT, RequestNumber NVARCHAR(11))
	CREATE TABLE dbo.#Infos (Name NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS, Val NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS)
	CREATE TABLE dbo.#Params (Name NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS, Val NVARCHAR(250) COLLATE SQL_Latin1_General_CP1_CI_AS)
	CREATE TABLE dbo.#ReqNum (RequestNumber NVARCHAR(11) COLLATE SQL_Latin1_General_CP1_CI_AS)

	SELECT * INTO dbo.#temp FROM @tv
	
	UPDATE t
	SET t.ColumnName= '[' + rfs.Name + ']'
	FROM Req.ReqFieldSetup rfs WITH(NOLOCK)
		INNER JOIN dbo.#temp t WITH(NOLOCK) ON rfs.ReqFieldSetupID=t.ID
	WHERE rfs.RequestTypeID=@RequestTypeID AND t.TableType='Request'
	
	DECLARE @ProductGroupColumn NVARCHAR(150) 
	DECLARE @DepartmentColumn NVARCHAR(150)
	DECLARE @ColumnName NVARCHAR(255)
	DECLARE @whereStr NVARCHAR(MAX)
	DECLARE @whereStr2 NVARCHAR(MAX)
	DECLARE @whereStr3 NVARCHAR(MAX)
	DECLARE @rows NVARCHAR(MAX)
	DECLARE @ParameterColumnNames NVARCHAR(MAX)
	DECLARE @InformationColumnNames NVARCHAR(MAX)
	DECLARE @SQL NVARCHAR(MAX)
	DECLARE @RecordCount INT
	DECLARE @ByPassProductCheck INT
	SELECT @RecordCount = COUNT(*) FROM dbo.#temp 
	SET @ByPassProductCheck = 0
	SELECT @ByPassProductCheck = u.ByPassProduct FROM Users u WHERE u.ID=@UserID
	
	SELECT @ProductGroupColumn = fs.Name
	FROM Req.ReqFieldSetup fs 
		INNER JOIN Req.ReqFieldMapping fm ON fs.Name=fm.ExtField AND fs.RequestTypeID=fm.RequestTypeID
	WHERE fs.RequestTypeID = @RequestTypeID AND fm.IntField='ProductGroup'
	
	SELECT @DepartmentColumn = fs.Name
	FROM Req.ReqFieldSetup fs
		INNER JOIN Req.ReqFieldMapping fm ON fs.Name=fm.ExtField AND fs.RequestTypeID=fm.RequestTypeID
	WHERE fs.RequestTypeID = @RequestTypeID AND fm.IntField='Department'
	
	SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + rfs.Name
		FROM Req.ReqFieldSetup rfs WITH(NOLOCK)
		WHERE rfs.RequestTypeID=@RequestTypeID AND ISNULL(rfs.Archived, 0) = CONVERT(BIT, 0)
		ORDER BY '],[' +  rfs.Name
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

	SET @SQL = 'ALTER TABLE dbo.#Request ADD '+ replace(@rows, ']', '] NVARCHAR(4000)')
	EXEC sp_executesql @SQL	
	
	IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType = 'ReqNum') > 0)
		BEGIN
			INSERT INTO dbo.#ReqNum (RequestNumber)
			SELECT SearchTerm
			FROM dbo.#temp
			WHERE TableType = 'ReqNum'
		END

	SET @SQL = 'INSERT INTO dbo.#Request SELECT *
		FROM 
			(
			SELECT r.RequestID, r.BatchID, r.RequestNumber, rfd.Value, rfs.Name 
			FROM Req.Request r WITH(NOLOCK)
				INNER JOIN Req.ReqFieldData rfd WITH(NOLOCK) ON rfd.RequestID=r.RequestID
				INNER JOIN Req.ReqFieldSetup rfs WITH(NOLOCK) ON rfs.ReqFieldSetupID=rfd.ReqFieldSetupID
				INNER JOIN Req.RequestType rt WITH(NOLOCK) ON rt.RequestTypeID=rfs.RequestTypeID '
			
			IF ((SELECT COUNT(*) FROM dbo.#ReqNum) > 0)
				BEGIN
					SET @SQL += ' INNER JOIN dbo.#ReqNum rn WITH(NOLOCK) ON rn.RequestNumber=r.RequestNumber '
				END
				
			SET @SQL += ' WHERE rt.RequestTypeID=' + CONVERT(NVARCHAR, @RequestTypeID) + '
			) req PIVOT (MAX(Value) FOR Name IN (' + REPLACE(@rows, ',', ',
			') + ')) AS pvt '

	INSERT INTO #executeSQL (sqlvar)
	VALUES (@SQL)
	
	SET @SQL = ''
	
	IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType='Request') > 0)
	BEGIN
		INSERT INTO #executeSQL (sqlvar)
		VALUES (' WHERE ')

		DECLARE @ID INT
		SELECT @ID = MIN(ID) FROM dbo.#temp WHERE TableType='Request'

		WHILE (@ID IS NOT NULL)
		BEGIN
			INSERT INTO #executeSQL (sqlvar)
			VALUES ('
				(')

			IF ((SELECT TOP 1 1 FROM dbo.#temp WHERE ID = @ID AND TableType='Request' AND LTRIM(RTRIM(SearchTerm)) NOT LIKE '-%') = 1)
			BEGIN
				INSERT INTO #executeSQL (sqlvar)
				VALUES ('
						(')
			END

			DECLARE @NOLIKE INT
			SET @NOLIKE = 0
			SET @ColumnName = ''
			SET @whereStr = ''
			SELECT @ColumnName=ColumnName FROM dbo.#temp WHERE ID = @ID AND TableType='Request'

			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(SearchTerm)) + ''','
			FROM dbo.#temp
			WHERE ID = @ID AND TableType='Request' AND LTRIM(RTRIM(SearchTerm)) NOT LIKE '*%' AND LTRIM(RTRIM(SearchTerm)) NOT LIKE '-%'

			IF (LEN(LTRIM(RTRIM(@whereStr))) > 0)
			BEGIN
				INSERT INTO #executeSQL (sqlvar)
				VALUES (@ColumnName + ' IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')')
				SET @NOLIKE = 1
			END

			SET @whereStr = ''
			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(SearchTerm)) + ''','
			FROM dbo.#temp
			WHERE ID = @ID AND TableType='Request' AND LTRIM(RTRIM(SearchTerm)) LIKE '*%'

			SET @whereStr = REPLACE(REPLACE(REPLACE(@whereStr, '''*', 'LIKE ''%'), ''',', '%'''), 'LIKE ', ' OR ' + @ColumnName + ' LIKE ')

			IF (LEN(LTRIM(RTRIM(@whereStr))) > 0)
			BEGIN
				INSERT INTO #executeSQL (sqlvar)
				VALUES (CASE WHEN @NOLIKE = 0 THEN SUBSTRING(@whereStr,4, LEN(@whereStr)) ELSE @whereStr END)
			END

			IF ((SELECT TOP 1 1 FROM dbo.#temp WHERE ID = @ID AND TableType='Request' AND LTRIM(RTRIM(SearchTerm)) NOT LIKE '-%') = 1)
			BEGIN
				INSERT INTO #executeSQL (sqlvar)
				VALUES (')
						')
			END

			SET @whereStr = ''
			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(SearchTerm)) + ''','
			FROM dbo.#temp
			WHERE ID = @ID AND TableType='Request' AND LTRIM(RTRIM(SearchTerm)) LIKE '-%'

			SET @whereStr = REPLACE(REPLACE(REPLACE(@whereStr, '''-', 'NOT LIKE ''%'), ''',', '%'''), 'NOT LIKE ', ' AND ' + @ColumnName + ' NOT LIKE ')

			IF (LEN(LTRIM(RTRIM(@whereStr))) > 0)
			BEGIN
				IF ((SELECT TOP 1 1 FROM dbo.#temp WHERE ID = @ID AND TableType='Request' AND LTRIM(RTRIM(SearchTerm)) NOT LIKE '-%') = 1)
				BEGIN
					INSERT INTO #executeSQL (sqlvar)
					VALUES (@whereStr)
				END
				ELSE
				BEGIN
					INSERT INTO #executeSQL (sqlvar)
					VALUES (SUBSTRING(@whereStr, 6, LEN(@whereStr)))
				END
			END

			INSERT INTO #executeSQL (sqlvar)
			VALUES ('
				) AND ')

			SELECT @ID = MIN(ID) FROM dbo.#temp WHERE ID > @ID AND TableType='Request'
		END

		INSERT INTO #executeSQL (sqlvar)
		VALUES (' 1=1 ')
	END

	SET @SQL = REPLACE((select sqlvar AS [text()] from dbo.#executeSQL for xml path('')), '&#x0D;','')

	EXEC sp_executesql @SQL

	--START BUILDING MEASUREMENTS
	IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType NOT IN ('Request','ReqNum')) > 0)
	BEGIN
		SET @SQL = ''
		TRUNCATE TABLE dbo.#executeSQL

		CREATE TABLE dbo.#RR (RequestID INT, BatchID INT, RequestNumber NVARCHAR(11), BatchUnitNumber INT, UnitIMEI NVARCHAR(150), UnitBSN BIGINT, ID INT, ResultID INT, XMLID INT)
		CREATE TABLE dbo.#RRParameters (ResultMeasurementID INT)
		CREATE TABLE dbo.#RRInformation (RID INT, ResultInfoArchived BIT)
		
		CREATE INDEX [Request_BatchID] ON dbo.#Request([BatchID])

		SET @SQL = 'ALTER TABLE dbo.#RR ADD ' + replace(@rows, ']', '] NVARCHAR(4000)')
		EXEC sp_executesql @SQL

		ALTER TABLE dbo.#RR ADD ResultLink NVARCHAR(100), TestName NVARCHAR(400), TestStageName NVARCHAR(400), 
			TestRunStartDate DATETIME, TestRunEndDate DATETIME, 
			MeasurementName NVARCHAR(150), MeasurementValue NVARCHAR(500), 
			LowerLimit NVARCHAR(255), UpperLimit NVARCHAR(255), Archived BIT, Comment NVARCHAR(1000), 
			DegradationVal DECIMAL(10,3), MeasurementDescription NVARCHAR(800), PassFail BIT, ReTestNum INT,
			MeasurementUnitType NVARCHAR(150)

		INSERT INTO #executeSQL (sqlvar)
		VALUES ('INSERT INTO dbo.#RR 
		SELECT r.RequestID, r.BatchID, r.RequestNumber, tu.BatchUnitNumber, tu.IMEI, tu.BSN, m.ID, rs.ID AS ResultID, x.ID AS XMLID, ')

		SET @rows = REPLACE(@rows, '[', 'r.[')
		INSERT INTO #executeSQL (sqlvar)
		VALUES (@rows)

		INSERT INTO #executeSQL (sqlvar)
		VALUES (', (''http://go/remi/Relab/Measurements.aspx?ID='' + CONVERT(VARCHAR, rs.ID) + ''&Batch='' + CONVERT(VARCHAR, b.ID)) AS ResultLink ')
		
		INSERT INTO #executeSQL (sqlvar)
		VALUES (', t.TestName, ts.TestStageName, x.StartDate AS TestRunStartDate, x.EndDate AS TestRunEndDate, 
			mn.[Values] As MeasurementName, m.MeasurementValue, m.LowerLimit, m.UpperLimit, m.Archived, m.Comment, m.DegradationVal, m.Description AS MeasurementDescription, m.PassFail, m.ReTestNum, 
			mut.[Values] As MeasurementUnitType ')

		INSERT INTO #executeSQL (sqlvar)
		VALUES (' FROM dbo.#Request r WITH(NOLOCK)
			INNER JOIN dbo.Batches b WITH(NOLOCK) ON b.ID=r.BatchID
			INNER JOIN dbo.TestUnits tu WITH(NOLOCK) ON tu.BatchID=b.ID ')

		DECLARE @ResultArchived INT
		DECLARE @TestRunStartDate NVARCHAR(12)
		DECLARE @TestRunEndDate NVARCHAR(12)

		SELECT @ResultArchived = ID FROM dbo.#temp WHERE TableType='ResultArchived'
		SELECT @TestRunStartDate = SearchTerm FROM dbo.#temp WHERE TableType='TestRunStartDate'
		SELECT @TestRunEndDate = SearchTerm FROM dbo.#temp WHERE TableType='TestRunEndDate'

		IF @ResultArchived IS NULL
			SET @ResultArchived = 0

		INSERT INTO #executeSQL (sqlvar)
		VALUES ('INNER JOIN Relab.Results rs WITH(NOLOCK) ON rs.TestUnitID=tu.ID
			INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) ON m.ResultID=rs.ID
			INNER JOIN dbo.Lookups mn WITH(NOLOCK) ON mn.LookupID = m.MeasurementTypeID 
			LEFT OUTER JOIN dbo.Lookups mut WITH(NOLOCK) ON mut.LookupID = m.MeasurementUnitTypeID 
			INNER JOIN dbo.Tests t WITH(NOLOCK) ON rs.TestID=t.ID
			INNER JOIN dbo.TestStages ts WITH(NOLOCK) ON rs.TestStageID=ts.ID
			INNER JOIN dbo.Jobs j WITH(NOLOCK) ON j.ID=ts.JobID
			LEFT OUTER JOIN Relab.ResultsXML x WITH(NOLOCK) ON x.ID=m.XMLID
		WHERE ((' + CONVERT(NVARCHAR,@ResultArchived) + ' = 0 AND m.Archived=0) OR (' + CONVERT(NVARCHAR, @ResultArchived) + '=1)) ')

		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType = 'Measurement') > 0)
		BEGIN				
			SET @whereStr = ''
			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(SearchTerm)) + ''','
			FROM dbo.#temp
			WHERE TableType='Measurement' AND LTRIM(RTRIM(SearchTerm)) LIKE '*%'

			SET @whereStr = REPLACE(REPLACE(REPLACE(@whereStr, '''*', 'LIKE ''%'), ''',', '%'''), 'LIKE ', ' OR mn.[Values] LIKE ')

			INSERT INTO #executeSQL (sqlvar)
			VALUES ('AND ( ' + SUBSTRING(@whereStr,4, LEN(@whereStr)) + ' )')
		END

		IF (@TestRunStartDate IS NOT NULL AND @TestRunEndDate IS NOT NULL)
		BEGIN
			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND (x.StartDate >= ''' + CONVERT(NVARCHAR,@TestRunStartDate) + ' 00:00:00.000'' AND x.EndDate <= ''' + CONVERT(NVARCHAR,@TestRunEndDate) + ' 23:59:59'') ')
		END

		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType='Unit') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(ISNULL(SearchTerm, ''))) + ''','
			FROM dbo.#temp
			WHERE TableType = 'Unit'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND tu.BatchUnitNumber IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')')
		END

		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType='IMEI') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(ISNULL(SearchTerm, ''))) + ''','
			FROM dbo.#temp
			WHERE TableType = 'IMEI'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND tu.IMEI IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')')
		END

		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType='BSN') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(SearchTerm)) + ''','
			FROM dbo.#temp
			WHERE TableType = 'BSN'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND tu.BSN IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')')
		END

		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType='Test') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + LTRIM(RTRIM(ID)) + ','
			FROM dbo.#temp
			WHERE TableType = 'Test'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND t.ID IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')')
		END

		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType='Stage') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + LTRIM(RTRIM(ID)) + ','
			FROM dbo.#temp
			WHERE TableType = 'Stage'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND ts.ID IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ') ')
		END
		
		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType='Job') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + LTRIM(RTRIM(ID)) + ','
			FROM dbo.#temp
			WHERE TableType = 'Job'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND j.ID IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ') ')
		END
		
		SET @SQL =  REPLACE(REPLACE(REPLACE(REPLACE((select sqlvar AS [text()] from dbo.#executeSQL for xml path('')), '&#x0D;',''), '&gt;', ' >'), '&lt;', ' <'),'&amp;','&')
		EXEC sp_executesql @SQL

		SET @SQL = ''
		TRUNCATE TABLE dbo.#executeSQL

		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType LIKE 'Param:%') > 0)
		BEGIN
			INSERT INTO dbo.#Params (Name, Val)
			SELECT REPLACE(TableType, 'Param:', ''), SearchTerm
			FROM dbo.#temp
			WHERE TableType LIKE 'Param:%'
		END
		
		SELECT @ParameterColumnNames=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + rp.ParameterName
		FROM dbo.#RR rr WITH(NOLOCK)
			LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rr.ID=rp.ResultMeasurementID
		WHERE rp.ParameterName <> 'Command'
		ORDER BY '],[' +  rp.ParameterName
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

		IF (@ParameterColumnNames <> '[na]')
		BEGIN
			SET @SQL = 'ALTER TABLE dbo.#RRParameters ADD ' + replace(@ParameterColumnNames, ']', '] NVARCHAR(250)')
			EXEC sp_executesql @SQL
			SET @whereStr = ''
			
			DELETE p 
			FROM dbo.#Params p
			WHERE p.Name IN (SELECT Name
					FROM 
						(
							SELECT Name
							FROM #Params
						) param
					WHERE param.Name NOT IN (SELECT s FROM dbo.Split(',', LTRIM(RTRIM(REPLACE(REPLACE(@ParameterColumnNames, '[', ''), ']', ''))))))
			
			IF ((SELECT COUNT(*) FROM dbo.#Params) > 0)
			BEGIN
				SET @whereStr = ' WHERE '
				SET @whereStr2 = ''
				SET @whereStr3 = ''
				
				SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS params
				INTO #buildparamtable
				FROM #Params
				GROUP BY name
				
				SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS params
				INTO #buildparamtable2
				FROM #Params
				GROUP BY name
				
				SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS params
				INTO #buildparamtable3
				FROM #Params
				GROUP BY name
				
				UPDATE bt
				SET bt.params = REPLACE(REPLACE((
						SELECT ('''' + p.Val + ''',') As Val
						FROM #Params p
						WHERE p.Name = bt.Name AND Val NOT LIKE '*%' AND Val NOT LIKE '-%'
						FOR XML PATH('')), '<Val>', ''), '</Val>','')
				FROM #buildparamtable bt
				WHERE Params = ''
				
				UPDATE bt
				SET bt.params = REPLACE(REPLACE((
						SELECT ('LTRIM(RTRIM([' + Name + '])) LIKE ''' + REPLACE(p.Val, '*','%') + '%'' OR ') As Val
						FROM #Params p
						WHERE p.Name = bt.Name AND Val LIKE '*%' AND Val NOT LIKE '-%'
						FOR XML PATH('')), '<Val>', ''), '</Val>','')
				FROM #buildparamtable2 bt
				WHERE Params = '' OR Params IS NULL
				
				UPDATE bt
				SET bt.params = REPLACE(REPLACE((
						SELECT ('LTRIM(RTRIM([' + Name + '])) NOT LIKE ''' + REPLACE(p.Val, '-','%') + '%'' OR ') As Val
						FROM #Params p
						WHERE p.Name = bt.Name AND Val LIKE '-%'
						FOR XML PATH('')), '<Val>', ''), '</Val>','')
				FROM #buildparamtable3 bt
				WHERE Params = '' OR Params IS NULL
				
				SELECT @whereStr = COALESCE(@whereStr + '' ,'') + 'LTRIM(RTRIM([' + Name + '])) IN (' + SUBSTRING(params, 0, LEN(params)) + ') AND ' 
				FROM dbo.#buildparamtable 
				WHERE Params IS NOT NULL
				
				IF (@whereStr <> ' WHERE ')
					SET @whereStr = SUBSTRING(@whereStr, 0, LEN(@whereStr)-2)

				SELECT @whereStr2 += COALESCE(@whereStr2 + '' ,'') + ' ( ' + SUBSTRING(params, 0, LEN(params)-1) + ' ) '
				FROM dbo.#buildparamtable2 
				WHERE Params IS NOT NULL
				
				IF @whereStr2 IS NOT NULL AND LTRIM(RTRIM(@whereStr2)) <> ''
				BEGIN						
					IF (@whereStr <> ' WHERE ')
						SET @whereStr2 = ' AND ' + @whereStr2
					ELSE
						SET @whereStr2 = @whereStr2
				END
				
				SELECT @whereStr3 += COALESCE(@whereStr3 + '' ,'') + ' ( ' + SUBSTRING(params, 0, LEN(params)-1) + ' ) '
				FROM dbo.#buildparamtable3
				WHERE Params IS NOT NULL
				
				IF @whereStr3 IS NOT NULL AND LTRIM(RTRIM(@whereStr3)) <> ''
				BEGIN						
					IF (@whereStr <> ' WHERE ')
						SET @whereStr3 = ' AND ' + @whereStr3
					ELSE
						SET @whereStr3 = @whereStr3
				END
											
				SET @whereStr = REPLACE(@whereStr + @whereStr2 + @whereStr3,'&amp;','&')				

				DROP TABLE #buildparamtable
				DROP TABLE #buildparamtable2
			END

			SET @SQL = 'INSERT INTO dbo.#RRParameters SELECT *
			FROM (
				SELECT rp.ResultMeasurementID, rp.ParameterName, rp.Value
				FROM dbo.#RR rr WITH(NOLOCK)
					INNER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rr.ID=rp.ResultMeasurementID
				) te PIVOT (MAX(Value) FOR ParameterName IN (' + @ParameterColumnNames + ')) AS pvt
			 ' + @whereStr
				
			EXEC sp_executesql @SQL
		END
		ELSE
		BEGIN
			SET @ParameterColumnNames = NULL
		END

		DECLARE @ResultInfoArchived INT
		SELECT @ResultInfoArchived = ID FROM dbo.#temp WHERE TableType='ResultInfoArchived'

		IF @ResultInfoArchived IS NULL
			SET @ResultInfoArchived = 0
							
		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType LIKE 'Info:%') > 0)
		BEGIN
			INSERT INTO dbo.#Infos (Name, Val)
			SELECT REPLACE(TableType, 'Info:', ''), SearchTerm
			FROM dbo.#temp
			WHERE TableType LIKE 'Info:%'
		END

		SELECT @InformationColumnNames=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + ri.Name
		FROM dbo.#RR rr WITH(NOLOCK)
			INNER JOIN Relab.ResultsXML x WITH(NOLOCK) ON x.ResultID = rr.ResultID
			LEFT OUTER JOIN Relab.ResultsInformation ri WITH(NOLOCK) ON x.ID=ri.XMLID
		WHERE ri.Name NOT IN ('Start UTC','Start','End', 'STEF Plugin Version')
			AND ((@ResultInfoArchived = 0 AND ri.IsArchived=0) OR (@ResultInfoArchived=1))
		ORDER BY '],[' +  ri.Name
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

		IF (@InformationColumnNames <> '[na]')
		BEGIN
			SET @SQL = 'ALTER TABLE dbo.#RRInformation ADD ' + replace(@InformationColumnNames, ']', '] NVARCHAR(250)')
			EXEC sp_executesql @SQL
			
			SET @whereStr = ''
			
			DELETE i 
			FROM dbo.#infos i
			WHERE i.Name IN (SELECT Name
					FROM 
						(
							SELECT Name
							FROM #Infos
						) inf
					WHERE inf.Name NOT IN (SELECT s FROM dbo.Split(',', LTRIM(RTRIM(REPLACE(REPLACE(@InformationColumnNames, '[', ''), ']', ''))))))

			IF ((SELECT COUNT(*) FROM dbo.#Infos) > 0)
			BEGIN
				SET @whereStr = ' WHERE '
				SET @whereStr2 = ''
				SET @whereStr3 = ''
				
				SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS info
				INTO #buildinfotable
				FROM dbo.#infos
				GROUP BY name
				
				SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS info
				INTO #buildinfotable2
				FROM dbo.#infos
				GROUP BY name
				
				SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS info
				INTO #buildinfotable3
				FROM dbo.#infos
				GROUP BY name
				
				UPDATE bt
				SET bt.info = REPLACE(REPLACE((
						SELECT ('''' + i.Val + ''',') As Val
						FROM dbo.#infos i
						WHERE i.Name = bt.Name AND Val NOT LIKE '*%' AND Val NOT LIKE '-%'
						FOR XML PATH('')), '<Val>', ''), '</Val>','')
				FROM #buildinfotable bt
				WHERE info = ''
				
				UPDATE bt
				SET bt.info = REPLACE(REPLACE((
						SELECT ('LTRIM(RTRIM([' + Name + '])) LIKE ''' + REPLACE(i.Val, '*','%') + '%'' OR ') As Val
						FROM dbo.#infos i
						WHERE i.Name = bt.Name AND Val LIKE '*%'
						FOR XML PATH('')), '<Val>', ''), '</Val>','')
				FROM #buildinfotable2 bt
				WHERE info = '' OR info IS NULL
				
				UPDATE bt
				SET bt.info = REPLACE(REPLACE((
						SELECT ('LTRIM(RTRIM([' + Name + '])) NOT LIKE ''' + REPLACE(i.Val, '-','%') + '%'' OR ') As Val
						FROM dbo.#infos i
						WHERE i.Name = bt.Name AND Val LIKE '-%'
						FOR XML PATH('')), '<Val>', ''), '</Val>','')
				FROM #buildinfotable3 bt
				WHERE info = '' OR info IS NULL
									
				SELECT @whereStr = COALESCE(@whereStr + '' ,'') + 'LTRIM(RTRIM([' + Name + '])) IN (' + SUBSTRING(info, 0, LEN(info)) + ') AND ' 
				FROM dbo.#buildinfotable 
				WHERE info IS NOT NULL 
				
				IF (@whereStr <> ' WHERE ')
					SET @whereStr = SUBSTRING(@whereStr, 0, LEN(@whereStr)-2)
									
				SELECT @whereStr2 += COALESCE(@whereStr2 + '' ,'') + ' ( ' + SUBSTRING(info, 0, LEN(info)-1) + ' ) '
				FROM dbo.#buildinfotable2 
				WHERE info IS NOT NULL 
				
				IF @whereStr2 IS NOT NULL AND LTRIM(RTRIM(@whereStr2)) <> ''
				BEGIN						
					IF (@whereStr <> ' WHERE ')
						SET @whereStr2 = ' AND ' + @whereStr2
					ELSE
						SET @whereStr2 = @whereStr2
				END						
				
				SELECT @whereStr3 += COALESCE(@whereStr3 + '' ,'') + ' ( ' + SUBSTRING(info, 0, LEN(info)-1) + ' ) '
				FROM dbo.#buildinfotable3 
				WHERE info IS NOT NULL 
				
				IF @whereStr3 IS NOT NULL AND LTRIM(RTRIM(@whereStr3)) <> ''
				BEGIN						
					IF (@whereStr <> ' WHERE ')
						SET @whereStr3 = ' AND ' + @whereStr3
					ELSE
						SET @whereStr3 = @whereStr3
				END
											
				SET @whereStr = REPLACE(@whereStr + @whereStr2 + @whereStr3,'&amp;','&')

				DROP TABLE #buildinfotable
				DROP TABLE #buildinfotable2
			END

			SET @SQL = N'INSERT INTO dbo.#RRInformation SELECT *
			FROM (
				SELECT rr.ResultID AS RID, ri.IsArchived AS ResultInfoArchived, ri.Name, ri.Value
				FROM dbo.#RR rr WITH(NOLOCK)
					INNER JOIN Relab.ResultsInformation ri WITH(NOLOCK) ON rr.XMLID=ri.XMLID
					WHERE ri.Name NOT IN (''Start UTC'',''Start'',''End'', ''STEF Plugin Version'') AND
						((@ResultInfoArchived = 0 AND ri.IsArchived=0) OR (@ResultInfoArchived=1)) 
				) te PIVOT (MAX(Value) FOR Name IN ('+ @InformationColumnNames +')) AS pvt
			' + @whereStr

			EXEC sp_executesql @SQL, N'@ResultInfoArchived int', @ResultInfoArchived
		END
		ELSE
		BEGIN
			SET @InformationColumnNames = NULL
		END

		SET @whereStr = ''

		IF (@UserID > 0 AND @UserID IS NOT NULL)
		BEGIN
			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + LTRIM(RTRIM(ColumnName)) + ','
			FROM dbo.UserSearchFilter
			WHERE UserID=@UserID AND RequestTypeID=@RequestTypeID
			ORDER BY SortOrder
		END
		
		DECLARE @LimitedByInfo INT
		DECLARE @LimitedByParam INT
		SET @LimitedByParam = 0
		SET @LimitedByInfo = 0
		
		IF ((SELECT COUNT(*) FROM dbo.#Infos) > 0)
			SET @LimitedByInfo = 1
		
		IF ((SELECT COUNT(*) FROM dbo.#Params) > 0)
			SET @LimitedByParam = 1

		SET @whereStr = REPLACE(REPLACE(@whereStr 
				, 'Params', CASE WHEN (SELECT 1 FROM UserSearchFilter WHERE FilterType=3) = 1 THEN @ParameterColumnNames ELSE '' END)
				, 'Info', CASE WHEN (SELECT 1 FROM UserSearchFilter WHERE FilterType=4) = 1 THEN @InformationColumnNames ELSE '' END)

		IF (ISNULL(@whereStr, '') = '')
		BEGIN
			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + '[' + COLUMN_NAME + '],' 
			FROM tempdb.INFORMATION_SCHEMA.COLUMNS 
			WHERE (TABLE_NAME like '#RR%' OR TABLE_NAME LIKE '#RRParameters%' OR TABLE_NAME LIKE '#RRInformation%')
				AND COLUMN_NAME NOT IN ('RequestID', 'XMLID', 'ID', 'BatchID', 'ResultID', 'RID', 'ResultMeasurementID')
			ORDER BY TABLE_NAME
		END
		
		SET @whereStr = SUBSTRING(@whereStr, 0, LEN(@whereStr))

		SET @SQL = 'SELECT DISTINCT ' + @whereStr + '
			FROM dbo.#RR rr 
				LEFT OUTER JOIN dbo.#RRParameters p ON rr.ID=p.ResultMeasurementID
				LEFT OUTER JOIN dbo.#RRInformation i ON i.RID = rr.ResultID
			WHERE ((' + CONVERT(NVARCHAR, @LimitedByInfo) + ' = 0) OR (' + CONVERT(NVARCHAR, @LimitedByInfo) + ' = 1 AND i.RID IS NOT NULL ))
				AND ((' + CONVERT(NVARCHAR, @LimitedByParam) + ' = 0) OR (' + CONVERT(NVARCHAR, @LimitedByParam) + ' = 1 AND p.ResultMeasurementID IS NOT NULL )) '
		
		IF (@SQL LIKE '%[' + @ProductGroupColumn + ']%' AND @UserID IS NOT NULL)
		BEGIN
			SET @SQL += 'AND (' + CONVERT(NVARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(NVARCHAR, @ByPassProductCheck) + ' = 0 
																	AND [' + @ProductGroupColumn + '] COLLATE SQL_Latin1_General_CP1_CI_AS IN (SELECT p.[values] 
																FROM UsersProducts up 
																	INNER JOIN Lookups p ON p.LookupID=up.ProductID 
																WHERE UserID=' + CONVERT(NVARCHAR, @UserID) + '))) '
		END
		
		IF (@SQL LIKE '%[' + @DepartmentColumn + ']%' AND @UserID IS NOT NULL)
		BEGIN
			SET @SQL += ' AND ([' + @DepartmentColumn + '] COLLATE SQL_Latin1_General_CP1_CI_AS IN (SELECT lt.[Values]
															FROM UserDetails ud
																INNER JOIN Lookups lt ON lt.LookupID=ud.LookupID
															WHERE ud.UserID=' + CONVERT(NVARCHAR, @UserID) + ')) '
		END
		
		print @SQL
		EXEC sp_executesql @SQL

		DROP TABLE dbo.#RRParameters
		DROP TABLE dbo.#RRInformation
		DROP TABLE dbo.#RR
	END
	ELSE
	BEGIN
		SET @whereStr = ''

		IF (@UserID > 0 AND @UserID IS NOT NULL)
		BEGIN
			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + LTRIM(RTRIM(ColumnName)) + ','
			FROM dbo.UserSearchFilter
			WHERE UserID=@UserID AND FilterType = 1 AND RequestTypeID=@RequestTypeID 
			ORDER BY SortOrder
		END

		IF (ISNULL(@whereStr, '') = '')
		BEGIN
			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + '[' + COLUMN_NAME + '],' 
			FROM tempdb.INFORMATION_SCHEMA.COLUMNS 
			WHERE (TABLE_NAME like '#Request%') AND COLUMN_NAME NOT IN ('RequestID', 'BatchID')
			ORDER BY TABLE_NAME
		END

		SET @whereStr = SUBSTRING(@whereStr, 0, LEN(@whereStr))

		SET @SQL = 'SELECT DISTINCT ' + CASE WHEN @RecordCount = 0 THEN 'TOP 20' ELSE '' END + @whereStr + ' 
					FROM dbo.#Request r 
					WHERE (1=1)'

		IF (@SQL LIKE '%[' + @ProductGroupColumn + ']%' AND @UserID IS NOT NULL)
		BEGIN
			SET @SQL += 'AND (' + CONVERT(NVARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(NVARCHAR, @ByPassProductCheck) + ' = 0 
															AND [' + @ProductGroupColumn + '] COLLATE SQL_Latin1_General_CP1_CI_AS IN (SELECT p.[values] 
																FROM UsersProducts up 
																	INNER JOIN Lookups p ON p.LookupID=up.ProductID 
																WHERE UserID=' + CONVERT(NVARCHAR, @UserID) + '))) '
		END
		
		IF (@SQL LIKE '%[' + @DepartmentColumn + ']%' AND @UserID IS NOT NULL)
		BEGIN
			SET @SQL += ' AND ([' + @DepartmentColumn + '] COLLATE SQL_Latin1_General_CP1_CI_AS IN (SELECT lt.[Values]
															FROM UserDetails ud
																INNER JOIN Lookups lt ON lt.LookupID=ud.LookupID
															WHERE ud.UserID=' + CONVERT(NVARCHAR, @UserID) + ')) '
		END
		
		SET @SQL += ' ORDER BY RequestNumber DESC '
		EXEC sp_executesql @SQL
	END

	DROP TABLE dbo.#executeSQL
	DROP TABLE dbo.#temp
	DROP TABLE dbo.#Request
	DROP TABLE dbo.#Infos
	DROP TABLE dbo.#ReqNum
	DROP TABLE dbo.#Params
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Req].[RequestSearch] TO REMI
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