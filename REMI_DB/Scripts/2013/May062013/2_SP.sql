/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        ci0000001593275\SQLDeveloper.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 5/1/2013 11:40:20 AM

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
PRINT N'Altering [dbo].[remispUsersDeleteSingleItem]'
GO
ALTER PROCEDURE [dbo].[remispUsersDeleteSingleItem]
/*	'===============================================================
	'   NAME:                	remispUsersDeleteSingleItem
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Deletes an item from table: Users
	'   IN:        ID of item          
	'   OUT: 		Nothing         
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@userIDToDelete nvarchar(255),
	@UserID INT
AS
	update ProductManagers 
	set LastUser = (SELECT LDAPLogin FROM Users WHERE ID=@UserID) 
	FROM ProductManagers
	where UserID = @userIDToDelete

	delete from ProductManagers where UserID = @userIDToDelete

	update	Users set LastUser = (SELECT LDAPLogin FROM Users WHERE ID=@UserID)  where ID = @userIDToDelete
	delete from users where ID = @userIDToDelete
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispGetUserTraining]'
GO
ALTER PROCEDURE [dbo].[remispGetUserTraining] @UserID INT
AS
BEGIN
	SELECT UserID, DateAdded, Lookups.LookupID, Lookups.[Values] AS TrainingOption, CASE WHEN ID IS NOT NULL THEN CONVERT(BIT,1) ELSE CONVERT(BIT, 0) END AS IsTrained
	FROM Lookups
		LEFT OUTER JOIN UserTraining ON UserTraining.LookupID=Lookups.LookupID AND UserTraining.UserID=@UserID
	WHERE Type='Training'
	ORDER BY Lookups.[Values]
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispProductManagersDeleteSingleItem]'
GO
ALTER PROCEDURE [dbo].[remispProductManagersDeleteSingleItem]
/*	'===============================================================
	'   NAME:                	remispProductManagersDeleteSingleItem
	'   DATE CREATED:       	11 Sept 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Deletes an item from table: UsersXProductGroups
	'   IN:        UserID of user, ProductGroupID of productGroup          
	'   OUT: 		Nothing         
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@UserIDToRemove INT,
	@ProductID INT,
	@UserID INT
AS
	update productmanagers 
	set lastuser = (SELECT LDAPLogin FROM Users WHERE ID=@UserID)
	FROM productManagers
		INNER JOIN Products p ON ProductManagers.ProductID=p.ID
	WHERE p.ID = @ProductID and UserID = @UserIDToRemove

	delete productmanagers
	from productmanagers
		INNER JOIN Products p ON ProductManagers.ProductID=p.ID
	WHERE p.ID = @ProductID and UserID = @UserIDToRemove
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispProductManagersSelectList]'
GO
ALTER PROCEDURE [dbo].[remispProductManagersSelectList]
/*	'===============================================================
'   NAME:                	remispProductManagersSelectList
'   DATE CREATED:       	11 Sept 2009
'   CREATED BY:          	Darragh O'Riordan
'   FUNCTION:            	Retrieves  data from table: UsersXProductGroups OR the number of records in the table
'   IN:         Optional: RecordCount         
'   OUT: 		List Of:ProductGroup        
'   VERSION: 1           
'   COMMENTS:            
'   MODIFIED ON:         
'   MODIFIED BY:         
'   REASON MODIFICATION: 
'===============================================================*/
	@RecordCount int = NULL OUTPUT,
	@UserID INT
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM  productmanagers AS uxpg WHERE uxpg.UserID = @UserID)
		RETURN
	END

	SELECT p.ProductGroupName, p.ID  
	FROM productmanagers AS uxpg
		INNER JOIN Products p ON p.ID=uxpg.ProductID
	WHERE uxpg.UserID = @UserID
	ORDER BY p.ProductGroupName
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remispUsersDeleteSingleItem]'
GO
GRANT EXECUTE ON  [dbo].[remispUsersDeleteSingleItem] TO [remi]
GO
ALTER PROCEDURE [dbo].[remispTestUnitsSelectListByLastUser] @UserID INT, @includeCompletedQRA BIT = 1
AS
	DECLARE @username NVARCHAR(255)
	SELECT @username = LDAPLogin FROM Users WHERE ID=@UserID

	SELECT 
	tu.ID,
	tu.batchid, 
	tu.BSN, 
	tu.BatchUnitNumber, 
	tu.CurrentTestStageName, 
	tu.CurrentTestName, 
	tu.AssignedTo,
	tu.ConcurrencyID,
	tu.LastUser,
	tu.Comment,
	b.QRANumber,
	dtl.ConcurrencyID as dtlCID,
	dtl.ID as dtlID,
	dtl.InTime as dtlInTime,
	dtl.InUser as dtlInUser,
	dtl.OutTime as dtlouttime,
	dtl.OutUser as dtloutuser,
	tl.TrackingLocationName,
	tl.ID as dtlTLID
		
	from TestUnits as tu, devicetrackinglog as dtl, Batches as b, TrackingLocations as tl  
	where tl.ID = dtl.TrackingLocationID and tu.id = dtl.testunitid and tu.batchid = b.id 
		and inuser = @username and outuser is null
		AND (
				(@includeCompletedQRA = 0 AND b.BatchStatus <> 5)
				OR
				(@includeCompletedQRA = 1)
			)
	order by QRANumber desc, BatchUnitNumber 
GO
GRANT EXECUTE ON remispTestUnitsSelectListByLastUser TO REMI
GO
ALTER PROCEDURE [dbo].[remispUsersSelectListByTestCentre] @TestLocation INT, @IncludeInActive INT = 1, @determineDelete INT = 1, @RecordCount int = NULL OUTPUT
AS
	DECLARE @ConCurID timestamp


	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) 
							FROM Users 
							WHERE TestCentreID=TestCentreID
								AND 
								(
									(@IncludeInActive = 0 AND IsActive=1)
									OR
									@IncludeInActive = 1
								)
							)
		RETURN
	END

	SELECT UsersRows.BadgeNumber,UsersRows.ConcurrencyID,UsersRows.ID,usersrows.TestCentre, UsersRows.LastUser,UsersRows.LDAPLogin,UsersRows.Row, UsersRows.IsActive, CASE WHEN @determineDelete = 1 THEN dbo.remifnUserCanDelete(UsersRows.LDAPLogin) ELSE 0 END AS CanDelete, UsersRows.DefaultPage, UsersRows.TestCentreID
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY ID) AS Row, Users.BadgeNumber,Users.ConcurrencyID,Users.ID,Users.LastUser,Users.LDAPLogin, 
				Lookups.[Values] AS TestCentre, ISNULL(Users.IsActive,1) AS IsActive, Users.DefaultPage, Users.TestCentreID
			FROM Users
				LEFT OUTER JOIN Lookups ON Type='TestCenter' AND LookupID=TestCentreID
			WHERE (TestCentreID=@TestLocation OR @TestLocation = 0)
				AND 
				(
					(@IncludeInActive = 0 AND ISNULL(Users.IsActive, 1)=1)
					OR
					@IncludeInActive = 1
				)
		) AS UsersRows
	ORDER BY IsActive DESC, LDAPLogin
GO
-- Permissions

