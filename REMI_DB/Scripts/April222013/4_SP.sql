/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        ci0000001593275\SQLDeveloper.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 4/17/2013 11:35:31 AM

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
PRINT N'Altering [dbo].[remispUsersSelectSingleItemByBadgeNumber]'
GO
ALTER PROCEDURE [dbo].[remispUsersSelectSingleItemByBadgeNumber] @BadgeNumber int
AS
	SELECT u.BadgeNumber,u.ConcurrencyID,u.ID,u.LastUser,u.LDAPLogin, u.TestCentre, ISNULL(u.IsActive,1) As IsActive, u.DefaultPage
	FROM Users as u
	WHERE BadgeNumber = @BadgeNumber
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispUsersSelectSingleItemByUserName]'
GO
ALTER PROCEDURE [dbo].[remispUsersSelectSingleItemByUserName] @LDAPLogin nvarchar(255)
AS
	SELECT Users.BadgeNumber,Users.ConcurrencyID,Users.ID,Users.LastUser,Users.LDAPLogin, Users.TestCentre, ISNULL(Users.IsActive, 1) AS IsActive, Users.DefaultPage
	FROM Users
	WHERE LDAPLogin = @LDAPLogin
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispUsersSelectList]'
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

	SELECT UsersRows.BadgeNumber,UsersRows.ConcurrencyID,UsersRows.ID,usersrows.TestCentre, UsersRows.LastUser,UsersRows.LDAPLogin,UsersRows.Row, UsersRows.IsActive, dbo.remifnUserCanDelete(UsersRows.LDAPLogin) AS CanDelete, UsersRows.DefaultPage
	FROM     
		(SELECT ROW_NUMBER() OVER (ORDER BY ID) AS Row, Users.BadgeNumber,Users.ConcurrencyID,Users.ID,Users.LastUser,Users.LDAPLogin, Users.TestCentre, ISNULL(Users.IsActive,1) AS IsActive, Users.DefaultPage
		FROM Users) AS UsersRows
	WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1) 
	ORDER BY IsActive desc, LDAPLogin
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispUsersInsertUpdateSingleItem]'
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
	@testcentre nvarchar(200) = null,
	@LastUser nvarchar(255),
	@ConcurrencyID rowversion OUTPUT,
	@IsActive INT = 1,
	@DefaultPage NVARCHAR(255)
AS
	DECLARE @ReturnValue int

	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO Users (LDAPLogin, BadgeNumber, TestCentre, LastUser, IsActive, DefaultPage)
		VALUES
		(
			@LDAPLogin,
			@BadgeNumber,
			@TestCentre,
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
			TestCentre = @testcentre,
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispUsersSelectListByTestCentre]'
GO
ALTER PROCEDURE [dbo].[remispUsersSelectListByTestCentre] @TestLocation INT, @RecordCount int = NULL OUTPUT
AS
	DECLARE @ConCurID timestamp
	DECLARE @TestCenter NVARCHAR(200)

	SELECT @TestCenter = [Values] FROM Lookups WHERE LookupID=@TestLocation

	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Users WHERE TestCentre=@TestCenter)
		RETURN
	END

	SELECT UsersRows.BadgeNumber,UsersRows.ConcurrencyID,UsersRows.ID,usersrows.TestCentre, UsersRows.LastUser,UsersRows.LDAPLogin,UsersRows.Row, UsersRows.IsActive, dbo.remifnUserCanDelete(UsersRows.LDAPLogin) AS CanDelete, UsersRows.DefaultPage
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY ID) AS Row, Users.BadgeNumber,Users.ConcurrencyID,Users.ID,Users.LastUser,Users.LDAPLogin, Users.TestCentre, ISNULL(Users.IsActive,1) AS IsActive, Users.DefaultPage
			FROM Users
			WHERE TestCentre=@TestCenter OR @TestLocation = 0
		) AS UsersRows
	WHERE UsersRows.TestCentre = @TestCenter OR @TestLocation = 0
	order by IsActive DESC, LDAPLogin
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering trigger [dbo].[UsersAuditDelete] on [dbo].[Users]'
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[UsersAuditDelete]
   ON  [dbo].[Users]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into Usersaudit (
	UserId, 
	LDAPLogin, 
	BadgeNumber,
	TestCentre,
	Username,	
	Action,
	IsActive, DefaultPage)
	Select 
	Id, 
	LDAPLogin, 
	BadgeNumber,
	TestCentre,
	lastuser,
	'D',
	IsActive, DefaultPage
	from deleted
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering trigger [dbo].[UsersAuditInsertUpdate] on [dbo].[Users]'
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[UsersAuditInsertUpdate]
   ON  [dbo].[Users]
    after insert, update
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

--Only inserts records into the Audit table if the row was either updated or inserted and values actually changed.
select @count= count(*) from
(
   select LDAPLogin, BadgeNumber, TestCentre, IsActive, DefaultPage from Inserted
   except
   select LDAPLogin, BadgeNumber, TestCentre, IsActive, DefaultPage from Deleted
) a

if ((@count) >0)
	begin
		insert into Usersaudit (
		UserId, 
		LDAPLogin, 
		BadgeNumber,
		TestCentre,
		Username,
		Action,
		IsActive, DefaultPage)
		Select 
		Id, 
		LDAPLogin, 
		BadgeNumber,
		TestCentre,
		lastuser,
		@action, 
		IsActive, DefaultPage
		from inserted
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remispUsersSelectSingleItemByBadgeNumber]'
GO
GRANT EXECUTE ON  [dbo].[remispUsersSelectSingleItemByBadgeNumber] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispUsersSelectSingleItemByUserName]'
GO
GRANT EXECUTE ON  [dbo].[remispUsersSelectSingleItemByUserName] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispUsersSelectList]'
GO
GRANT EXECUTE ON  [dbo].[remispUsersSelectList] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispUsersInsertUpdateSingleItem]'
GO
GRANT EXECUTE ON  [dbo].[remispUsersInsertUpdateSingleItem] TO [remi]
GO
ALTER PROCEDURE [dbo].[remispTestRecordsSelectForBatch] @QRANumber nvarchar(11) = null
AS
BEGIN
	SELECT tr.FailDocRQID,tr.Comment,tr.ConcurrencyID,tr.FailDocNumber,tr.ID,tr.JobName,tr.ResultSource,tr.LastUser,tr.RelabVersion,tr.Status,tr.TestName,
		tr.TestStageName,tr.TestUnitID, b.QRANumber, tu.BatchUnitNumber,
	(
		Select sum(datediff(MINUTE,dtl.intime,(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end ))) 
		from Testrecordsxtrackinglogs trXtl
			INNER JOIN DeviceTrackingLog dtl ON dtl.ID = trXtl.TrackingLogID
		where trXtl.TestRecordID = tr.id
	) as TotalTestTimeMinutes,
	(
		select COUNT (*)
		from Testrecordsxtrackinglogs as trXtl
			INNER JOIN DeviceTrackingLog as dtl ON dtl.ID = trXtl.TrackingLogID
		where trXtl.TestRecordID = tr.id
	) as NumberOfTests	
	FROM TestRecords as tr
		INNER JOIN testunits tu ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b ON b.id = tu.batchid
	WHERE b.QRANumber = @QRANumber
	ORDER BY tr.TestStageName, tr.TestName, tr.TestUnitID
END
GO
GRANT EXECUTE ON remispTestRecordsSelectForBatch TO Remi
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
commit TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO