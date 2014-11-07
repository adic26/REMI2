BEGIN TRAN
GO
ALTER TABLE [Req].[ReqFieldSetup] ADD [ColumnOrder] [int] NULL
GO
UPDATE [Req].[ReqFieldSetup] SET [ColumnOrder]=1
GO
ALTER TABLE [Req].[ReqFieldSetup] ADD [ColumnOrder] [int] NULL
GO
CREATE TABLE [dbo].[UserDetails](
	[UserDetailsID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [int] NOT NULL,
	[LookupID] [int] NOT NULL,
	[IsDefault] [bit] NULL,
 CONSTRAINT [PK_UserDetails] PRIMARY KEY CLUSTERED 
(
	[UserDetailsID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[UserDetails]  WITH CHECK ADD  CONSTRAINT [FK_UserDetails_Lookups] FOREIGN KEY([LookupID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO
ALTER TABLE [dbo].[UserDetails] CHECK CONSTRAINT [FK_UserDetails_Lookups]
GO
ALTER TABLE [dbo].[UserDetails]  WITH CHECK ADD  CONSTRAINT [FK_UserDetails_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([ID])
GO
ALTER TABLE [dbo].[UserDetails] CHECK CONSTRAINT [FK_UserDetails_Users]
GO
ALTER TABLE [dbo].[UserDetails] ADD  DEFAULT ((0)) FOR [IsDefault]
GO
insert into UserDetails (UserID, LookupID)
SELECT ID, TestCentreID, 1
FROM Users
WHERE TestCentreID IS NOT NULL

insert into UserDetails (UserID, LookupID)
SELECT ID, DepartmentID, 1
FROM Users
WHERE DepartmentID IS NOT NULL

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Users_Department]') AND parent_object_id = OBJECT_ID(N'[dbo].[Users]'))
ALTER TABLE [dbo].[Users] DROP CONSTRAINT [FK_Users_Department]

ALTER TABLE Users DROP COLUMN DepartmentID
ALTER TABLE Users DROP COLUMN TestCentreID
ALTER TABLE Users DROP COLUMN _TestCentre
ALTER TABLE UsersAudit DROP COLUMN DepartmentID
ALTER TABLE UsersAudit DROP COLUMN TestCentreID
alter table usersaudit drop column _TestCentre

DROP PROCEDURE remispUsersSelectListByTestCentre
DROP PROCEDURE remispUsersSelectList
DROP PROCEDURE remispUsersSelectSingleItemBybadgenumber
DROP PROCEDURE remispUsersSelectSingleItemByUserName
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
   select LDAPLogin, BadgeNumber, IsActive, DefaultPage, ByPassProduct from Inserted
   except
   select LDAPLogin, BadgeNumber, IsActive, DefaultPage, ByPassProduct from Deleted
) a

if ((@count) >0)
	begin
		insert into Usersaudit (
		UserId, LDAPLogin, BadgeNumber, Username, Action,IsActive, DefaultPage, ByPassProduct)
		Select Id, LDAPLogin, BadgeNumber,lastuser,@action, IsActive, DefaultPage, ByPassProduct
		from inserted
	END
END
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
	
insert into Usersaudit (UserId, LDAPLogin, BadgeNumber,Username,Action,IsActive, DefaultPage, ByPassProduct)
Select Id, LDAPLogin, BadgeNumber,lastuser,'D',IsActive, DefaultPage, ByPassProduct
from deleted
END
GO
CREATE PROCEDURE [dbo].[remispMenuAccessByDepartment] @Name NVARCHAR(150) = NULL, @DepartmentID INT = NULL
AS
BEGIN
	SELECT m.Name, l.[Values] AS Department, m.Url
	FROM Menu m
		INNER JOIN MenuDepartment md ON m.MenuID=md.MenuID
		INNER JOIN Lookups l ON l.LookupID=md.DepartmentID
	WHERE (md.DepartmentID = @DepartmentID OR ISNULL(@DepartmentID, 0) = 0)
		AND (m.Name=@Name OR LTRIM(RTRIM(ISNULL(@Name, '')))  = '')
	ORDER BY l.[Values], m.Name
END
GO
-- Permissions

GRANT EXECUTE ON  [dbo].[remispMenuAccessByDepartment] TO [remi]
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
				LEFT OUTER JOIN UsersProducts up ON up.UserID = u.ID
				INNER JOIN UserDetails udtc ON udtc.UserID=u.ID
				INNER JOIN UserDetails udd ON udd.UserID=u.ID
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
					(up.ProductID=@ProductID) 
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
ALTER PROCEDURE [dbo].[remispUsersInsertUpdateSingleItem]
	@ID int OUTPUT,
	@LDAPLogin nvarchar(255),
	@BadgeNumber int=null,
	@LastUser nvarchar(255),
	@ConcurrencyID rowversion OUTPUT,
	@IsActive INT = 1,
	@ByPassProduct INT = 0,
	@DefaultPage NVARCHAR(255)
AS
	DECLARE @ReturnValue int

	IF (@ID IS NULL AND NOT EXISTS (SELECT 1 FROM Users WHERE LDAPLogin=@LDAPLogin)) -- New Item
	BEGIN
		INSERT INTO Users (LDAPLogin, BadgeNumber, LastUser, IsActive, DefaultPage, ByPassProduct)
		VALUES (@LDAPLogin, @BadgeNumber, @LastUser, @IsActive, @DefaultPage, @ByPassProduct)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE IF(@ConcurrencyID IS NOT NULL) -- Exisiting Item
	BEGIN
		UPDATE Users SET
			LDAPLogin = @LDAPLogin,
			BadgeNumber=@BadgeNumber,
			lastuser=@LastUser,
			IsActive=@IsActive,
			DefaultPage = @DefaultPage,
			ByPassProduct = @ByPassProduct
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
GRANT EXECUTE ON remispUsersInsertUpdateSingleItem TO Remi
GO
CREATE TABLE [dbo].[Menu](
	[MenuID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](150) NOT NULL,
	[Url] [nvarchar](250) NULL,
 CONSTRAINT [PK_Menu] PRIMARY KEY CLUSTERED 
(
	[MenuID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
Go
CREATE TABLE [dbo].[MenuDepartment](
	[MenuDepartmentID] [int] IDENTITY(1,1) NOT NULL,
	[DepartmentID] [int] NOT NULL,
	[MenuID] [int] NOT NULL,
 CONSTRAINT [PK_MenuDepartment] PRIMARY KEY CLUSTERED 
(
	[MenuDepartmentID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[MenuDepartment]  WITH CHECK ADD  CONSTRAINT [FK_MenuDepartment_Lookups] FOREIGN KEY([DepartmentID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO
ALTER TABLE [dbo].[MenuDepartment] CHECK CONSTRAINT [FK_MenuDepartment_Lookups]
GO
ALTER TABLE [dbo].[MenuDepartment]  WITH CHECK ADD  CONSTRAINT [FK_MenuDepartment_Menu] FOREIGN KEY([MenuID])
REFERENCES [dbo].[Menu] ([MenuID])
GO
ALTER TABLE [dbo].[MenuDepartment] CHECK CONSTRAINT [FK_MenuDepartment_Menu]
GO
INSERT INTO Menu (Name, Url) VALUES ('Overview','/Overview.aspx')
INSERT INTO Menu (Name, Url) VALUES ('Search','/Reports/search.aspx')
INSERT INTO Menu (Name, Url) VALUES ('Scan Device','/ScanForTest/Default.aspx')
INSERT INTO Menu (Name, Url) VALUES ('Batch Info','/ScanForInfo/Default.aspx')
INSERT INTO Menu (Name, Url) VALUES ('Product Info','/ScanForInfo/productgroup.aspx')
INSERT INTO Menu (Name, Url) VALUES ('Tracking Location','/ManageTestStations/TrackingLocation.aspx')
INSERT INTO Menu (Name, Url) VALUES ('Timeline','/ManageTestStations/default.aspx')
INSERT INTO Menu (Name, Url) VALUES ('Incoming','/Incoming/default.aspx')
INSERT INTO Menu (Name, Url) VALUES ('Inventory','/Inventory/Default.aspx')
INSERT INTO Menu (Name, Url) VALUES ('User','/ManageUser/Default.aspx')
INSERT INTO Menu (Name, Url) VALUES ('Results','/Relab/Results.aspx')
GO
DECLARE @DepartmentID INT
SELECT @DepartmentID = LookupID FROM Lookups l INNER JOIN LookupType lt ON lt.LookupTypeID=l.LookupTypeID WHERE lt.Name='Department'

INSERT INTO MenuDepartment (DepartmentID, MenuID)
SELECT @DepartmentID AS DepartmentID, MenuID
FROM Menu
GO
ALTER PROCEDURE [dbo].remispProductConfigurationUpload @ProductID INT, @TestID INT, @XML AS NTEXT, @LastUser As NVARCHAR(255), @PCName NVARCHAR(200) = NULL
AS
BEGIN
	IF (@PCName IS NULL OR LTRIM(RTRIM(@PCName)) = '') --Get The Root Name Of the XML
	BEGIN
		DECLARE @xmlTemp XML = CONVERT(XML, @XML)
		SELECT @PCName= LTRIM(RTRIM(x.c.value('local-name(/*[1])','nvarchar(max)')))
		FROM @xmlTemp.nodes('/*') x ( c )
		
		IF (@PCName = '')
		BEGIN
			SET @PCName = 'ProductConfiguration'
		END
	END

	IF EXISTS (SELECT 1 FROM ProductConfigurationUpload WHERE TestID=@TestID AND ProductID=@ProductID AND PCName=@PCName)
	BEGIN
		DECLARE @increment INT
		DECLARE @PCNameTemp NVARCHAR(200)
		SET @PCNameTemp = @PCName
		SET @increment = 1
		
		WHILE EXISTS (SELECT 1 FROM ProductConfigurationUpload WHERE TestID=@TestID AND ProductID=@ProductID AND PCName=@PCNameTemp)
		BEGIN
			SET @PCNameTemp = @PCName + CONVERT(NVARCHAR, @increment)
			SET @increment = @increment + 1
			print @PCNameTemp
		END
		
		SET @PCName = @PCNameTemp
	END
	
	IF NOT EXISTS (SELECT 1 FROM ProductConfigurationUpload WHERE TestID=@TestID AND ProductID=@ProductID AND PCName=@PCName)
	BEGIN
		INSERT INTO ProductConfigurationUpload (IsProcessed, ProductID, TestID, LastUser, PCName) 
		Values (CONVERT(BIT, 0), @ProductID, @TestID, @LastUser, @PCName)
		
		DECLARE @UploadID INT
		SET @UploadID =  @@IDENTITY

		EXEC remispProductConfigurationSaveXMLVersion @XML, @LastUser, @UploadID
	END
END
GO
ALTER PROCEDURE [Req].[RequestFieldSetup] @RequestTypeID INT, @IncludeArchived BIT = 0, @RequestNumber NVARCHAR(12) = NULL
AS
BEGIN
	DECLARE @RequestID INT
	DECLARE @RequestType NVARCHAR(150)
	SET @RequestID = 0
	SET @IncludeArchived=0

	SELECT @RequestType=lrt.[values] FROM Req.RequestType rt INNER JOIN Lookups lrt ON lrt.LookupID=rt.TypeID WHERE rt.RequestTypeID=@RequestTypeID

	IF (@RequestNumber IS NOT NULL)
		BEGIN
			SELECT @RequestID = RequestID FROM Req.Request WHERE RequestNumber=@RequestNumber
		END
		ELSE
		BEGIN
			SELECT @RequestNumber = REPLACE(RequestNumber, @RequestType + '-' + Right(Year(getDate()),2) + '-', '') + 1 FROM Req.Request WHERE RequestNumber LIKE @RequestType + '-' + Right(Year(getDate()),2) + '-%'
		
			IF (@RequestNumber IS NULL)
				SET @RequestNumber = '0001'
		
			SET @RequestNumber = @RequestType + '-' + Right(Year(getDate()),2) + '-' + @RequestNumber
		END

	SELECT rfs.ReqFieldSetupID, @RequestType AS RequestType, rfs.Name, lft.[Values] AS FieldType, rfs.FieldTypeID, 
			lvt.[Values] AS ValidationType, rfs.FieldValidationID, ISNULL(rfs.IsRequired, 0) AS IsRequired, rfs.DisplayOrder, 
			rfs.ColumnOrder, ISNULL(rfs.Archived, 0) AS Archived, rfs.Description, rfs.OptionsTypeID, @RequestTypeID AS RequestTypeID,
			@RequestNumber AS RequestNumber, @RequestID AS RequestID, rfd.Value, rfm.IntField, rfm.ExtField,
			CASE WHEN rfm.ID IS NOT NULL THEN 1 ELSE 0 END AS Internal,
			CASE WHEN @RequestID = 0 THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END AS NewRequest
	FROM Req.RequestType
		INNER JOIN Lookups lrt ON lrt.LookupID=Req.RequestType.TypeID
		INNER JOIN Req.ReqFieldSetup rfs ON rfs.RequestTypeID=Req.RequestType.RequestTypeID                  
		INNER JOIN Lookups lft ON lft.LookupID=rfs.FieldTypeID
		LEFT OUTER JOIN Lookups lvt ON lvt.LookupID=rfs.FieldValidationID
		LEFT OUTER JOIN Req.ReqFieldSetupRole ON Req.ReqFieldSetupRole.ReqFieldSetupID=rfs.ReqFieldSetupID
		LEFT OUTER JOIN Req.ReqFieldData rfd ON rfd.ReqFieldSetupID=rfs.ReqFieldSetupID
		LEFT OUTER JOIN Req.Request ON Req.Request.RequestID = rfd.RequestID AND RequestNumber=@RequestNumber
		LEFT OUTER JOIN Req.ReqFieldMapping rfm ON rfm.RequestTypeID=Req.RequestType.RequestTypeID AND rfm.ExtField=rfs.Name AND ISNULL(rfm.IsActive, 0) = 1
	WHERE (lrt.[Values] = @RequestType) AND
		(
			(@IncludeArchived = 1)
			OR
			(@IncludeArchived = 0 AND ISNULL(rfs.Archived, 0) = 0)
		)
	ORDER BY ISNULL(rfs.DisplayOrder, 0) ASC
END
GO
ALTER PROCEDURE [dbo].remispStationConfigurationProcess AS
BEGIN
	CREATE TABLE #temp2 (ID INT, ParentID INT, NodeType INT, LocalName NVARCHAR(100), Text NVARCHAR(100), ID_temp INT IDENTITY(1,1), ID_NEW INT, ParentID_NEW INT)
	CREATE TABLE #temp3 (LookupID INT, Type INT, LocalName NVARCHAR(150), ID INT IDENTITY(1,1))
	DECLARE @TrackingLocationHostID INT
	DECLARE @MaxID INT
	DECLARE @MaxLookupID INT
	DECLARE @idoc INT
	DECLARE @PluginID INT
	DECLARE @LookupTypeID INT
	DECLARE @ID INT
	DECLARE @xml XML
	DECLARE @LastUser NVARCHAR(255)

	IF ((SELECT COUNT(*) FROM StationConfigurationUpload WHERE ISNULL(IsProcessed,0)=0)=0)
		RETURN

	SELECT @LookupTypeID=LookupTypeID FROM LookupType WHERE Name='Configuration'

	WHILE ((SELECT COUNT(*) FROM StationConfigurationUpload WHERE ISNULL(IsProcessed,0)=0)>0)
	BEGIN
		SELECT TOP 1 @ID=ID, @xml =StationConfigXML, @TrackingLocationHostID=TrackingLocationHostID, @LastUser=LastUser, @PluginID = TrackingLocationPluginID
		FROM StationConfigurationUpload 
		WHERE ISNULL(IsProcessed,0)=0
				
		IF (@PluginID = 0)
			SET @PluginID = NULL

		exec sp_xml_preparedocument @idoc OUTPUT, @xml
	
		SELECT @MaxID = ISNULL(MAX(ID),0)+1 FROM TrackingLocationsHostsConfiguration
		SELECT @MaxLookupID = ISNULL(MAX(LookupID),0)+1 FROM Lookups

		SELECT * 
		INTO #temp
		FROM OPENXML(@idoc, '/')

		INSERT INTO #temp2 (ID, ParentID, NodeType, LocalName, Text, ParentID_NEW)
		SELECT ID, ParentID, NodeType, LocalName, '' AS Text, 0 AS ParentID_NEW
		FROM #temp 
		WHERE NodeType=1 AND (SELECT COUNT(ISNULL(ParentID,0)) FROM #temp t WHERE t.ParentID=#temp.ID AND t.ParentID IS NOT NULL)>1
		UNION
		SELECT ID, ParentID, NodeType, LocalName, '' AS Text, 0 AS ParentID_NEW
		FROM #temp 
		WHERE NodeType=1 AND (SELECT COUNT(*) FROM #temp t1 WHERE t1.NodeType=1 AND t1.ParentID=#temp.ID AND t1.ParentID IS NOT NULL GROUP BY t1.ParentID )=1
		UNION
		SELECT ID, ParentID, NodeType, LocalName, '' AS Text, 0 AS ParentID_NEW
		FROM #temp 
		WHERE NodeType=1 AND (SELECT COUNT(ISNULL(ParentID,0)) FROM #temp t WHERE t.ParentID=#temp.ID AND t.ParentID IS NOT NULL AND t.NodeType <> 3)=1
	
		UPDATE #temp2
		SET ID_NEW = ID_temp + @MaxID

		UPDATE #temp2
		SET ParentID_NEW = (SELECT t.ID_NEW FROM #temp2 t WHERE #temp2.ParentID=t.ID)
		WHERE #temp2.ParentID IS NOT NULL

		SET IDENTITY_INSERT TrackingLocationsHostsConfiguration ON

		INSERT INTO TrackingLocationsHostsConfiguration (ID, ParentId, ViewOrder, NodeName, LastUser, TrackingLocationHostID, TrackingLocationProfileID)
		SELECT ID_NEW, CASE WHEN ParentID_NEW = 0 THEN NULL ELSE ParentID_NEW END, ROW_NUMBER() OVER (ORDER BY id) AS ViewOrder, LocalName, @LastUser, @TrackingLocationHostID, @PluginID
		FROM #temp2
		ORDER BY ID, parentid

		SET IDENTITY_INSERT TrackingLocationsHostsConfiguration OFF
	
		INSERT INTO #temp3
		SELECT DISTINCT 0 AS LookupID, @LookupTypeID AS LookupTypeID, LTRIM(RTRIM(LocalName)) AS LocalName
		FROM #temp 
		WHERE NodeType=2 AND LocalName NOT IN (SELECT Lookups.[Values] FROM Lookups WHERE LookupTypeID=@LookupTypeID)

		INSERT INTO #temp3
		SELECT DISTINCT 0 AS LookupID, @LookupTypeID AS LookupTypeID, LTRIM(RTRIM(LocalName)) AS LocalName
		FROM #temp 
		WHERE NodeType=1 AND LocalName NOT IN (SELECT Lookups.[Values] FROM Lookups WHERE LookupTypeID=@LookupTypeID)
			AND ID IN (SELECT ParentID FROM #temp WHERE NodeType=3)

		UPDATE #temp3 SET LookupID=ID+@MaxLookupID

		insert into Lookups (LookupID, [Values], LookupTypeID)
		select LookupID, localname as [Values], [Type] As LookupTypeID from #temp3
	
		INSERT INTO TrackingLocationsHostsConfigValues (Value, LookupID, TrackingConfigID, LastUser, IsAttribute)
		SELECT ISNULL((SELECT t2.Text FROM #temp t2 WHERE t2.NodeType=3 AND t2.ParentID=#temp.ID), '') AS Value, 
			CASE WHEN #temp.NodeType=2 THEN (SELECT LookupID FROM Lookups WHERE LookupTypeID=@LookupTypeID AND [values]=#temp.LocalName) ELSE NULL END As LookupID, 
			(SELECT ID_NEW FROM #temp2 WHERE #temp.ParentID=#temp2.ID) AS TrackingConfigID, @LastUser As LastUser, 1 AS IsAttribute
		FROM #temp
		WHERE #temp.NodeType=2

		INSERT INTO TrackingLocationsHostsConfigValues (Value, LookupID, TrackingConfigID, LastUser, IsAttribute)
		SELECT ISNULL(#temp.Text,'') AS Value, (SELECT Lookups.LookupID FROM #temp t INNER JOIN Lookups ON LookupTypeID=@LookupTypeID AND LOWER(LTRIM(RTRIM([Values])))=LOWER(LTRIM(RTRIM(t.LocalName))) WHERE t.NodeType=1 AND t.id=#temp.parentid) AS LookupID,
			(SELECT #temp2.ID_NEW 
			FROM #temp2 	
				INNER JOIN #temp t1 ON t1.NodeType=1 AND #temp2.ID=t1.parentid
			WHERE #temp.ParentID=t1.ID) AS TrackingConfigID, 
			@LastUser As LastUser, 0 AS IsAttribute
		FROM #temp
		WHERE NodeType=3 AND ParentID NOT IN (Select ID FROM #temp WHERE #temp.NodeType=2)

		INSERT INTO TrackingLocationsHostsConfigValues (Value, LookupID, TrackingConfigID, LastUser, IsAttribute)
		SELECT ISNULL(#temp.Text,'') AS Value, (SELECT Lookups.LookupID FROM #temp t INNER JOIN Lookups ON LookupTypeID=@LookupTypeID AND LOWER(LTRIM(RTRIM([Values])))=LOWER(LTRIM(RTRIM(t.LocalName))) WHERE t.NodeType=1 AND t.id=#temp.id) AS LookupID,
			(SELECT #temp2.ID_NEW 
			FROM #temp2 	
				INNER JOIN #temp t1 ON t1.NodeType=1 AND #temp2.ID=t1.parentid
			WHERE #temp.ID=t1.ID) AS TrackingConfigID, 
			@LastUser As LastUser, 0 AS IsAttribute
		FROM #temp
		WHERE NodeType=1 AND ID NOT IN (Select ParentID FROM #temp t WHERE t.NodeType =3)
			AND ID NOT IN (Select ID FROM #temp2)	

		DELETE FROM #temp2
		DELETE FROM #temp3
		DROP TABLE #temp
		
		UPDATE StationConfigurationUpload SET IsProcessed=1 WHERE ID=@ID
	END

	DROP TABLE #temp2
	DROP TABLE #temp3
END
GO
ALTER PROCEDURE [dbo].remispStationConfigurationUpload @HostID INT, @XML AS NTEXT, @LastUser As NVARCHAR(255), @PluginID INT = 0
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM StationConfigurationUpload WHERE TrackingLocationHostID=@HostID And TrackingLocationPluginID=@PluginID)
		INSERT INTO StationConfigurationUpload (StationConfigXML, TrackingLocationHostID, LastUser, TrackingLocationPluginID) Values (CONVERT(XML, @XML), @HostID, @LastUser, @PluginID)
END
GO
ALTER PROCEDURE [dbo].remispProductConfigurationProcess AS
BEGIN
	CREATE TABLE #temp2 (ID INT, ParentID INT NULL, NodeType INT, LocalName NVARCHAR(100), Text NVARCHAR(2000), ID_temp INT IDENTITY(1,1), ID_NEW INT NULL, ParentID_NEW INT NULL)
	CREATE TABLE #temp3 (LookupID INT, Type INT, LocalName NVARCHAR(150), ID INT IDENTITY(1,1))
	DECLARE @MaxID INT
	DECLARE @MaxLookupID INT
	DECLARE @LookupTypeID INT
	DECLARE @idoc INT
	DECLARE @ID INT
	DECLARE @xml XML
	DECLARE @LastUser NVARCHAR(255)

	IF ((SELECT COUNT(*) FROM ProductConfigurationUpload WHERE ISNULL(IsProcessed,0)=0 AND ProductID IN (SELECT ID FROM Products))=0)
		RETURN
	
	SELECT @LookupTypeID=LookupTypeID FROM LookupType WHERE Name='Configuration'

	WHILE ((SELECT COUNT(*) FROM ProductConfigurationUpload WHERE ISNULL(IsProcessed,0)=0)>0)
	BEGIN
		SELECT TOP 1 @ID=pcu.ID, @xml =pcv.PCXML, @LastUser=pcu.LastUser
		FROM ProductConfigurationUpload pcu
			INNER JOIN ProductConfigurationVersion pcv ON pcu.ID=pcv.UploadID AND pcv.VersionNum=1
		WHERE ISNULL(IsProcessed,0)=0 AND ProductID IN (SELECT ID FROM Products)
		
		exec sp_xml_preparedocument @idoc OUTPUT, @xml
		
		SELECT @MaxID = ISNULL(MAX(ID),0)+1 FROM ProductConfiguration
		SELECT @MaxLookupID = ISNULL(MAX(LookupID),0)+1 FROM Lookups

		SELECT * 
		INTO #temp
		FROM OPENXML(@idoc, '/')

		INSERT INTO #temp2 (ID, ParentID, NodeType, LocalName, Text, ParentID_NEW)
		SELECT ID, ParentID, NodeType, LocalName, '' AS Text, 0 AS ParentID_NEW
		FROM #temp 
		WHERE NodeType=1 AND (SELECT COUNT(ISNULL(ParentID,0)) FROM #temp t WHERE t.ParentID=#temp.ID AND t.ParentID IS NOT NULL)>1
		UNION
		SELECT ID, ParentID, NodeType, LocalName, '' AS Text, 0 AS ParentID_NEW
		FROM #temp 
		WHERE NodeType=1 AND (SELECT COUNT(*) FROM #temp t1 WHERE t1.NodeType=1 AND t1.ParentID=#temp.ID AND t1.ParentID IS NOT NULL GROUP BY t1.ParentID )=1
		UNION
		SELECT ID, ParentID, NodeType, LocalName, '' AS Text, 0 AS ParentID_NEW
		FROM #temp 
		WHERE NodeType=1 AND (SELECT COUNT(ISNULL(ParentID,0)) FROM #temp t WHERE t.NodeType IN (1,2) AND t.ParentID=#temp.ID AND t.ParentID IS NOT NULL AND t.NodeType <> 3)=1
		
		UPDATE #temp2
		SET ID_NEW = ID_temp + @MaxID

		UPDATE #temp2
		SET ParentID_NEW = (SELECT t.ID_NEW FROM #temp2 t WHERE #temp2.ParentID=t.ID)
		WHERE #temp2.ParentID IS NOT NULL

		SET IDENTITY_INSERT ProductConfiguration ON

		INSERT INTO ProductConfiguration (ID, ParentId, ViewOrder, NodeName, LastUser, UploadID)
		SELECT ID_NEW, CASE WHEN ParentID_NEW = 0 THEN NULL ELSE ParentID_NEW END, ROW_NUMBER() OVER (ORDER BY id) AS ViewOrder, LocalName, @LastUser, @ID
		FROM #temp2
		ORDER BY ID, parentid

		SET IDENTITY_INSERT ProductConfiguration OFF
			
		INSERT INTO #temp3
		SELECT DISTINCT 0 AS LookupID, @LookupTypeID AS LookupTypeID, LTRIM(RTRIM(LocalName)) AS LocalName
		FROM #temp 
		WHERE NodeType=2 AND LocalName NOT IN (SELECT Lookups.[Values] FROM Lookups WHERE LookupTypeID=@LookupTypeID)
			
		INSERT INTO #temp3
		SELECT DISTINCT 0 AS LookupID, @LookupTypeID AS LookupTypeID, LTRIM(RTRIM(LocalName)) AS LocalName
		FROM #temp 
		WHERE NodeType=1 AND LocalName NOT IN (SELECT Lookups.[Values] FROM Lookups WHERE LookupTypeID=@LookupTypeID)
			AND ID IN (SELECT ParentID FROM #temp WHERE NodeType=3)
		
		UPDATE #temp3 SET LookupID=ID+@MaxLookupID

		insert into Lookups (LookupID, [Values], LookupTypeID)
		select LookupID, localname as [Values], [Type] AS LookupTypeID from #temp3
			
		INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
		SELECT ISNULL((SELECT t2.Text FROM #temp t2 WHERE t2.NodeType=3 AND t2.ParentID=#temp.ID),'') AS Value, 
			CASE WHEN #temp.NodeType=2 THEN (SELECT LookupID FROM Lookups WHERE LookupTypeID=@LookupTypeID AND [values]=#temp.LocalName) ELSE NULL END As LookupID, 
			(SELECT ID_NEW FROM #temp2 WHERE #temp.ParentID=#temp2.ID) AS ProductConfigID, @LastUser As LastUser, 1 AS IsAttribute
		FROM #temp
		WHERE #temp.NodeType=2 		

		INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
		SELECT ISNULL(#temp.Text,'') AS Value, (SELECT Lookups.LookupID FROM #temp t INNER JOIN Lookups ON LookupTypeID=@LookupTypeID AND LOWER(LTRIM(RTRIM([Values])))=LOWER(LTRIM(RTRIM(t.LocalName))) WHERE t.NodeType=1 AND t.id=#temp.parentid) AS LookupID,
			(SELECT #temp2.ID_NEW 
			FROM #temp2 	
				INNER JOIN #temp t1 ON t1.NodeType=1 AND #temp2.ID=t1.parentid
			WHERE #temp.ParentID=t1.ID) AS ProductConfigID, 
			@LastUser As LastUser, 0 AS IsAttribute
		FROM #temp
		WHERE NodeType=3 AND ParentID NOT IN (Select ID FROM #temp WHERE #temp.NodeType=2)
			
		INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
		SELECT ISNULL(#temp.Text,'') AS Value, (SELECT Lookups.LookupID FROM #temp t INNER JOIN Lookups ON LookupTypeID=@LookupTypeID AND LOWER(LTRIM(RTRIM([Values])))=LOWER(LTRIM(RTRIM(t.LocalName))) WHERE t.NodeType=1 AND t.id=#temp.id) AS LookupID,
			(SELECT #temp2.ID_NEW 
			FROM #temp2 	
				INNER JOIN #temp t1 ON t1.NodeType=1 AND #temp2.ID=t1.parentid
			WHERE #temp.ID=t1.ID) AS ProductConfigID, 
			@LastUser As LastUser, 0 AS IsAttribute
		FROM #temp
		WHERE NodeType=1 AND ID NOT IN (Select ParentID FROM #temp t WHERE t.NodeType =3)
			AND ID NOT IN (Select ID FROM #temp2)	
		
		UPDATE ProductConfigurationUpload SET IsProcessed=1 WHERE ID=@ID
		
		DELETE FROM #temp2
		DELETE FROM #temp3
		DROP TABLE #temp
	END
		
	DROP TABLE #temp2
	DROP TABLE #temp3	
END
GO
CREATE PROCEDURE [dbo].[remispGetUser] @SearchBy INT, @SearchStr NVARCHAR(255)
AS	
	DECLARE @UserID INT

	IF (@SearchBy = 0)
	BEGIN
		SELECT @UserID=ID
		FROM Users u
		WHERE u.BadgeNumber=@SearchStr
	END
	ELSE IF (@SearchBy = 1)
	BEGIN
		SELECT @UserID=ID
		FROM Users u
		WHERE u.LDAPLogin=@SearchStr
	END
	ELSE IF (@SearchBy = 2)
	BEGIN
		SELECT @UserID=ID
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
GO
GRANT EXECUTE ON remispGetUser TO Remi
GO
CREATE PROCEDURE remispGetUserDetails @UserID INT
AS
BEGIN
	SELECT lt.Name, l.[Values], l.LookupID, ISNULL(ud.IsDefault, 0) AS IsDefault
	FROM UserDetails ud
		INNER JOIN Lookups l ON l.LookupID=ud.LookupID
		INNER JOIN LookupType lt ON lt.LookupTypeID=l.LookupTypeID
	WHERE ud.UserID=@UserID
	ORDER BY lt.Name, l.[Values]
END
GO
GRANT EXECUTE ON remispGetUserDetails TO REMI
GO


ROLLBACK TRAN