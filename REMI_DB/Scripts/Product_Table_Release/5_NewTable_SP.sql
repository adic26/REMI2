/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        ci0000001593275\SQLDeveloper.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 3/18/2013 10:13:09 AM

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
PRINT N'Creating [dbo].[Products]'
GO
CREATE TABLE [dbo].[Products]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[ProductGroupName] [nvarchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[IsActive] [bit] NOT NULL CONSTRAINT [DF__Products__IsActi__37D02F05] DEFAULT ((1))
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_Products] on [dbo].[Products]'
GO
ALTER TABLE [dbo].[Products] ADD CONSTRAINT [PK_Products] PRIMARY KEY CLUSTERED  ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating index [UIX_Products_ProductGroupName] on [dbo].[Products]'
GO
CREATE UNIQUE NONCLUSTERED INDEX [UIX_Products_ProductGroupName] ON [dbo].[Products] ([ProductGroupName])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispUsersSelectListByTestCentre]'
GO
CREATE PROCEDURE [dbo].[remispUsersSelectListByTestCentre] @TestLocation NVARCHAR(200), @RecordCount int = NULL OUTPUT
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Users WHERE TestCentre=@TestLocation)
		RETURN
	END
	DECLARE @ConCurID timestamp

	SELECT UsersRows.BadgeNumber,UsersRows.ConcurrencyID,UsersRows.ID,usersrows.TestCentre, UsersRows.LastUser,UsersRows.LDAPLogin,UsersRows.Row   
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY ID) AS Row, Users.BadgeNumber,Users.ConcurrencyID,Users.ID,Users.LastUser,Users.LDAPLogin, Users.TestCentre
			FROM Users
			WHERE TestCentre=@TestLocation
		) AS UsersRows
	WHERE UsersRows.TestCentre = @TestLocation
	order by LDAPLogin
GO
GRANT EXECUTE ON remispUsersSelectListByTestCentre TO Remi
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispGetProducts]'
GO
CREATE PROCEDURE [dbo].[remispGetProducts]
AS
BEGIN
	DECLARE @TrueBit BIT
	SET @TrueBit = CONVERT(BIT, 1)

	SELECT ID, ProductGroupName
	FROM Products
	WHERE IsActive = @TrueBit
	ORDER BY ProductGroupname
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispGetProductNameByID]'
GO
CREATE PROCEDURE [dbo].[remispGetProductNameByID] @ProductID INT
AS
BEGIN
	SELECT ID, ProductGroupName
	FROM Products
	WHERE ID=@ProductID
END
GO
GRANT EXECUTE ON remispGetProductNameByID TO Remi
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispSaveProduct]'
GO
CREATE PROCEDURE [dbo].[remispSaveProduct] @ProductID int , @isActive int, @ProductGroupName NVARCHAR(150)
AS
BEGIN
	IF (@ProductID = 0)--ensure we don't have it
	BEGIN
		SELECT @ProductID = ID
		FROM Products
		WHERE LTRIM(RTRIM(ProductGroupName))=LTRIM(RTRIM(@ProductGroupName))
	END

	IF (@ProductID = 0)--if we still dont have it insert it
	BEGIN
		INSERT INTO Products VALUES (LTRIM(RTRIM(@ProductGroupName)), CONVERT(BIT, @isActive))
	END
	ELSE
	BEGIN
		UPDATE Products
		SET IsActive = CONVERT(BIT, @isActive), ProductGroupName = @ProductGroupName
		WHERE ID=@ProductID
	END
END
GRANT EXECUTE ON remispSaveProduct TO REMI
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispGetProductIDByName]'
GO
CREATE PROCEDURE [dbo].[remispGetProductIDByName] @ProductGroupName NVARCHAR(800)
AS
BEGIN
	SELECT ID, ProductGroupName
	FROM Products
	WHERE LTRIM(RTRIM(ProductGroupName))=LTRIM(RTRIM(@ProductGroupName))
END
GO
GRANT EXECUTE ON remispGetProductIDByName TO Remi
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispSaveLookup]'
GO
CREATE PROCEDURE [dbo].[remispSaveLookup] @LookupType NVARCHAR(150), @Value NVARCHAR(150)
AS
BEGIN
	DECLARE @LookupID INT
	SELECT @LookupID = MAX(LookupID) + 1 FROM Lookups
	
	IF NOT EXISTS (SELECT 1 FROM Lookups WHERE Type=@LookupType AND [Values]=LTRIM(RTRIM(@Value)))
	BEGIN
		INSERT INTO Lookups (LookupID, Type, [Values]) VALUES (@LookupID, @LookupType, LTRIM(RTRIM(@Value)))
	END
END
GO
GRANT EXECUTE ON remispSaveLookup TO Remi
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispTrackingLocationsHostID]'
GO
CREATE PROCEDURE [dbo].[remispTrackingLocationsHostID] @ComputerName NVARCHAR(255)
AS
BEGIN
	DECLARE @ID INT
	SET @ID = 0

	SELECT @ID=ID FROM TrackingLocationsHosts WHERE HostName=@ComputerName

	Return @ID
END
GRANT EXECUTE ON remispTrackingLocationsHostID TO Remi
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [dbo].[Batches]'
GO
ALTER TABLE [dbo].[Batches] ADD CONSTRAINT [FK_Batches_Products] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Products] ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [dbo].[ProductConfiguration]'
GO
ALTER TABLE [dbo].[ProductConfiguration] ADD CONSTRAINT [FK_ProductConfiguration_Products] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Products] ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [dbo].[ProductManagers]'
GO
ALTER TABLE [dbo].[ProductManagers] ADD CONSTRAINT [FK_ProductManagers_Products] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Products] ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [dbo].[ProductSettings]'
GO
ALTER TABLE [dbo].[ProductSettings] ADD CONSTRAINT [FK_ProductSettings_Products] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Products] ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remispGetProductNameByID]'
GO
GRANT EXECUTE ON  [dbo].[remispGetProductNameByID] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispSaveProduct]'
GO
GRANT EXECUTE ON  [dbo].[remispSaveProduct] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispGetProductIDByName]'
GO
GRANT EXECUTE ON  [dbo].[remispGetProductIDByName] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispSaveLookup]'
GO
GRANT EXECUTE ON  [dbo].[remispSaveLookup] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispTrackingLocationsHostID]'
GO
GRANT EXECUTE ON  [dbo].[remispTrackingLocationsHostID] TO [remi]
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