BEGIN TRAN
EXEC sp_rename 'dbo.UsersProducts', '_UsersProducts'
EXEC sp_rename 'dbo.UsersProductsAudit', '_UsersProductsAudit'

ALTER TABLE dbo.UserDetails ADD IsProductManager BIT DEFAULT(0) NULL
ALTER TABLE dbo.UserDetails ADD LastUser NVARCHAR(255) NULL

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION dbo.remifnUserCanDelete (@UserName NVARCHAR(255))
RETURNS BIT
AS
BEGIN
	DECLARE @Exists BIT
	SET @UserName = LTRIM(RTRIM(@UserName))
	
	SELECT @Exists = (SELECT DISTINCT 0
		FROM BatchComments
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM Batches
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM BatchSpecificTestDurations
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM Jobs
		WHERE LTRIM(RTRIM(LastUser))=@UserName	
		UNION
		SELECT DISTINCT 0
		FROM ProductConfiguration
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM ProductConfigValues
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM ProductSettings
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM StationConfigurationUpload
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TestExceptions
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TestRecords
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM Tests
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM Tests
		WHERE LTRIM(RTRIM(Owner))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM Tests
		WHERE LTRIM(RTRIM(Trainee))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TestStages
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TestUnits
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TrackingLocations
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION 
		SELECT DISTINCT 0
		FROM TrackingLocationsHosts
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION 
		SELECT DISTINCT 0
		FROM TrackingLocationsHostsConfiguration
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION 
		SELECT DISTINCT 0
		FROM TrackingLocationsHostsConfigValues
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TrackingLocationTypePermissions
		WHERE LTRIM(RTRIM(LastUser))=@UserName OR LTRIM(RTRIM(UserName))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TaskAssignments
		WHERE LTRIM(RTRIM(AssignedTo))=@UserName OR LTRIM(RTRIM(AssignedBy))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TrackingLocationTypes
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM UserDetails
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM UserTraining
		WHERE LTRIM(RTRIM(UserAssigned))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM ProductConfigurationUpload
		WHERE LTRIM(RTRIM(LastUser))=@UserName)
	
	RETURN ISNULL(@Exists, 1)
END
GO
GRANT EXECUTE ON remifnUserCanDelete TO Remi
GO
ALTER PROCEDURE [dbo].[remispModifyUserToBasicAccess] @UserName NVARCHAR(255)
AS
BEGIN
	DECLARE @UserID INT
	DECLARE @UserIDGuid UNIQUEIDENTIFIER
	DECLARE @RoleID UNIQUEIDENTIFIER
	SELECT @UserID=ID FROM Users WHERE LDAPLogin=@UserName
	SELECT @UserIDGuid = UserID FROM aspnet_Users WHERE UserName=@UserName
	SELECT @RoleID = RoleID FROM aspnet_Roles WHERE RoleName='LabTestAssociate'
	
	DELETE FROM UserDetails WHERE UserID=@UserID
	
	UPDATE Users SET ByPassProduct=0 WHERE ID=@UserID
	DELETE FROM aspnet_UsersInRoles WHERE UserId=@UserIDGuid AND RoleId <> @RoleID
	DELETE FROM UserTraining WHERE UserID=@UserID
END
GO
GRANT EXECUTE ON [remispModifyUserToBasicAccess] TO REMI
GO
alter PROCEDURE [dbo].[remispGetUser] @SearchBy INT, @SearchStr NVARCHAR(255)
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

	EXEC Req.remispGetRequestTypes @UserName
	
	SELECT s.ServiceID, s.ServiceName, l.[Values] AS Department
	FROM UserDetails ud
		INNER JOIN Lookups l ON l.LookupID=ud.LookupID
		INNER JOIN LookupType lt ON lt.LookupTypeID=l.LookupTypeID
		INNER JOIN ServicesAccess sa ON sa.LookupID=l.LookupID
		INNER JOIN Services s ON sa.ServiceID=s.ServiceID 
	WHERE ud.UserID=@UserID AND lt.Name='Department' AND ISNULL(s.IsActive, 0) = 1
GO
GRANT EXECUTE ON remispGetUser TO Remi
GO
DROP PROCEDURE remispProductManagersSelectList
GO
ALTER PROCEDURE remispGetUserDetails @UserID INT
AS
BEGIN
	SELECT lt.Name, l.[Values], l.LookupID, ISNULL(ud.IsDefault, 0) AS IsDefault, ud.IsProductManager
	FROM UserDetails ud
		INNER JOIN Lookups l ON l.LookupID=ud.LookupID
		INNER JOIN LookupType lt ON lt.LookupTypeID=l.LookupTypeID
	WHERE ud.UserID=@UserID
	ORDER BY lt.Name, l.[Values]
END
GO
GRANT EXECUTE ON remispGetUserDetails TO REMI
GO
ALTER PROCEDURE [dbo].[remispGetProducts] @ByPassProductCheck INT, @UserID INT, @ShowArchived INT
AS
BEGIN
	DECLARE @TrueBit BIT
	SET @TrueBit = CONVERT(BIT, 1)

	SELECT ID, lp.[values] AS ProductGroupName
	FROM Products p WITH(NOLOCK)
		INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
	WHERE (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND lp.LookupID IN (SELECT LookupID FROM UserDetails WITH(NOLOCK) WHERE UserID=@UserID)))
		AND
		(
			(@ShowArchived = 1)
			OR
			(@ShowArchived = 0 AND lp.IsActive = @TrueBit)
		)
	ORDER BY ProductGroupname
END
GO
GRANT EXECUTE ON remispGetProducts TO Remi
GO
ALTER PROCEDURE [dbo].[remispYourBatchesGetActiveBatches] @UserID int, @ByPassProductCheck INT = 0, @Year INT = 0, @OnlyShowQRAWithResults INT = 0
AS	
SELECT b.ID, lp.[Values] AS ProductGroupName,b.QRANumber, (b.QRANumber + ' ' + lp.[Values]) AS Name
	FROM Batches as b WITH(NOLOCK)
	INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
	INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
WHERE ( 
		(@Year = 0 AND BatchStatus NOT IN(5,7))
		OR
		(@Year > 0 AND b.QRANumber LIKE '%-' + RIGHT(CONVERT(NVARCHAR, @Year), 2) + '-%')
	  )
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND lp.LookupID IN (SELECT up.LookupID FROM UserDetails up WITH(NOLOCK) WHERE UserID=@UserID)))
	AND (@OnlyShowQRAWithResults = 0 OR (@OnlyShowQRAWithResults = 1 AND b.ID IN (SELECT tu.BatchID FROM Relab.Results r WITH(NOLOCK) INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID)))
	AND (b.DepartmentID IN (SELECT ud.LookupID 
							FROM UserDetails ud WITH(NOLOCK)
								INNER JOIN Lookups lt WITH(NOLOCK) ON lt.LookupID=ud.LookupID
							WHERE ud.UserID=@UserID))
ORDER BY b.QRANumber DESC
RETURN
GO
GRANT EXECUTE ON remispYourBatchesGetActiveBatches TO Remi
GO
ALTER procedure [dbo].[remispUsersSearch] @ProductID INT = 0, @TestCenterID INT = 0, @TrainingID INT = 0, @TrainingLevelID INT = 0, @ByPass INT = 0, @showAllGrid BIT = 0, @UserID INT = 0, @DepartmentID INT = 0, @DetermineDelete INT = 1,  @IncludeInActive INT = 1
AS
BEGIN	
	IF (@showAllGrid = 0)
	BEGIN
		SELECT ID, LDAPLogin, BadgeNumber, ByPassProduct, DefaultPage, ISNULL(IsActive, 1) AS IsActive, LastUser, 
				ConcurrencyID, CASE WHEN @DetermineDelete = 1 THEN dbo.remifnUserCanDelete(LDAPLogin) ELSE 0 END AS CanDelete
		FROM 
			(SELECT DISTINCT u.ID, u.LDAPLogin, u.BadgeNumber, u.ByPassProduct, u.DefaultPage, ISNULL(u.IsActive, 1) AS IsActive, u.LastUser, 
				u.ConcurrencyID
			 FROM Users u
				LEFT OUTER JOIN UserTraining ut ON ut.UserID = u.ID
				INNER JOIN UserDetails udtc ON udtc.UserID=u.ID
				INNER JOIN UserDetails udd ON udd.UserID=u.ID
				LEFT OUTER JOIN UserDetails udp ON udp.UserID=u.ID
				LEFT OUTER JOIN Products p ON p.LookupID=udp.LookupID
			WHERE (
					(@IncludeInActive = 0 AND ISNULL(u.IsActive, 1)=1)
					OR
					@IncludeInActive = 1
				  )
				  AND 
				  (
					(udtc.LookupID=@TestCenterID) 
					OR
					(@TestCenterID = 0)
				  )
				  AND
				  (
					(ut.LookupID=@TrainingID) 
					OR
					(@TrainingID = 0)
				  )
				  AND
				  (
					(ut.LevelLookupID=@TrainingLevelID) 
					OR
					(@TrainingLevelID = 0)
				  )
				  AND
				  (
					(u.ByPassProduct=@ByPass) 
					OR
					(@ByPass = 0)
				  )
				  AND
				  (
					(p.ID=@ProductID) 
					OR
					(@ProductID = 0)
				  )
				  AND 
				  (
					(udd.LookupID=@DepartmentID) 
					OR
					(@DepartmentID = 0)
				  )
			) AS UsersRows
			ORDER BY LDAPLogin
	END
	ELSE
	BEGIN
		DECLARE @rows VARCHAR(8000)
		DECLARE @query VARCHAR(4000)
		SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + l.[Values]
		FROM Lookups l
			INNER JOIN LookupType lt ON lt.LookupTypeID=l.LookupTypeID
		WHERE lt.Name='Training' And l.IsActive=1
		AND (
				(l.LookupID=@TrainingID) 
				OR
				(@TrainingID = 0)
			  )
		ORDER BY '],[' + l.[Values]
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

		SET @query = '
			SELECT *
			FROM
			(
				SELECT CASE WHEN ut.lookupID IS NOT NULL THEN (CASE WHEN ut.LevelLookupID IS NULL THEN ''*'' ELSE (SELECT SUBSTRING([values], 1, 1) FROM Lookups WHERE LookupID=LevelLookupID) END) ELSE NULL END As Row, u.LDAPLogin, l.[values] As Training
				FROM Users u WITH(NOLOCK)
					LEFT OUTER JOIN UserTraining ut ON ut.UserID = u.ID
					LEFT OUTER JOIN Lookups l on l.lookupid=ut.lookupid
					INNER JOIN UserDetails ud ON ud.UserID=u.ID
				WHERE u.IsActive = 1 AND (
				(ud.lookupid=' + CONVERT(VARCHAR, @TestCenterID) + ') 
				OR
				(' + CONVERT(VARCHAR, @TestCenterID) + ' = 0)
			  )
			  AND
			  (
				(ut.LookupID=' + CONVERT(VARCHAR, @TrainingID) + ') 
				OR
				(' + CONVERT(VARCHAR, @TrainingID) + ' = 0)
			  )
			  AND
			  (
				(u.ID=' + CONVERT(VARCHAR, @UserID) + ')
				OR
				(' + CONVERT(VARCHAR, @UserID) + ' = 0)
			  )
			)r
			PIVOT 
			(
				MAX(row) 
				FOR Training 
					IN ('+@rows+')
			) AS pvt'
		EXECUTE (@query)	
	END
END
GO
GRANT EXECUTE ON remispUsersSearch TO REMI
GO
ALTER PROCEDURE [dbo].[remispUsersDeleteSingleItem] @userIDToDelete nvarchar(255), @UserID INT
AS
	UPDATE Users 
	SET LastUser = (SELECT LDAPLogin FROM Users WHERE ID=@UserID)
	WHERE ID = @userIDToDelete

	DELETE FROM UserSearchFilter WHERE UserID = @userIDToDelete
	DELETE FROM UserDetails WHERE UserID=@userIDToDelete
	DELETE FROM UserTraining WHERE UserID=@userIDToDelete
	DELETE FROM users WHERE ID = @userIDToDelete
GO
GRANT EXECUTE ON remispUsersDeleteSingleItem TO Remi
GO
DROP PROCEDURE remispProductManagersAssignUser
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectChamberBatches]
/*	'===============================================================
	'   NAME:                	remispBatchesSelectDailyList
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retreives the batches in chamber
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/

	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@TestCentreLocation Int =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc',
	@ByPassProductCheck INT = 0,
	@UserID int
	AS
SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
	BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName,
	batchesrows.ProductID,batchesrows.QRANumber,
	BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName, 
	batchesrows.TestStageCompletionStatus,testunitcount,
	(CASE WHEN batchesrows.WILocation IS NULL THEN NULL ELSE batchesrows.WILocation END) AS jobWILocation,
	(testUnitCount -
		(select COUNT(*) 
			  from TestUnits as tu WITH(NOLOCK)
			  INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			  where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
	) as HasUnitsToReturnToRequestor,
	ISNULL(
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
			WHERE ta.BatchID = BatchesRows.ID and ta.Active=1), 
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
			WHERE ta.Active=1 AND ISNULL(ta.taskID,0) = 0 AND ta.BatchID = BatchesRows.ID)
		) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions,
	batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,batchesrows.RQID As ReqID, batchesrows.TestCenterLocationID,
	AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate, IsMQual, JobID, MechanicalTools, BatchesRows.RequestPurposeID,
	BatchesRows.PriorityID, DepartmentID, Department, Requestor
	FROM     
	(
		SELECT ROW_NUMBER() OVER 
			(ORDER BY 
				case when @sortExpression='qra' and @direction='asc' then qranumber end,
				case when @sortExpression='qra' and @direction='desc' then qranumber end desc,
				case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
				case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
				case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
				case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
				case when @sortExpression='job' and @direction='asc' then jobname end,
				case when @sortExpression='job' and @direction='desc' then jobname end desc,
				case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
				case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
				case when @sortExpression='priority' and @direction='asc' then Priority end asc,
				case when @sortExpression='priority' and @direction='desc' then Priority end desc,
				case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
				case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
				case when @sortExpression is null then Priority end desc
			) AS Row, 
			ID, 
			QRANumber, 
			Comment,
			RequestPurpose, 
			Priority,
			TestStageName, 
			BatchStatus, 
			ProductGroupName, 
			ProductType,
			AccessoryGroupName,
			ProductTypeID,
			AccessoryGroupID,
			ProductID,
			JobName, 
			TestCenterLocationID,
			TestCenterLocation,
			LastUser, 
			ConcurrencyID,
			b.TestStageCompletionStatus,
			(select count(*) from testunits WITH(NOLOCK) where testunits.batchid = b.id) as testUnitCount,
			b.WILocation,b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, JobID, MechanicalTools,
			RequestPurposeID, PriorityID, DepartmentID, Department, Requestor
		FROM 
		(
			SELECT DISTINCT b.ID, 
				b.QRANumber, 
				b.Comment,
				b.RequestPurpose As RequestPurposeID, 
				b.Priority AS PriorityID,
				b.TestStageName, 
				b.BatchStatus, 
				lp.[Values] AS ProductGroupName, 
				b.ProductTypeID,
				b.AccessoryGroupID,
				l.[Values] AS ProductType,
				l2.[Values] As AccessoryGroupName,
				p.ID As ProductID,
				b.JobName, 
				b.LastUser, 
				b.TestCenterLocationID,
				l3.[Values] As TestCenterLocation,
				b.ConcurrencyID,
				b.TestStageCompletionStatus, j.WILocation,b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, 
				b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, MechanicalTools, l4.[Values] As RequestPurpose, l5.[Values] As Priority, b.DepartmentID, l6.[Values] AS Department,
				b.Requestor
			FROM Batches AS b WITH(NOLOCK)
				LEFT OUTER JOIN Jobs as j WITH(NOLOCK) on b.jobname = j.JobName 
				inner join TestStages as ts WITH(NOLOCK) on j.ID = ts.JobID
				inner join Tests as t WITH(NOLOCK) on ts.TestID = t.ID
				inner join DeviceTrackingLog AS dtl WITH(NOLOCK) 
				INNER JOIN TrackingLocations AS tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.ID
				INNER JOIN TrackingLocationTypes as tlt WITH(NOLOCK) on tl.TrackingLocationTypeID = tlt.id 
				inner join TestUnits AS tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID on tu.CurrentTestName = t.TestName and b.id = tu.batchid  --batches where there's a tracking log
				INNER JOIN Products p WITH(NOLOCK) ON b.ProductID=p.id
				INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON b.TestCenterLocationID=l3.LookupID  
				LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON b.RequestPurpose=l4.LookupID   
				LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON b.Priority=l5.LookupID
				LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON b.DepartmentID=l6.LookupID
			WHERE (b.TestCenterLocationID = @TestCentreLocation or @TestCentreLocation is null) and j.TechnicalOperationsTest = 1 and j.MechanicalTest=0 and  tlt.TrackingLocationFunction= 4  and t.ResultBasedOntime = 1 AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL
			AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.LookupID IN (SELECT ud.LookupID FROM UserDetails ud WITH(NOLOCK) WHERE UserID=@UserID)))
		)as b
	) as batchesrows
 	WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex = -1 OR @maximumRows = -1) 
GO
GRANT EXECUTE ON remispBatchesSelectChamberBatches TO Remi
GO
DROP PROCEDURE remispProductManagersDeleteSingleItem
GO
ALTER PROCEDURE [dbo].[remispBatchesSearch]
	@ByPassProductCheck INT = 0,
	@ExecutingUserID int,
	@Status int = null,
	@Priority int = null,
	@UserID int = null,
	@TrackingLocationID int = null,
	@TestStageID int = null,
	@TestID int = null,
	@ProductTypeID int = null,
	@ProductID int = null,
	@AccessoryGroupID int = null,
	@GeoLocationID INT = null,
	@JobName nvarchar(400) = null,
	@RequestReason int = null,
	@StartRowIndex int = null,
	@MaximumRows int = null,
	@BatchStart DateTime = NULL,
	@BatchEnd DateTime = NULL,
	@TestStage NVARCHAR(400) = NULL,
	@TestStageType INT = NULL,
	@excludedTestStageType INT = NULL,
	@ExcludedStatus INT = NULL,
    @TrackingLocationFunction INT = NULL,
	@NotInTrackingLocationFunction INT  = NULL,
	@Revision NVARCHAR(10) = NULL,
	@DepartmentID INT = NULL,
	@OnlyHasResults INT = NULL
AS
	DECLARE @TestName NVARCHAR(400)
	DECLARE @TestStageName NVARCHAR(400)
	DECLARE @HasBatchSpecificExceptions BIT
	SET @HasBatchSpecificExceptions = CONVERT(BIT, 0)
	
	SELECT @TestName = TestName FROM Tests WITH(NOLOCK) WHERE ID=@TestID 
	SELECT @TestStageName = TestStageName FROM TestStages WITH(NOLOCK) WHERE ID=@TestStageID
	CREATE TABLE #ExTestStageType (ID INT)
	CREATE TABLE #ExBatchStatus (ID INT)
	
	IF (@TestStageName IS NOT NULL)
		SET @TestStage = NULL
	
	IF convert(VARCHAR,(@excludedTestStageType & 1) / 1) = 1
	BEGIN
		INSERT INTO #ExTestStageType VALUES (1)
	END
	IF convert(VARCHAR,(@excludedTestStageType & 2) / 2) = 1
	BEGIN
		INSERT INTO #ExTestStageType VALUES (2)
	END
	IF convert(VARCHAR,(@excludedTestStageType & 4) / 4) = 1
	BEGIN
		INSERT INTO #ExTestStageType VALUES (3)
	END
	IF convert(VARCHAR,(@excludedTestStageType & 8) / 8) = 1
	BEGIN
		INSERT INTO #ExTestStageType VALUES (4)
	END
	IF convert(VARCHAR,(@excludedTestStageType & 16) / 16) = 1
	BEGIN
		INSERT INTO #ExTestStageType VALUES (5)
	END
		
	IF convert(VARCHAR,(@ExcludedStatus & 1) / 1) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (1)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 2) / 2) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (2)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 4) / 4) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (3)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 8) / 8) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (4)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 16) / 16) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (5)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 32) / 32) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (6)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 64) / 64) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (7)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 128) / 128) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (8)
	END
		
	SELECT TOP 100 BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroup As ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName,batchesrows.ProductID, 
		BatchesRows.QRANumber,BatchesRows.RequestPurposeID, BatchesRows.TestCenterLocationID,BatchesRows.TestStageName, BatchesRows.TestStageCompletionStatus, testUnitCount, 
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation, batchesrows.RQID AS ReqID,
		(testunitcount -
			(select COUNT(*) 
			from TestUnits as tu WITH(NOLOCK)
			INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
		) as HasUnitsToReturnToRequestor,
		ISNULL(
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
			WHERE ta.BatchID = BatchesRows.ID and ta.Active=1), 
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
			WHERE ta.Active=1 AND ISNULL(ta.taskID,0) = 0 AND ta.BatchID = BatchesRows.ID)
		) as ActiveTaskAssignee,
		@HasBatchSpecificExceptions AS HasBatchSpecificExceptions, batchesrows.ProductTypeID,batchesrows.AccessoryGroupID, BatchesRows.CPRNumber, BatchesRows.RelabJobID, 
		BatchesRows.TestCenterLocation, AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate, IsMQual, JobID, DateCreated, ContinueOnFailures,
		MechanicalTools, BatchesRows.RequestPurpose, BatchesRows.PriorityID, DepartmentID, Department, Requestor
	FROM     
		(
			SELECT DISTINCT b.BatchStatus,b.Comment, b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority AS PriorityID,b.ProductTypeID,
				b.AccessoryGroupID,p.ID As ProductID,lp.[Values] As ProductGroup,b.QRANumber,b.RequestPurpose As RequestPurposeID,b.TestCenterLocationID,b.TestStageName,
				j.WILocation,(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, l3.[Values] As TestCenterLocation,
				b.CPRNumber,b.RelabJobID, b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, 
				b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, b.DateCreated, j.ContinueOnFailures, MechanicalTools, l4.[Values] As RequestPurpose, l5.[Values] As Priority, 
				ISNULL(b.[Order], 100) As PriorityOrder, b.DepartmentID, l6.[Values] AS Department, b.Requestor
			FROM Batches as b WITH(NOLOCK)
				INNER JOIN Products p WITH(NOLOCK) on b.ProductID=p.id 
				INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
				LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON b.TestCenterLocationID=l3.LookupID
				INNER JOIN TestStages ts WITH(NOLOCK) ON ts.TestStageName=b.TestStageName
				LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON b.RequestPurpose=l4.LookupID
				LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON b.Priority=l5.LookupID
				LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON b.DepartmentID=l6.LookupID
			WHERE ((BatchStatus NOT IN (SELECT ID FROM #ExBatchStatus) OR @ExcludedStatus IS NULL) AND (BatchStatus = @Status OR @Status IS NULL))
				AND (p.ID = @ProductID OR @ProductID IS NULL)
				AND (b.Priority = @Priority OR @Priority IS NULL)
				AND (b.ProductTypeID = @ProductTypeID OR @ProductTypeID IS NULL)
				AND (b.AccessoryGroupID = @AccessoryGroupID OR @AccessoryGroupID IS NULL)
				AND (b.TestCenterLocationID = @GeoLocationID OR @GeoLocationID IS NULL)
				AND (b.DepartmentID = @DepartmentID OR @DepartmentID IS NULL)
				AND (b.JobName = @JobName OR @JobName IS NULL)
				AND (b.RequestPurpose = @RequestReason OR @RequestReason IS NULL)
				AND (b.MechanicalTools = @Revision OR @Revision IS NULL)
				AND 
				(
					(@TestStage IS NULL AND (b.TestStageName = @TestStageName OR @TestStageName IS NULL))
					OR
					(b.TestStageName = @TestStage AND @TestStageName IS NULL)
				)
				AND ((ts.TestStageType NOT IN (SELECT ID FROM #ExTestStageType) OR @excludedTestStageType IS NULL) AND (ts.TestStageType = @TestStageType OR @TestStageType IS NULL))
				AND
				(
					(
						SELECT top(1) tu.CurrentTestName as CurrentTestName 
						FROM TestUnits AS tu WITH(NOLOCK), DeviceTrackingLog AS dtl WITH(NOLOCK)
						where tu.ID = dtl.TestUnitID 
						and tu.CurrentTestName is not null
						and (dtl.OutUser IS NULL) AND tu.BatchID=b.ID
					) = @TestName 
					OR 
					@TestName IS NULL
				)
				AND
				(
					(
						SELECT top 1 u.id 
						FROM TestUnits as tu WITH(NOLOCK), devicetrackinglog as dtl WITH(NOLOCK), TrackingLocations as tl WITH(NOLOCK), Users u WITH(NOLOCK)
						WHERE tl.ID = dtl.TrackingLocationID and tu.id  = dtl.testunitid and tu.batchid = b.id and  inuser = u.LDAPLogin and outuser is null
					) = @UserID
					OR
					@UserID IS NULL
				)
				AND
				(
					@TrackingLocationID IS NULL
					OR
					(
						b.ID IN (SELECT DISTINCT tu.BatchID
						FROM TrackingLocations tl WITH(NOLOCK)
							INNER JOIN devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID --AND dtl.OutTime IS NULL
								AND dtl.InTime BETWEEN @BatchStart AND @BatchEnd
							INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=dtl.TestUnitID
						WHERE TrackingLocationTypeID=@TrackingLocationID)
					)
				)
				AND
				(
					@TrackingLocationFunction IS NULL
					OR
					(
						b.ID IN (select DISTINCT tu.BatchID
						FROM TrackingLocations tl WITH(NOLOCK)
							INNER JOIN devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID AND dtl.OutTime IS NULL
							INNER JOIN TestUnits tu WITH(NOLOCK) on tu.ID=dtl.TestUnitID
							INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tlt.ID = tl.TrackingLocationTypeID
						where tlt.TrackingLocationFunction=@TrackingLocationFunction)
					)
				)
				AND
				(
					@NotInTrackingLocationFunction IS NULL
					OR
					(
						b.ID IN (select DISTINCT tu.BatchID
						FROM TrackingLocations tl WITH(NOLOCK)
							INNER JOIN devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID AND dtl.OutTime IS NULL
							INNER JOIN TestUnits tu WITH(NOLOCK) on tu.ID=dtl.TestUnitID
							INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tlt.ID = tl.TrackingLocationTypeID
						where tlt.TrackingLocationFunction NOT IN (@NotInTrackingLocationFunction))
					)
				)
				AND 
				(
					(@BatchStart IS NULL AND @BatchEnd IS NULL)
					OR
					(@BatchStart IS NOT NULL AND @BatchEnd IS NOT NULL AND b.ID IN (Select distinct batchid FROM BatchesAudit WITH(NOLOCK) WHERE InsertTime BETWEEN @BatchStart AND @BatchEnd))
				)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.LookupID IN (SELECT ud.LookupID FROM UserDetails ud WITH(NOLOCK) WHERE UserID=@ExecutingUserID)))
				AND
				(
					(@OnlyHasResults IS NULL OR @OnlyHasResults = 0)
					OR
					(@OnlyHasResults = 1 AND EXISTS(SELECT 1 FROM TestUnits tu WITH(NOLOCK) INNER JOIN Relab.Results r ON r.TestUnitID=tu.ID WHERE tu.BatchID=b.ID))
				)
		)AS BatchesRows		
	ORDER BY BatchesRows.PriorityOrder ASC, BatchesRows.QRANumber DESC
	
	DROP TABLE #ExTestStageType
	DROP TABLE #ExBatchStatus
	RETURN
GO
GRANT EXECUTE ON remispBatchesSearch TO Remi
GO
ALTER PROCEDURE dbo.remispGetContacts @ProductID INT
AS
BEGIN
	DECLARE @TSDContact NVARCHAR(255)
	
	SELECT @TSDContact = p.TSDContact
	FROM Products p
	WHERE p.ID=@ProductID

	SELECT ISNULL(us.LDAPLogin, '') AS ProductManager
	INTO #temp
	FROM UserDetails ud WITH(NOLOCK)
		INNER JOIN Products p WITH(NOLOCK) ON p.LookupID=ud.LookupID
		INNER JOIN Users us WITH(NOLOCK) ON us.ID=ud.UserID
	WHERE ud.IsProductManager=1 AND p.ID=@ProductID
	
	IF ((SELECT COUNT(*) FROM #temp) = 0)
	BEGIN
		SELECT NULL AS ProductManager, @TSDContact AS TSDContact
	END
	ELSE
	BEGIN
		SELECT *, @TSDContact AS TSDContact
		FROM #temp
	END
	
	DROP TABLE #temp
END
GO
GRANT EXECUTE ON [dbo].remispGetContacts TO REMI
GO
INSERT INTO UserDetails (LookupID,LastUser,IsProductManager,UserID)
select p.LookupID,l.LastUser,0,l.UserID
from _UsersProducts l
inner join Products p on p.ID=l.ProductID
inner join Users u on u.ID=l.UserID
GO
update UserDetails set IsProductManager=0
GO
update ud
set ud.IsProductManager=1
from aspnet_UsersInRoles ur
inner join aspnet_Roles r on ur.RoleId=r.RoleId
inner join aspnet_Users u on u.UserId=ur.UserId
inner join Users us on us.LDAPLogin=u.UserName
inner join UserDetails ud on ud.UserID=us.id and ud.LookupID in (select LookupID from Products)
where r.RoleName='ProjectManager'
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
	SELECT @ByPassProductCheck = u.ByPassProduct FROM Users u WITH(NOLOCK) WHERE u.ID=@UserID
	
	SELECT @ProductGroupColumn = fs.Name
	FROM Req.ReqFieldSetup fs WITH(NOLOCK)
		INNER JOIN Req.ReqFieldMapping fm WITH(NOLOCK) ON fs.Name=fm.ExtField AND fs.RequestTypeID=fm.RequestTypeID
	WHERE fs.RequestTypeID = @RequestTypeID AND fm.IntField='ProductGroup'
	
	SELECT @DepartmentColumn = fs.Name
	FROM Req.ReqFieldSetup fs WITH(NOLOCK)
		INNER JOIN Req.ReqFieldMapping fm WITH(NOLOCK) ON fs.Name=fm.ExtField AND fs.RequestTypeID=fm.RequestTypeID
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
	
	IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType = 'ReqNum') > 0)
		BEGIN
			INSERT INTO dbo.#ReqNum (RequestNumber)
			SELECT SearchTerm
			FROM dbo.#temp WITH(NOLOCK)
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
		SELECT @ID = MIN(ID) FROM dbo.#temp WITH(NOLOCK) WHERE TableType='Request'

		WHILE (@ID IS NOT NULL)
		BEGIN
			INSERT INTO #executeSQL (sqlvar)
			VALUES ('
				(')

			IF ((SELECT TOP 1 1 FROM dbo.#temp WITH(NOLOCK) WHERE ID = @ID AND TableType='Request' AND LTRIM(RTRIM(SearchTerm)) NOT LIKE '-%') = 1)
			BEGIN
				INSERT INTO #executeSQL (sqlvar)
				VALUES ('
						(')
			END

			DECLARE @NOLIKE INT
			SET @NOLIKE = 0
			SET @ColumnName = ''
			SET @whereStr = ''
			SELECT @ColumnName=ColumnName FROM dbo.#temp WITH(NOLOCK) WHERE ID = @ID AND TableType='Request'

			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(SearchTerm)) + ''','
			FROM dbo.#temp WITH(NOLOCK)
			WHERE ID = @ID AND TableType='Request' AND LTRIM(RTRIM(SearchTerm)) NOT LIKE '*%' AND LTRIM(RTRIM(SearchTerm)) NOT LIKE '-%'

			IF (LEN(LTRIM(RTRIM(@whereStr))) > 0)
			BEGIN
				INSERT INTO #executeSQL (sqlvar)
				VALUES (@ColumnName + ' IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')')
				SET @NOLIKE = 1
			END

			SET @whereStr = ''
			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(SearchTerm)) + ''','
			FROM dbo.#temp WITH(NOLOCK)
			WHERE ID = @ID AND TableType='Request' AND LTRIM(RTRIM(SearchTerm)) LIKE '*%'

			SET @whereStr = REPLACE(REPLACE(REPLACE(@whereStr, '''*', 'LIKE ''%'), ''',', '%'''), 'LIKE ', ' OR ' + @ColumnName + ' LIKE ')

			IF (LEN(LTRIM(RTRIM(@whereStr))) > 0)
			BEGIN
				INSERT INTO #executeSQL (sqlvar)
				VALUES (CASE WHEN @NOLIKE = 0 THEN SUBSTRING(@whereStr,4, LEN(@whereStr)) ELSE @whereStr END)
			END

			IF ((SELECT TOP 1 1 FROM dbo.#temp WITH(NOLOCK) WHERE ID = @ID AND TableType='Request' AND LTRIM(RTRIM(SearchTerm)) NOT LIKE '-%') = 1)
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
				IF ((SELECT TOP 1 1 FROM dbo.#temp WITH(NOLOCK) WHERE ID = @ID AND TableType='Request' AND LTRIM(RTRIM(SearchTerm)) NOT LIKE '-%') = 1)
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

			SELECT @ID = MIN(ID) FROM dbo.#temp WITH(NOLOCK) WHERE ID > @ID AND TableType='Request'
		END

		INSERT INTO #executeSQL (sqlvar)
		VALUES (' 1=1 ')
	END

	SET @SQL = REPLACE((select sqlvar AS [text()] from dbo.#executeSQL for xml path('')), '&#x0D;','')

	EXEC sp_executesql @SQL

	--START BUILDING MEASUREMENTS
	IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType NOT IN ('Request','ReqNum')) > 0)
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

		SELECT @ResultArchived = ID FROM dbo.#temp WITH(NOLOCK) WHERE TableType='ResultArchived'
		SELECT @TestRunStartDate = SearchTerm FROM dbo.#temp WITH(NOLOCK) WHERE TableType='TestRunStartDate'
		SELECT @TestRunEndDate = SearchTerm FROM dbo.#temp WITH(NOLOCK) WHERE TableType='TestRunEndDate'

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

		IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType = 'Measurement') > 0)
		BEGIN				
			SET @whereStr = ''
			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(SearchTerm)) + ''','
			FROM dbo.#temp WITH(NOLOCK)
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

		IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType='Unit') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(ISNULL(SearchTerm, ''))) + ''','
			FROM dbo.#temp WITH(NOLOCK)
			WHERE TableType = 'Unit'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND tu.BatchUnitNumber IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')')
		END

		IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType='IMEI') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(ISNULL(SearchTerm, ''))) + ''','
			FROM dbo.#temp WITH(NOLOCK)
			WHERE TableType = 'IMEI'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND tu.IMEI IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')')
		END

		IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType='BSN') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(SearchTerm)) + ''','
			FROM dbo.#temp WITH(NOLOCK)
			WHERE TableType = 'BSN'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND tu.BSN IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')')
		END

		IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType='Test') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + LTRIM(RTRIM(ID)) + ','
			FROM dbo.#temp WITH(NOLOCK)
			WHERE TableType = 'Test'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND t.ID IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')')
		END

		IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType='Stage') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + LTRIM(RTRIM(ID)) + ','
			FROM dbo.#temp WITH(NOLOCK)
			WHERE TableType = 'Stage'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND ts.ID IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ') ')
		END
		
		IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType='Job') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + LTRIM(RTRIM(ID)) + ','
			FROM dbo.#temp WITH(NOLOCK)
			WHERE TableType = 'Job'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND j.ID IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ') ')
		END
		
		SET @SQL =  REPLACE(REPLACE(REPLACE(REPLACE((select sqlvar AS [text()] from dbo.#executeSQL for xml path('')), '&#x0D;',''), '&gt;', ' >'), '&lt;', ' <'),'&amp;','&')
		EXEC sp_executesql @SQL

		SET @SQL = ''
		TRUNCATE TABLE dbo.#executeSQL

		IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType LIKE 'Param:%') > 0)
		BEGIN
			INSERT INTO dbo.#Params (Name, Val)
			SELECT REPLACE(TableType, 'Param:', ''), SearchTerm
			FROM dbo.#temp WITH(NOLOCK)
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
			FROM dbo.#Params p WITH(NOLOCK)
			WHERE p.Name IN (SELECT Name
					FROM 
						(
							SELECT Name
							FROM #Params WITH(NOLOCK)
						) param
					WHERE param.Name NOT IN (SELECT s FROM dbo.Split(',', LTRIM(RTRIM(REPLACE(REPLACE(@ParameterColumnNames, '[', ''), ']', ''))))))
			
			IF ((SELECT COUNT(*) FROM dbo.#Params WITH(NOLOCK)) > 0)
			BEGIN
				SET @whereStr = ' WHERE '
				SET @whereStr2 = ''
				SET @whereStr3 = ''
				
				SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS params
				INTO #buildparamtable
				FROM #Params WITH(NOLOCK)
				GROUP BY name
				
				SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS params
				INTO #buildparamtable2
				FROM #Params WITH(NOLOCK)
				GROUP BY name
				
				SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS params
				INTO #buildparamtable3
				FROM #Params WITH(NOLOCK)
				GROUP BY name
				
				UPDATE bt
				SET bt.params = REPLACE(REPLACE((
						SELECT ('''' + p.Val + ''',') As Val
						FROM #Params p WITH(NOLOCK)
						WHERE p.Name = bt.Name AND Val NOT LIKE '*%' AND Val NOT LIKE '-%'
						FOR XML PATH('')), '<Val>', ''), '</Val>','')
				FROM #buildparamtable bt WITH(NOLOCK)
				WHERE Params = ''
				
				UPDATE bt
				SET bt.params = REPLACE(REPLACE((
						SELECT ('LTRIM(RTRIM([' + Name + '])) LIKE ''' + REPLACE(p.Val, '*','%') + '%'' OR ') As Val
						FROM #Params p WITH(NOLOCK)
						WHERE p.Name = bt.Name AND Val LIKE '*%' AND Val NOT LIKE '-%'
						FOR XML PATH('')), '<Val>', ''), '</Val>','')
				FROM #buildparamtable2 bt WITH(NOLOCK)
				WHERE Params = '' OR Params IS NULL
				
				UPDATE bt
				SET bt.params = REPLACE(REPLACE((
						SELECT ('LTRIM(RTRIM([' + Name + '])) NOT LIKE ''' + REPLACE(p.Val, '-','%') + '%'' OR ') As Val
						FROM #Params p WITH(NOLOCK)
						WHERE p.Name = bt.Name AND Val LIKE '-%'
						FOR XML PATH('')), '<Val>', ''), '</Val>','')
				FROM #buildparamtable3 bt WITH(NOLOCK)
				WHERE Params = '' OR Params IS NULL
				
				SELECT @whereStr = COALESCE(@whereStr + '' ,'') + 'LTRIM(RTRIM([' + Name + '])) IN (' + SUBSTRING(params, 0, LEN(params)) + ') AND ' 
				FROM dbo.#buildparamtable WITH(NOLOCK) 
				WHERE Params IS NOT NULL
				
				IF (@whereStr <> ' WHERE ')
					SET @whereStr = SUBSTRING(@whereStr, 0, LEN(@whereStr)-2)

				SELECT @whereStr2 += COALESCE(@whereStr2 + '' ,'') + ' ( ' + SUBSTRING(params, 0, LEN(params)-1) + ' ) '
				FROM dbo.#buildparamtable2 WITH(NOLOCK)
				WHERE Params IS NOT NULL
				
				IF @whereStr2 IS NOT NULL AND LTRIM(RTRIM(@whereStr2)) <> ''
				BEGIN						
					IF (@whereStr <> ' WHERE ')
						SET @whereStr2 = ' AND ' + @whereStr2
					ELSE
						SET @whereStr2 = @whereStr2
				END
				
				SELECT @whereStr3 += COALESCE(@whereStr3 + '' ,'') + ' ( ' + SUBSTRING(params, 0, LEN(params)-1) + ' ) '
				FROM dbo.#buildparamtable3 WITH(NOLOCK)
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
		SELECT @ResultInfoArchived = ID FROM dbo.#temp WITH(NOLOCK) WHERE TableType='ResultInfoArchived'

		IF @ResultInfoArchived IS NULL
			SET @ResultInfoArchived = 0
							
		IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType LIKE 'Info:%') > 0)
		BEGIN
			INSERT INTO dbo.#Infos (Name, Val)
			SELECT REPLACE(TableType, 'Info:', ''), SearchTerm
			FROM dbo.#temp WITH(NOLOCK)
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
			FROM dbo.#infos i WITH(NOLOCK)
			WHERE i.Name IN (SELECT Name
					FROM 
						(
							SELECT Name
							FROM #Infos WITH(NOLOCK)
						) inf
					WHERE inf.Name NOT IN (SELECT s FROM dbo.Split(',', LTRIM(RTRIM(REPLACE(REPLACE(@InformationColumnNames, '[', ''), ']', ''))))))

			IF ((SELECT COUNT(*) FROM dbo.#Infos WITH(NOLOCK)) > 0)
			BEGIN
				SET @whereStr = ' WHERE '
				SET @whereStr2 = ''
				SET @whereStr3 = ''
				
				SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS info
				INTO #buildinfotable
				FROM dbo.#infos WITH(NOLOCK)
				GROUP BY name
				
				SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS info
				INTO #buildinfotable2
				FROM dbo.#infos WITH(NOLOCK)
				GROUP BY name
				
				SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS info
				INTO #buildinfotable3
				FROM dbo.#infos WITH(NOLOCK)
				GROUP BY name
				
				UPDATE bt
				SET bt.info = REPLACE(REPLACE((
						SELECT ('''' + i.Val + ''',') As Val
						FROM dbo.#infos i WITH(NOLOCK)
						WHERE i.Name = bt.Name AND Val NOT LIKE '*%' AND Val NOT LIKE '-%'
						FOR XML PATH('')), '<Val>', ''), '</Val>','')
				FROM #buildinfotable bt WITH(NOLOCK)
				WHERE info = ''
				
				UPDATE bt
				SET bt.info = REPLACE(REPLACE((
						SELECT ('LTRIM(RTRIM([' + Name + '])) LIKE ''' + REPLACE(i.Val, '*','%') + '%'' OR ') As Val
						FROM dbo.#infos i WITH(NOLOCK)
						WHERE i.Name = bt.Name AND Val LIKE '*%'
						FOR XML PATH('')), '<Val>', ''), '</Val>','')
				FROM #buildinfotable2 bt WITH(NOLOCK)
				WHERE info = '' OR info IS NULL
				
				UPDATE bt
				SET bt.info = REPLACE(REPLACE((
						SELECT ('LTRIM(RTRIM([' + Name + '])) NOT LIKE ''' + REPLACE(i.Val, '-','%') + '%'' OR ') As Val
						FROM dbo.#infos i WITH(NOLOCK)
						WHERE i.Name = bt.Name AND Val LIKE '-%'
						FOR XML PATH('')), '<Val>', ''), '</Val>','')
				FROM #buildinfotable3 bt WITH(NOLOCK)
				WHERE info = '' OR info IS NULL
									
				SELECT @whereStr = COALESCE(@whereStr + '' ,'') + 'LTRIM(RTRIM([' + Name + '])) IN (' + SUBSTRING(info, 0, LEN(info)) + ') AND ' 
				FROM dbo.#buildinfotable WITH(NOLOCK) 
				WHERE info IS NOT NULL 
				
				IF (@whereStr <> ' WHERE ')
					SET @whereStr = SUBSTRING(@whereStr, 0, LEN(@whereStr)-2)
									
				SELECT @whereStr2 += COALESCE(@whereStr2 + '' ,'') + ' ( ' + SUBSTRING(info, 0, LEN(info)-1) + ' ) '
				FROM dbo.#buildinfotable2 WITH(NOLOCK) 
				WHERE info IS NOT NULL 
				
				IF @whereStr2 IS NOT NULL AND LTRIM(RTRIM(@whereStr2)) <> ''
				BEGIN						
					IF (@whereStr <> ' WHERE ')
						SET @whereStr2 = ' AND ' + @whereStr2
					ELSE
						SET @whereStr2 = @whereStr2
				END						
				
				SELECT @whereStr3 += COALESCE(@whereStr3 + '' ,'') + ' ( ' + SUBSTRING(info, 0, LEN(info)-1) + ' ) '
				FROM dbo.#buildinfotable3 WITH(NOLOCK) 
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
			FROM dbo.UserSearchFilter WITH(NOLOCK)
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
				, 'Params', CASE WHEN (SELECT 1 FROM UserSearchFilter WITH(NOLOCK) WHERE FilterType=3) = 1 THEN @ParameterColumnNames ELSE '' END)
				, 'Info', CASE WHEN (SELECT 1 FROM UserSearchFilter WITH(NOLOCK) WHERE FilterType=4) = 1 THEN @InformationColumnNames ELSE '' END)

		IF (ISNULL(@whereStr, '') = '')
		BEGIN
			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + '[' + COLUMN_NAME + '],' 
			FROM tempdb.INFORMATION_SCHEMA.COLUMNS WITH(NOLOCK) 
			WHERE (TABLE_NAME like '#RR%' OR TABLE_NAME LIKE '#RRParameters%' OR TABLE_NAME LIKE '#RRInformation%')
				AND COLUMN_NAME NOT IN ('RequestID', 'XMLID', 'ID', 'BatchID', 'ResultID', 'RID', 'ResultMeasurementID')
			ORDER BY TABLE_NAME
		END
		
		SET @whereStr = SUBSTRING(@whereStr, 0, LEN(@whereStr))

		SET @SQL = 'SELECT DISTINCT ' + @whereStr + '
			FROM dbo.#RR rr WITH(NOLOCK) 
				LEFT OUTER JOIN dbo.#RRParameters p WITH(NOLOCK) ON rr.ID=p.ResultMeasurementID
				LEFT OUTER JOIN dbo.#RRInformation i WITH(NOLOCK) ON i.RID = rr.ResultID
			WHERE ((' + CONVERT(NVARCHAR, @LimitedByInfo) + ' = 0) OR (' + CONVERT(NVARCHAR, @LimitedByInfo) + ' = 1 AND i.RID IS NOT NULL ))
				AND ((' + CONVERT(NVARCHAR, @LimitedByParam) + ' = 0) OR (' + CONVERT(NVARCHAR, @LimitedByParam) + ' = 1 AND p.ResultMeasurementID IS NOT NULL )) '
		
		IF (@SQL LIKE '%[' + @ProductGroupColumn + ']%' AND @UserID IS NOT NULL)
		BEGIN
			SET @SQL += 'AND (' + CONVERT(NVARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(NVARCHAR, @ByPassProductCheck) + ' = 0 
																	AND [' + @ProductGroupColumn + '] COLLATE SQL_Latin1_General_CP1_CI_AS IN (SELECT p.[values] 
																FROM UserDetails ud WITH(NOLOCK)
																	INNER JOIN Lookups p WITH(NOLOCK) ON p.LookupID=ud.LookupID 
																WHERE UserID=' + CONVERT(NVARCHAR, @UserID) + '))) '
		END
		
		IF (@SQL LIKE '%[' + @DepartmentColumn + ']%' AND @UserID IS NOT NULL)
		BEGIN
			SET @SQL += ' AND ([' + @DepartmentColumn + '] COLLATE SQL_Latin1_General_CP1_CI_AS IN (SELECT lt.[Values]
															FROM UserDetails ud WITH(NOLOCK)
																INNER JOIN Lookups lt WITH(NOLOCK) ON lt.LookupID=ud.LookupID
															WHERE ud.UserID=' + CONVERT(NVARCHAR, @UserID) + ')) '
		END
		
		PRINT @SQL
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
			FROM dbo.UserSearchFilter WITH(NOLOCK)
			WHERE UserID=@UserID AND FilterType = 1 AND RequestTypeID=@RequestTypeID 
			ORDER BY SortOrder
		END

		IF (ISNULL(@whereStr, '') = '')
		BEGIN
			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + '[' + COLUMN_NAME + '],' 
			FROM tempdb.INFORMATION_SCHEMA.COLUMNS WITH(NOLOCK) 
			WHERE (TABLE_NAME like '#Request%') AND COLUMN_NAME NOT IN ('RequestID', 'BatchID')
			ORDER BY TABLE_NAME
		END

		SET @whereStr = SUBSTRING(@whereStr, 0, LEN(@whereStr))

		SET @SQL = 'SELECT DISTINCT ' + CASE WHEN @RecordCount = 0 THEN 'TOP 20' ELSE '' END + @whereStr + ' 
					FROM dbo.#Request r WITH(NOLOCK) 
					WHERE (1=1)'

		IF (@SQL LIKE '%[' + @ProductGroupColumn + ']%' AND @UserID IS NOT NULL)
		BEGIN
			SET @SQL += 'AND (' + CONVERT(NVARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(NVARCHAR, @ByPassProductCheck) + ' = 0 
															AND [' + @ProductGroupColumn + '] COLLATE SQL_Latin1_General_CP1_CI_AS IN (SELECT p.[values] 
																FROM UserDetails ud WITH(NOLOCK)
																	INNER JOIN Lookups p WITH(NOLOCK) ON p.LookupID=ud.LookupID 
																WHERE UserID=' + CONVERT(NVARCHAR, @UserID) + '))) '
		END
		
		IF (@SQL LIKE '%[' + @DepartmentColumn + ']%' AND @UserID IS NOT NULL)
		BEGIN
			SET @SQL += ' AND ([' + @DepartmentColumn + '] COLLATE SQL_Latin1_General_CP1_CI_AS IN (SELECT lt.[Values]
															FROM UserDetails ud WITH(NOLOCK)
																INNER JOIN Lookups lt WITH(NOLOCK) ON lt.LookupID=ud.LookupID
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
delete
from aspnet_UsersInRoles
where RoleId in (select RoleId
from aspnet_Roles
where RoleName='ProjectManager')
go
delete
from aspnet_PermissionsInRoles
where RoleID in (select roleid from aspnet_Roles where RoleName='ProjectManager')
go
delete
from aspnet_Roles
where RoleName='ProjectManager'
ROLLBACK TRAN