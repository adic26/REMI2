BEGIN TRAN
EXEC sp_rename 'dbo.UsersProducts', '_UsersProducts'
EXEC sp_rename 'dbo.UsersProductsAudit', '_UsersProductsAudit'
GO
ALTER TABLE dbo.UserDetails ADD IsProductManager BIT DEFAULT(0) NULL
ALTER TABLE dbo.UserDetails ADD LastUser NVARCHAR(255) NULL
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
go
DROP PROCEDURE remispTestsSelectSingleItemByName
GO
ALTER PROCEDURE [dbo].[remispTestsSelectSingleItem] @ID INT = 0, @Name nvarchar(400) = NULL, @ParametricOnly INT = 1
AS
	SELECT t.Comment,t.ConcurrencyID,t.Duration,t.ID,t.LastUser,t.ResultBasedOntime,t.TestName,t.TestType,t.WILocation, t.IsArchived, t.Owner, t.Trainee, t.DegradationVal
	FROM Tests as t
	WHERE 
		(
			(t.ID = @ID AND @ID > 0)
			OR
			(@ID = 0 AND t.TestName = @name)
		)
		AND 
		(
			@ParametricOnly = 0
			OR
			(@ParametricOnly = 1 AND TestType=1)
		)
GO
GRANT EXECUTE ON remispTestsSelectSingleItem TO REMI
GO
ALTER PROCEDURE [dbo].[remispTestUnitsAvailable] @RequestNumber NVARCHAR(11)
AS
BEGIN
	SELECT tu.BatchUnitNumber
	FROM Batches b WITH(NOLOCK)
		INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID=tu.BatchID
	WHERE QRANumber=@RequestNumber
		AND tu.ID NOT IN (SELECT dtl.TestUnitID
					FROM DeviceTrackingLog dtl WITH(NOLOCK)
						INNER JOIN TrackingLocations tl WITH(NOLOCK) ON dtl.TrackingLocationID=tl.ID AND tl.ID NOT IN (25,81)
					WHERE TestUnitID = 214734 AND OutTime IS NULL)
END
GO
GRANT EXECUTE ON remispTestUnitsAvailable TO REMI
GO
DROP PROCEDURE remispTrackingLocationsGetSpecificLocationForUsersTestCenter
go
drop procedure remispTestUnitsSetBSN
go
drop procedure remispTestRecordsSelectByStatus
go
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
	@OnlyHasResults INT = NULL,
	@JobID int = 0
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
				AND 
				(
					(@JobID > 0 AND j.ID=@JobID)
					OR
					(@JobName IS NOT NULL AND b.JobName = @JobName)
					OR
					(@JobName IS NULL AND @JobID = 0)
				)
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
ALTER PROCEDURE [Relab].[remispResultsStatus] @BatchID INT
AS
BEGIN
	DECLARE @Status NVARCHAR(18)
	
	SELECT CASE WHEN r.PassFail = 0 THEN 'Fail' ELSE 'Pass' END AS Result, COUNT(*) AS NumRecords
	INTO #ResultCount
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
	WHERE tu.BatchID=@BatchID
	GROUP BY r.PassFail
	
	SELECT CASE WHEN rs.PassFail = 1 THEN 'Pass' WHEN rs.PassFail=2 THEN 'Fail' ELSE 'No Result' END AS Result, 
		rs.ApprovedBy, rs.ApprovedDate
	INTO #ResultOverride
	FROM Relab.ResultsStatus rs WITH(NOLOCK)
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
ALTER PROCEDURE [dbo].[remispGetBatchJIRAs] @BatchID INT
AS
BEGIN
	SELECT 0 AS JIRAID, @BatchID As BatchID, '' AS DisplayName, '' AS Link, '' AS Title
	UNION
	SELECT bj.JIRAID, bj.BatchID, bj.DisplayName, bj.Link, bj.Title
	FROM BatchesJira bj WITH(NOLOCK)
	WHERE bj.BatchID=@BatchID
END
GO
GRANT EXECUTE ON [dbo].[remispGetBatchJIRAs] TO Remi
GO
ALTER PROCEDURE [remispBatchGetTaskInfo] @BatchID INT, @TestStageID INT = 0
AS
BEGIN
	DECLARE @BatchStatus INT
	SELECT @BatchStatus = BatchStatus FROM Batches WITH(NOLOCK) WHERE ID=@BatchID

	IF (@BatchStatus = 5)
	BEGIN
		SELECT QRANumber, expectedDuration, processorder, resultbasedontime, tname As TestName, testtype, teststagetype, tsname AS TestStageName, testunitsfortest, TestID, TestStageID, IsArchived, 
			TestIsArchived, TestWI, '' AS TestCounts
		FROM vw_GetTaskInfoCompleted WITH(NOLOCK)
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
		FROM vw_GetTaskInfo WITH(NOLOCK)
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
ALTER PROCEDURE [dbo].[remispESResultSummary] @BatchID INT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @UnitRows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	DECLARE @BatchUnitNumber INT
	DECLARE @UnitCount INT
	DECLARE @RowID INT
	DECLARE @ID INT
	CREATE TABLE #Results (TestID INT, TestName NVARCHAR(MAX), TestStageID INT, TestStageName NVARCHAR(MAX))

	SELECT ROW_NUMBER() OVER (ORDER BY tu.ID) AS RowID, tu.BatchUnitNumber, tu.ID
	INTO #units
	FROM TestUnits tu WITH(NOLOCK)
	WHERE BatchID=@BatchID

	INSERT INTO #Results (TestID, TestName, TestStageID, TestStageName)
	SELECT DISTINCT r.TestID, t.TestName, r.TestStageID, ts.TestStageName
	FROM Batches b 
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.BatchID=b.ID
		INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Tests t WITH(NOLOCK) ON t.ID=r.TestID
		INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID=r.TestStageID
	WHERE b.ID=@BatchID AND ts.TestStageName NOT IN ('Analysis')

	SELECT @UnitCount = COUNT(RowID) FROM #units WITH(NOLOCK)

	SELECT @RowID = MIN(RowID) FROM #units
				
	WHILE (@RowID IS NOT NULL)
	BEGIN
		SELECT @BatchUnitNumber=BatchUnitNumber, @ID=ID FROM #units WITH(NOLOCK) WHERE RowID=@RowID

		EXECUTE ('ALTER TABLE #Results ADD [' + @BatchUnitNumber + '] NVARCHAR(10) NULL')
		print @ID
		SET @SQL = 'UPDATE rr
				SET [' + CONVERT(VARCHAR,@BatchUnitNumber) + '] = (
						SELECT CASE WHEN PassFail  = 1 THEN ''Pass'' WHEN PassFail = 0 THEN ''Fail'' ELSE NULL END + 
							CASE WHEN (SELECT CONVERT(VARCHAR,COUNT(*))
							FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
								INNER JOIN Relab.ResultsMeasurementsFiles rmf WITH(NOLOCK) ON rmf.ResultMeasurementID=rm.ID
							WHERE rm.ResultID=r.ID) > 0 THEN ''1'' ELSE ''0'' END
						FROM Relab.Results r WITH(NOLOCK) 
						WHERE r.TestUnitID=' + CONVERT(NVARCHAR, @ID) + '
							AND rr.TestID=r.TestID AND rr.TestStageID=r.TestStageID
					)
				FROM #Results rr'
		
		EXECUTE (@SQL)
		SELECT @RowID = MIN(RowID) FROM #units WITH(NOLOCK) WHERE RowID > @RowID
	END
	
	ALTER TABLE #Results DROP COLUMN TestID
	ALTER TABLE #Results DROP COLUMN TestStageID
	
	SELECT * 
	FROM #Results WITH(NOLOCK)

	DROP TABLE #units
	DROP TABLE #Results
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [dbo].[remispESResultSummary] TO Remi
GO
ALTER PROCEDURE Relab.remispGetObservationSummary @BatchID INT
AS
BEGIN
	DECLARE @RowID INT
	DECLARE @ID INT
	DECLARE @BatchUnitNumber INT
	Declare @ObservationLookupID INT
	DECLARE @query NVARCHAR(4000)
	CREATE TABLE #Observations (Observation NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL, UnitsAffected INT)

	SELECT @ObservationLookupID = LookupID FROM Lookups WITH(NOLOCK) WHERE LookupTypeID=7 AND [values] = 'Observation'

	SELECT ROW_NUMBER() OVER (ORDER BY tu.ID) AS RowID, tu.BatchUnitNumber, tu.ID
	INTO #units
	FROM TestUnits tu WITH(NOLOCK)
	WHERE BatchID=@BatchID

	SELECT m.ID AS MeasurementID, tu.ID AS TestUnitID, tu.batchunitnumber, ts.ProcessOrder, ts.TestStageName, Relab.ResultsObservation (m.ID) AS Observation
	INTO #temp
	FROM Relab.ResultsMeasurements m WITH(NOLOCK)
		INNER JOIN Relab.Results r WITH(NOLOCK) ON r.ID=m.ResultID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID=r.TestStageID
		INNER JOIN Tests t WITH(NOLOCK) ON t.ID=r.TestID
		INNER JOIN Lookups lm WITH(NOLOCK) ON lm.LookupID=m.MeasurementTypeID
		INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
		LEFT OUTER JOIN JobOrientation jo WITH(NOLOCK) ON jo.ID=b.OrientationID
	WHERE MeasurementTypeID = @ObservationLookupID AND b.ID=@BatchID AND ISNULL(m.Archived, 0) = 0
		
	INSERT INTO #Observations
	SELECT Observation, COUNT(DISTINCT TestUnitID) AS UnitsAffected
	FROM #temp WITH(NOLOCK)
	GROUP BY Observation
	
	SELECT @RowID = MIN(RowID) FROM #units
				
	WHILE (@RowID IS NOT NULL)
	BEGIN
		SET @query = ''
		SELECT @BatchUnitNumber=BatchUnitNumber, @ID=ID FROM #units WITH(NOLOCK) WHERE RowID=@RowID
		
		EXECUTE ('ALTER TABLE #Observations ADD [' + @BatchUnitNumber + '] NVARCHAR(10) NULL')
		
		SET @query = 'UPDATE #Observations SET [' + CONVERT(VARCHAR,@BatchUnitNumber) + '] = ISNULL((
			SELECT TOP 1 REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(TestStageName,''''),''drops'',''''),''drop'',''''),''tumbles'',''''),''tumble'','''')
			FROM #temp WITH(NOLOCK)
			WHERE batchunitnumber=' + CONVERT(VARCHAR,@BatchUnitNumber) + ' 
				AND #temp.Observation = #Observations.Observation
			ORDER BY ProcessOrder ASC
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

	DROP TABLE #temp
	DROP TABLE #Observations
	DROP TABLE #units
END
GO
GRANT EXECUTE ON Relab.remispGetObservationSummary TO REMI
GO
ALTER FUNCTION [Relab].[ResultsObservation](@ResultMeasurementID INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @listStr NVARCHAR(MAX)
	DECLARE @obs TABLE(Value NVARCHAR(250), ParameterName NVARCHAR(255))
	
	INSERT INTO @obs (Value, ParameterName)
	SELECT Value, ParameterName
	FROM Relab.ResultsParameters WITH(NOLOCK)
	WHERE Relab.ResultsParameters.ResultMeasurementID=@ResultMeasurementID
	
	SELECT @listStr = Value
	FROM @obs
	WHERE ParameterName = 'Top Observation'
	
	SELECT @listStr = COALESCE(@listStr+'\' ,'') + LTRIM(RTRIM(Value))
	FROM @obs
	WHERE ParameterName LIKE '%Sub O%'
	ORDER BY ParameterName, Value ASC
	
	Return @listStr
END
GO
ALTER PROCEDURE Relab.remispGetObservations @BatchID INT
AS
BEGIN
	DECLARE @ObservationLookupID INT
	SELECT @ObservationLookupID = LookupID FROM Lookups WITH(NOLOCK) WHERE LookupTypeID=7 AND [values] = 'Observation'

	SELECT b.QRANumber, tu.BatchUnitNumber, (SELECT TOP 1 ts2.TestStageName
								FROM Relab.Results r2 WITH(NOLOCK)
									INNER JOIN TestStages ts2 WITH(NOLOCK) ON ts2.ID=r2.TestStageID AND ts2.TestStageType=2
								WHERE r2.TestUnitID=r.TestUnitID
								ORDER BY ts2.ProcessOrder DESC
								) AS MaxStage, 
			ts.TestStageName, [Relab].[ResultsObservation] (m.ID) AS Observation, 
			(SELECT T.c.value('@Description', 'varchar(MAX)')
			FROM jo.Definition.nodes('/Orientations/Orientation') T(c)
			WHERE T.c.value('@Unit', 'varchar(MAX)') = tu.BatchUnitNumber AND ts.TestStageName LIKE T.c.value('@Drop', 'varchar(MAX)') + ' %') AS Orientation, 
			m.Comment, (CASE WHEN (SELECT COUNT(*) FROM Relab.ResultsMeasurementsFiles rmf WITH(NOLOCK) WHERE rmf.ResultMeasurementID=m.ID) > 0 THEN 1 ELSE 0 END) AS HasFiles, m.ID AS MeasurementID
	FROM Relab.ResultsMeasurements m WITH(NOLOCK)
		INNER JOIN Relab.Results r WITH(NOLOCK) ON r.ID=m.ResultID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID=r.TestStageID
		INNER JOIN Tests t WITH(NOLOCK) ON t.ID=r.TestID
		INNER JOIN Lookups lm WITH(NOLOCK) ON lm.LookupID=m.MeasurementTypeID
		INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
		LEFT OUTER JOIN JobOrientation jo WITH(NOLOCK) ON jo.ID=b.OrientationID
	WHERE MeasurementTypeID = @ObservationLookupID
		AND b.ID=@BatchID AND ISNULL(m.Archived,0) = 0
	ORDER BY tu.BatchUnitNumber, ts.ProcessOrder
END
GO
GRANT EXECUTE ON Relab.remispGetObservations TO REMI
GO
ALTER procedure [dbo].[remispUnitSearch] @BSN INT=0, @IMEI NVARCHAR(150)= NULL
AS
BEGIN
	SELECT b.QRANumber, tu.BatchUnitNumber
	FROM Batches b
		INNER JOIN TestUnits tu ON tu.BatchID=b.ID
	WHERE (@BSN > 0 AND tu.BSN=@BSN)
		OR
		(@IMEI IS NOT NULL AND tu.IMEI=@IMEI)
END
GO
GRANT EXECUTE ON remispUnitSearch TO REMI
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
				
			SET @SQL += ' WHERE rt.RequestTypeID=' + CONVERT(NVARCHAR, @RequestTypeID)
			IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType IN ('BSN','IMEI')) > 0 AND (SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType NOT IN ('BSN','IMEI')) = 0)
			BEGIN
				SET @SQL += ' AND r.BatchID IN 
					(SELECT b.ID 
					FROM dbo.Batches b WITH(NOLOCK)
						INNER JOIN dbo.TestUnits tu WITH(NOLOCK) ON b.ID=tu.BatchID 
					WHERE b.QRANumber = r.RequestNumber AND ('

				IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType='BSN') > 0)
				BEGIN
					SET @whereStr = ''

					SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(ISNULL(SearchTerm, ''))) + ''','
					FROM dbo.#temp WITH(NOLOCK)
					WHERE TableType = 'BSN'

					SET @SQL += ' tu.BSN IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ') '
				END
				
				IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType='IMEI') > 0)
				BEGIN
					SET @whereStr = ''

					SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(SearchTerm)) + ''','
					FROM dbo.#temp WITH(NOLOCK)
					WHERE TableType = 'IMEI'
					
					IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType='BSN') > 0)
					BEGIN
						SET @SQL += ' OR '
					END

					SET @SQL += 'tu.IMEI IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ') '
				END
				
				SET @SQL += ' ) ) '
			END			
			
			SET @SQL += ' ) req PIVOT (MAX(Value) FOR Name IN (' + REPLACE(@rows, ',', ',
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
	IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType NOT IN ('Request','ReqNum', 'IMEI', 'BSN')) > 0)
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
ALTER PROCEDURE [Relab].[remispDeleteAllResults] @RequestNumber NVARCHAR(11), @IncludeBatch BIT = 0, @IncludeRequest BIT = 0 , @UserName NVARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON
	
	IF IS_ROLEMEMBER ('db_owner', @UserName) = 1
	BEGIN
		IF (@IncludeRequest = 1 AND @IncludeBatch = 0)
		BEGIN
			SET @IncludeBatch = 1
		END

		DECLARE @batchid INT
		SELECT @batchid=id FROM Batches WHERE QRANumber=@RequestNumber

		DELETE trtl
		FROM TestRecordsXTrackingLogs trtl
		WHERE trtl.TestRecordID in (SELECT tr.id 
									FROM TestRecords tr
										INNER JOIN TestUnits tu ON tr.TestUnitID=tu.id
									WHERE tu.BatchID=@batchid AND TestName NOT LIKE '%Sample Evaluation%')

		DELETE tr 
		FROM TestRecords tr
			INNER JOIN TestUnits tu ON tr.TestUnitID=tu.id
		WHERE tu.BatchID=@batchid AND TestName NOT LIKE '%Sample Evaluation%'

		DELETE x FROM Relab.ResultsInformation x WHERE x.XMLID IN (SELECT id FROM Relab.ResultsXML WHERE ResultID in (SELECT ID FROM Relab.Results WHERE TestUnitID IN (SELECT id FROM TestUnits WHERE BatchID=@batchid)))
		DELETE rmf FROM Relab.ResultsMeasurementsFiles rmf WHERE ResultMeasurementID IN (SELECT ID FROM Relab.ResultsMeasurements rm WHERE rm.ResultID IN (SELECT id FROM Relab.Results WHERE TestUnitID IN (SELECT id FROM TestUnits WHERE BatchID=@batchid)))
		DELETE rma FROM Relab.ResultsMeasurementsAudit rma WHERE ResultMeasurementID IN (SELECT ID FROM Relab.ResultsMeasurements rm WHERE rm.ResultID IN (SELECT id FROM Relab.Results WHERE TestUnitID IN (SELECT id FROM TestUnits WHERE BatchID=@batchid)))
		DELETE rp FROM Relab.ResultsParameters rp where rp.ResultMeasurementID IN (SELECT ID FROM Relab.ResultsMeasurements rm WHERE rm.ResultID IN (SELECT id FROM Relab.Results WHERE TestUnitID IN (SELECT id FROM TestUnits WHERE BatchID=@batchid)))
		DELETE rm FROM Relab.ResultsMeasurements rm WHERE rm.ResultID IN (SELECT id FROM Relab.Results WHERE TestUnitID IN (SELECT id FROM TestUnits WHERE BatchID=@batchid))
		DELETE x FROM Relab.ResultsXML x WHERE x.ResultID IN (SELECT ID FROM Relab.Results WHERE TestUnitID IN (SELECT id FROM TestUnits WHERE BatchID=@batchid))
		DELETE r FROM Relab.Results r WHERE TestUnitID IN (SELECT id FROM TestUnits WHERE BatchID=@batchid)
		DELETE FROM Relab.ResultsStatus WHERE BatchID=@batchid
		UPDATE TestUnits SET CurrentTestName='', CurrentTestStageName='' WHERE BatchID=@batchid
		
		IF (@IncludeBatch = 1)
		BEGIN
			DELETE FROM BatchesJira WHERE BatchID=@batchid
			DELETE FROM BatchComments WHERE BatchID=@batchid
			DELETE FROM BatchSpecificTestDurations WHERE BatchID=@batchid
			DELETE FROM DeviceTrackingLog WHERE TestUnitID IN (SELECT ID FROM TestUnits WHERE BatchID=@batchid)
			DELETE FROM TestRecordsXTrackingLogs WHERE TestRecordID IN (SELECT ID FROM TestRecords WHERE TestUnitID IN (SELECT ID FROM TestUnits WHERE BatchID=@batchid))
			DELETE FROM TestRecords WHERE TestUnitID IN (SELECT ID FROM TestUnits WHERE BatchID=@batchid)
			DELETE FROM TaskAssignments WHERE BatchID=@batchid
			DELETE FROM Req.RequestSetup WHERE BatchID=@batchid
			DELETE FROM TestUnits WHERE BatchID=@batchid
			UPDATE Req.Request SET BatchID=NULL WHERE BatchID=@batchid
			DELETE FROM Batches WHERE ID=@batchid
		END
		
		IF (@IncludeRequest = 1)
		BEGIN
			DELETE FROM Req.ReqFieldData WHERE RequestID IN (SELECT RequestID FROM Req.Request WHERE RequestNumber=@RequestNumber)
			DELETE FROM Req.ReqDistribution WHERE RequestID IN (SELECT RequestID FROM Req.Request WHERE RequestNumber=@RequestNumber)
			DELETE FROM Req.Request WHERE RequestNumber=@RequestNumber
		END
	END
	
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispDeleteAllResults] TO Remi
GO
update Batches set Priority=0 where Priority=6058
go
update Batches set RequestPurpose=0 where RequestPurpose=6057
GO
delete from Lookups where LookupID in (6058,6057)
go
ALTER PROCEDURE [dbo].[remispMoveBatchForward] @RequestNumber NVARCHAR(11), @UserName NVARCHAR(255)
AS
BEGIN
	DECLARE @ReqStatus NVARCHAR(50)
	DECLARE @BatchStatus NVARCHAR(50)
	DECLARE @NewBatchStatus INT
	DECLARE @BatchID INT
	DECLARE @RequestID INT
	DECLARE @JobID INT
	DECLARE @ProductID INT
	DECLARE @RowID INT
	DECLARE @TestStageID INT
	DECLARE @TestStageName NVARCHAR(255)
	DECLARE @ReturnVal INT
	DECLARE @TestID INT
	DECLARE @IncomingCount INT
	DECLARE @FailureCount INT
	DECLARE @UnitCount INT
	DECLARE @ExitedEarly BIT
	DECLARE @ProductType NVARCHAR(150)
	SET @ExitedEarly = CONVERT(BIT, 0)
	SET @ReturnVal = 0
	CREATE TABLE #TempSetup (TestStageID INT, TestStageName NVARCHAR(255), TestID INT, TestName NVARCHAR(255), Selected BIT)
	CREATE TABLE #Setup (ID INT IDENTITY(1,1), TestStageID INT, TestStageName NVARCHAR(255), TestID INT, TestName NVARCHAR(255), Selected BIT)
	CREATE TABLE #exceptions (Row INT, ID INT, RequestNumber NVARCHAR(11), BatchUnitNumber INT, ReasonForRequestID INT, ProductGroupName NVARCHAR(150), JobName NVARCHAR(150), TestStageName NVARCHAR(150), TestName NVARCHAR(150), TestStageID INT, TestUnitID INT, LastUser NVARCHAR(150), ProductTypeID INT, AccessoryGroupID INT, ProductID INT, ProductType NVARCHAR(150), AccessoryGroupName NVARCHAR(150), IsMQual INT, TestCenter NVARCHAR(MAX), TestCenterID INT, ReasonForRequest NVARCHAR(150), TestID INT)

	BEGIN TRY
		SELECT @RequestID=RequestID FROM Req.Request WHERE RequestNumber=@RequestNumber
		SELECT @UnitCount = COUNT(ID) FROM TestUnits WHERE BatchID=@BatchID
		SELECT @JobID = j.ID, @BatchID=b.ID, @ProductID=b.ProductID, @BatchStatus = CASE b.BatchStatus WHEN 1 THEN 'Held' WHEN 2 THEN 'InProgress' WHEN 3 THEN 'Quarantined'
			WHEN 4 THEN 'Received' WHEN 5 THEN 'Complete' WHEN 7 THEN 'Rejected' WHEN 8 THEN 'TestingComplete' ELSE 'NotSet' END, @NewBatchStatus = b.BatchStatus,
			@ProductType = l.[Values]
		FROM Batches b
			INNER JOIN Jobs j ON j.JobName = b.JobName
			INNER JOIN Lookups l ON l.LookupID=b.ProductTypeID
		WHERE b.QRANumber=@RequestNumber
		
		IF ((SELECT BatchID FROM Req.Request WHERE RequestNumber=@RequestNumber) IS NULL)
		BEGIN
			UPDATE Req.Request
			SET BatchID=@BatchID
			WHERE RequestNumber=@RequestNumber
		END
		
		--Get the setup information for the batch
		INSERT INTO #TempSetup
		EXEC Req.GetRequestSetupInfo @ProductID, @JobID, @BatchID, 1, 0, '', 0
		INSERT INTO #TempSetup
		EXEC Req.GetRequestSetupInfo @ProductID, @JobID, @BatchID, 2, 0, '', 0

		DELETE FROM #TempSetup WHERE Selected=0

		--Determine Request Status Value
		SELECT @ReqStatus = rd.Value
		FROM Req.ReqFieldData rd
			INNER JOIN Req.ReqFieldSetup fs ON fs.ReqFieldSetupID=rd.ReqFieldSetupID
			INNER JOIN Req.ReqFieldMapping fm ON fm.ExtField=fs.Name AND fm.RequestTypeID=fs.RequestTypeID AND fm.IntField='RequestStatus'
		WHERE RequestID=@RequestID

		--If request is closed/cancelled/completed and the batch isn't then close it
		If (LOWER(@ReqStatus) = 'completed' OR LOWER(@ReqStatus) = 'canceled' OR LOWER(@ReqStatus) LIKE '%closed%') AND @BatchStatus <> 'Complete'
		BEGIN
			SET @NewBatchStatus=5
		END

		--If batch is at incoming and the request was set to assigned then move back forward to Assigned status
		IF (@BatchStatus = 'Received' And @ReqStatus = 'Assigned')
		BEGIN
			SET @NewBatchStatus=2
		END

		--If batch is not at rejected but the request status is rejected then set to rejected
		IF (@BatchStatus <> 'Rejected' And @ReqStatus = 'Rejected')
		BEGIN
			SET @NewBatchStatus=7
		END

		--Determine if it should be at incoming
		SELECT @TestStageID=ID FROM TestStages ts WHERE ts.JobID=@JobID AND ISNULL(IsArchived, 0)=0 AND TestStageName='Sample Evaluation'
		SELECT @TestID=ID FROM Tests ts WHERE ISNULL(IsArchived, 0)=0 AND TestName='Sample Evaluation'
		
		SELECT @IncomingCount = COUNT(DISTINCT TestUnitID) 
		FROM TestRecords tr 
		WHERE tr.TestUnitID IN (SELECT ID FROM TestUnits tu WHERE tu.BatchID=@BatchID) AND TestID=@TestID AND TestStageID=@TestStageID
		
		IF (@UnitCount <> @IncomingCount AND LOWER(@ProductType)='handheld')
		BEGIN
			SET @TestStageName = 'Sample Evaluation'
			SET @NewBatchStatus = 4
		END
		ELSE
		BEGIN
			SET @TestStageID = NULL
			SET @TestID = NULL
			SET @FailureCount = NULL
			
			--Get the Request Setup
			INSERT INTO #Setup
			SELECT s.* 
			FROM #TempSetup s
				INNER JOIN TestStages ts ON ts.ID = s.TestStageID
			ORDER BY ts.ProcessOrder ASC
			
			INSERT INTO #exceptions (row,ID,RequestNumber, BatchUnitNumber, ReasonForRequestID, ProductGroupName, JobName, TestStageName, TestName, TestStageID, TestUnitID,LastUser, ProductTypeID, AccessoryGroupID, ProductID, ProductType, AccessoryGroupName, IsMQual, TestCenter, TestCenterID, ReasonForRequest, TestID)
			EXEC [dbo].[remispExceptionSearch] @IncludeBatches=1,@QRANumber=@RequestNumber

			SELECT @RowID=MIN(ID) FROM #Setup

			WHILE (@RowID IS NOT NULL)
			BEGIN
				DECLARE @CountUnitExceptioned INT
				DECLARE @TestStageType INT
				DECLARE @ProcessOrder INT
				SET @ProcessOrder = 0
				SET @TestStageType = 0
				SET @CountUnitExceptioned = 0
				SET @TestID=NULL
				SET @TestStageID=NULL
				SET @TestStageName=NULL
				
				SELECT @TestID=s.TestID, @TestStageID=s.TestStageID, @TestStageName=s.TestStageName, @TestStageType=ts.TestStageType, @ProcessOrder=ts.ProcessOrder
				FROM #Setup s
					INNER JOIN TestStages ts ON ts.ID=s.TestStageID
				WHERE s.ID=@RowID

				SELECT @CountUnitExceptioned = COUNT(DISTINCT TestUnitID)
				FROM #exceptions e
				WHERE (e.TestID=@TestID AND e.TestStageID IS NULL AND e.TestUnitID IS NULL)--Exception For Test regardless of unit
					OR
					(e.TestID=@TestID AND e.TestStageID = @TestStageID AND e.TestUnitID IS NULL)--Exception For Test/Stage regardless of unit
					OR
					(e.TestID=@TestID AND e.TestStageID = @TestStageID AND e.TestUnitID IN (SELECT ID FROM TestUnits WHERE BatchID=@BatchID))--Unit Exception For Test/Stage
					OR
					(e.TestID IS NULL AND e.TestStageID = @TestStageID AND e.TestUnitID IS NULL)--Exception For Stage regardless of unit
					OR
					(e.TestID IS NULL AND e.TestStageID IS NULL AND e.TestUnitID IN (SELECT ID FROM TestUnits WHERE BatchID=@BatchID))--Entire Unit Level Exception
					OR
					(e.TestID IS NULL AND e.TestStageID = @TestStageID AND e.TestUnitID IN (SELECT ID FROM TestUnits WHERE BatchID=@BatchID))--Unit Exception For Stage

				IF ((@UnitCount - @CountUnitExceptioned) <> (SELECT COUNT(DISTINCT ID) 
								FROM TestRecords tr
								WHERE TestStageID=@TestStageID AND TestID=@TestID 
									AND TestUnitID IN (SELECT ID FROM TestUnits WHERE BatchID=@BatchID)
									AND tr.Status IN (1, 2, 3, 6)))
				BEGIN
					SET @RowID = NULL
					SET @ExitedEarly = CONVERT(BIT, 1)
					BREAK
				END
				ELSE
				BEGIN
					SET @ExitedEarly = CONVERT(BIT, 0)
					SET @TestStageID = NULL
					SET @TestStageName = NULL
					SET @TestID = NULL
					SELECT @RowID=MIN(ID) FROM #Setup WHERE ID > @RowID
					CONTINUE
				END
			END
		END

		IF (@ExitedEarly = CONVERT(BIT, 0))
		BEGIN
			TRUNCATE TABLE #Setup
			INSERT INTO #Setup
			EXEC Req.GetRequestSetupInfo @ProductID, @JobID, @BatchID, 5, 0, '', 0
			
			IF ((SELECT COUNT(*) FROM #Setup)=1)
			BEGIN 
				SELECT @FailureCount = COUNT(DISTINCT TestUnitID) 
				FROM TestRecords tr 
				WHERE tr.TestUnitID IN (SELECT ID FROM TestUnits tu WHERE tu.BatchID=@BatchID) AND tr.Status=3
				
				IF (@FailureCount > 0)
				BEGIN
					IF (@FailureCount <> (SELECT COUNT(DISTINCT TestUnitID)
						FROM TestRecords tr 
							INNER JOIN #Setup s ON s.TestID=tr.TestID AND s.TestStageID=tr.TestStageID
						WHERE tr.TestUnitID IN (SELECT ID FROM TestUnits tu WHERE tu.BatchID=@BatchID)))
					BEGIN
						SELECT @TestStageName = s.TestStageName FROM #Setup s
					END
				END
			END
			ELSE
			BEGIN
				TRUNCATE TABLE #Setup
				INSERT INTO #Setup
				EXEC Req.GetRequestSetupInfo @ProductID, @JobID, @BatchID, 4, 0, '', 0
				
				IF ((SELECT COUNT(*) FROM #Setup WHERE TestStageName='Report')=1)
				BEGIN
					SET @TestStageName = 'Report'
				END
			END
		END
		
		IF (@TestStageID > 0)
		BEGIN
			UPDATE Batches SET TestStageName=@TestStageName, LastUser=@UserName, BatchStatus=@NewBatchStatus WHERE ID=@BatchID
		END
		SET @ReturnVal = 1
	END TRY
	BEGIN CATCH
		SET @ReturnVal = 0
	END CATCH
	
	RETURN @ReturnVal

	DROP TABLE #TempSetup
	DROP TABLE #Setup
	DROP TABLE #exceptions
END
GO
GRANT EXECUTE ON remispMoveBatchForward TO Remi
GO
UPDATE Menu set Name='Advanced Search' where Name='Result Search'
GO
ROLLBACK TRAN