GRANT EXECUTE ON  [dbo].[remispUsersSelectListByTestCentre] TO [remi]
GO
GO
ALTER PROCEDURE [dbo].[remispTrackingLocationsSearchFor]
/*	'===============================================================
	'   NAME:                	remispTrackingLocationsSearchFor
	'   DATE CREATED:       	21 Oct 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves paged data from table: TrackingLocations OR the number of records in the table
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
@RecordCount int = NULL OUTPUT,
@ID int = null,
@TrackingLocationName nvarchar(400)= null, 
@GeoLocationID INT= null, 
@Status int = null,
@TrackingLocationTypeID int= null,
@TrackingLocationTypeName nvarchar(400)=null,
@TrackingLocationFunction int = null,
@HostName nvarchar(255) = null,
@OnlyActive INT = 0,
@RemoveHosts INT = 0
AS
DECLARE @TrueBit BIT
DECLARE @FalseBit BIT
SET @TrueBit = CONVERT(BIT, 1)
SET @FalseBit = CONVERT(BIT, 0)

IF (@RecordCount IS NOT NULL)
BEGIN
	SET @RecordCount = (SELECT distinct COUNT(*) 
	FROM TrackingLocations as tl 
		INNER JOIN TrackingLocationTypes as tlt ON tl.TrackingLocationTypeID = tlt.ID
		LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
	WHERE (tl.ID = @ID or @ID is null) 
	and (tlh.status = @Status or @Status is null)
	and (tl.TrackingLocationName = @TrackingLocationName or @TrackingLocationName is null)
	and (TestCenterLocationID = @GeoLocationID or @GeoLocationID is null)
	and (tlh.HostName = @HostName or tlh.HostName='all' or @HostName is null)
	and (tl.TrackingLocationTypeID = @TrackingLocationTypeID or @TrackingLocationTypeID is null)
	and ((tl.TrackingLocationTypeID= tlt.id and tlt.TrackingLocationTypeName = @TrackingLocationTypeName) or @TrackingLocationTypeName is null)
	 and ((tl.TrackingLocationTypeID= tlt.id and tlt.TrackingLocationFunction = @TrackingLocationFunction )or @TrackingLocationFunction is null)
	 AND (
				(@OnlyActive = 1 AND ISNULL(tl.Decommissioned, 0) = 0)
				OR
				(@OnlyActive = 0)
			)
	)
	RETURN
END

SELECT DISTINCT tl.ID, tl.TrackingLocationName, tl.TestCenterLocationID, CASE WHEN tlh.Status IS NULL THEN 3 ELSE tlh.Status END AS Status, tl.LastUser, CASE WHEN @RemoveHosts = 1 THEN '' ELSE tlh.HostName END AS HostName,
	tl.ConcurrencyID, tl.comment,l3.[Values] AS GeoLocationName, CASE WHEN @RemoveHosts = 1 THEN 0 ELSE ISNULL(tlh.ID,0) END AS TrackingLocationHostID,
	(
		SELECT COUNT(*) as CurrentCount 
		FROM TestUnits AS tu
			INNER JOIN DeviceTrackingLog AS dtl ON dtl.TestUnitID = tu.ID
		WHERE dtl.TrackingLocationID = tl.ID and (dtl.OutUser IS NULL)
	) AS CurrentCount,
	tlt.wilocation as TLTWILocation, tlt.UnitCapacity as TLTUnitCapacity, tlt.Comment as TLTComment, tlt.ConcurrencyID as TLTConcurrencyID, tlt.LastUser as TLTLastUser,
	tlt.ID as TLTID, tlt.TrackingLocationTypeName as TLTName, tlt.TrackingLocationFunction as TLTFunction,
	(
		SELECT TOP(1) tu.CurrentTestName as CurrentTestName
		FROM TestUnits AS tu
			INNER JOIN DeviceTrackingLog AS dtl ON dtl.TestUnitID = tu.ID
		WHERE tu.CurrentTestName is not null and dtl.TrackingLocationID = tl.ID and (dtl.OutUser IS NULL)
	) AS CurrentTestName,
	(CASE WHEN EXISTS (SELECT TOP 1 1 FROM DeviceTrackingLog dl WHERE dl.TrackingLocationID=tl.ID) THEN @FalseBit ELSE @TrueBit END) As CanDelete,
	ISNULL(tl.Decommissioned, 0) AS Decommissioned
	FROM TrackingLocations as tl
		INNER JOIN TrackingLocationTypes as tlt ON tl.TrackingLocationTypeID = tlt.ID
		LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
		LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND l3.lookupID=tl.TestCenterLocationID
	WHERE (tl.ID = @ID or @ID is null) and (tlh.status = @Status or @Status is null)
		and (tl.TrackingLocationName = @TrackingLocationName or @TrackingLocationName is null)
		and (TestCenterLocationID = @GeoLocationID or @GeoLocationID is null)
		and 
		(
			tlh.HostName = @HostName 
			or 
			tlh.HostName='all'
			or
			@HostName is null 
			or 
			(
				@HostName is not null 
				and exists 
					(
						SELECT tlt1.TrackingLocationTypeName 
						FROM TrackingLocations as tl1
							INNER JOIN trackinglocationtypes as tlt1 ON tlt1.ID = tl1.TrackingLocationTypeID
							INNER JOIN TrackingLocationsHosts tlh1 ON tl1.ID = tlh1.TrackingLocationID
						WHERE tlh1.HostName = @HostName and tlt1.TrackingLocationTypeName = 'Storage'
					)
			)
		)
		and (tl.TrackingLocationTypeID= tlt.id and tlt.id = @TrackingLocationTypeID or @TrackingLocationTypeID is null)
		and (tl.TrackingLocationTypeID= tlt.id and tlt.TrackingLocationTypeName = @TrackingLocationTypeName or @TrackingLocationTypeName is null)
		and (tl.TrackingLocationTypeID= tlt.id and tlt.TrackingLocationFunction = @TrackingLocationFunction or @TrackingLocationFunction is null)
		AND (
				(@OnlyActive = 1 AND ISNULL(tl.Decommissioned, 0) = 0)
				OR
				(@OnlyActive = 0)
			)
	ORDER BY ISNULL(tl.Decommissioned, 0), tl.TrackingLocationName
GO
GRANT EXECUTE ON remispTrackingLocationsSearchFor TO Remi
GO
CREATE PROCEDURE [dbo].[remispGetLookup] @Type NVARCHAR(150), @Lookup NVARCHAR(150)
AS
BEGIN
	SELECT LookupID, IsActive FROM Lookups WHERE Type=@Type AND [Values]=@Lookup
END
GO
-- Permissions

GRANT EXECUTE ON  [dbo].[remispGetLookup] TO [remi]
GO
ALTER procedure [dbo].[remispTrackingLocationsGetSpecificLocationForUsersTestCenter] @username nvarchar(255), @locationname nvarchar(500)
AS
declare @selectedID int

select top(1) @selectedID = tl.ID 
from TrackingLocations as tl
	INNER JOIN Lookups l ON l.Type='TestCenter' AND tl.TestCenterLocationID=l.LookupID
	INNER JOIN Users as u ON u.TestCentreID = l.lookUpID
	INNER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
where TrackingLocationName = @locationname and u.LDAPLogin = @username

return @selectedid
GO
ALTER PROCEDURE [dbo].[remispUsersSelectSingleItemByBadgeNumber] @BadgeNumber int
AS
	SELECT u.BadgeNumber,u.ConcurrencyID,u.ID,u.LastUser,u.LDAPLogin, u.TestCentreID, ISNULL(u.IsActive,1) As IsActive, u.DefaultPage, Lookups.[values] As TestCentre
	FROM Users as u
		LEFT OUTER JOIN Lookups ON Type='TestCenter' AND LookupID=TestCentreID
	WHERE BadgeNumber = @BadgeNumber
GO
ALTER PROCEDURE [dbo].[remispUsersSelectSingleItemByUserName] @LDAPLogin nvarchar(255)
AS
	SELECT Users.BadgeNumber,Users.ConcurrencyID,Users.ID,Users.LastUser,Users.LDAPLogin, Users.TestCentreID, ISNULL(Users.IsActive, 1) AS IsActive, Users.DefaultPage, Lookups.[Values] As TestCentre
	FROM Users
		LEFT OUTER JOIN Lookups ON Type='TestCenter' AND LookupID=TestCentreID
	WHERE LDAPLogin = @LDAPLogin
GO
ALTER PROCEDURE [dbo].[remispUsersSelectList]
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@RecordCount int = NULL OUTPUT
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Users)
		RETURN
	END

	SELECT UsersRows.BadgeNumber,UsersRows.ConcurrencyID,UsersRows.ID,usersrows.TestCentre, UsersRows.LastUser,UsersRows.LDAPLogin,UsersRows.Row, UsersRows.IsActive, dbo.remifnUserCanDelete(UsersRows.LDAPLogin) AS CanDelete, UsersRows.DefaultPage, UsersRows.TestCentreID
	FROM     
		(SELECT ROW_NUMBER() OVER (ORDER BY ID) AS Row, Users.BadgeNumber,Users.ConcurrencyID,Users.ID,Users.LastUser,Users.LDAPLogin, Lookups.[Values] AS TestCentre, ISNULL(Users.IsActive,1) AS IsActive, Users.DefaultPage, Users.TestCentreID
		FROM Users
			LEFT OUTER JOIN Lookups ON Type='TestCenter' AND LookupID=TestCentreID
		) AS UsersRows
	WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1) 
	ORDER BY IsActive desc, LDAPLogin
GO
ALTER PROCEDURE [dbo].[remispUsersInsertUpdateSingleItem]
/*	'===============================================================
	'   NAME:                	remispUsersInsertUpdateSingleItem
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates or updates an item in a table: Users
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@ID int OUTPUT,
	@LDAPLogin nvarchar(255),
	@BadgeNumber int=null,
	@TestCentreID INT = null,
	@LastUser nvarchar(255),
	@ConcurrencyID rowversion OUTPUT,
	@IsActive INT = 1,
	@DefaultPage NVARCHAR(255)
AS
	DECLARE @ReturnValue int

	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO Users (LDAPLogin, BadgeNumber, TestCentreID, LastUser, IsActive, DefaultPage)
		VALUES
		(
			@LDAPLogin,
			@BadgeNumber,
			@TestCentreID,
			@LastUser,
			@IsActive,
			@DefaultPage
		)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE Users SET
			LDAPLogin = @LDAPLogin,
			BadgeNumber=@BadgeNumber,
			TestCentreID = @TestCentreID,
			lastuser=@LastUser,
			IsActive=@IsActive,
			DefaultPage = @DefaultPage
		WHERE ID = @ID AND ConcurrencyID = @ConcurrencyID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM Users WHERE ID = @ReturnValue)
	SET @ID = @ReturnValue
	
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN 0
	END
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