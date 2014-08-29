/*
Run this script on:

        sqlqa10ykf\haqa1.RemiQA    -  This database will be modified

to synchronize it with:

        CI0000001593275\SQLDEVELOPER.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.3.8 from Red Gate Software Ltd at 5/27/2013 5:59:53 PM

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
update [dbo].[aspnet_Roles] set hasProductCheck=1 where RoleName='ProjectManager'
GO
insert into UsersProducts(ProductID, UserID, LastUser)
select ProductID, UserID, LastUser
from _ProductManagers
GO
insert into TargetAccess values ('DataLoggerRelabOracleAccess',0)
GO
insert into TargetAccess values ('DataLoggerRelabRemiAccess',0)
GO
insert into aspnet_Roles (applicationid,RoleId,RoleName, LoweredRoleName, Description, hasProductCheck)
values ('892170D7-F95A-4AE1-A7E7-C1994D392790', 'EED4B3C7-10E0-4FE2-877B-CF77A71640EB','Relab','relab',null,null)
GO
Update Users Set ByPassProduct=1 where IsActive=1
GO
insert into aspnet_Permissions values ('11B32710-F71B-4937-9BC8-080A71887647','HasFAAssignmentAuthority','892170D7-F95A-4AE1-A7E7-C1994D392790')
insert into aspnet_Permissions values ('61D441B4-AB50-4269-814C-21C51FAD136B','HasTaskAssignmentAuthority','892170D7-F95A-4AE1-A7E7-C1994D392790')
insert into aspnet_Permissions values ('F3395C34-080E-43D9-BA29-22AC8786FDAA','HasFAHighTestingAuthority','892170D7-F95A-4AE1-A7E7-C1994D392790')
insert into aspnet_Permissions values ('9FED6710-53F6-48FB-986A-32E687E5266C','HasLastScanLocationOverride','892170D7-F95A-4AE1-A7E7-C1994D392790')
insert into aspnet_Permissions values ('3F2C7B9E-86CB-436A-A7E0-65FDF819FDDF','HasUploadConfigXML','892170D7-F95A-4AE1-A7E7-C1994D392790')
insert into aspnet_Permissions values ('2AE0D009-48C7-4DA8-812B-8F7FC4E322F4','HasFALowTestingAuthority','892170D7-F95A-4AE1-A7E7-C1994D392790')
insert into aspnet_Permissions values ('898CA6B5-28DE-4134-B95D-99CBAD4369F3','HasEditBatchCommentsAuthority','892170D7-F95A-4AE1-A7E7-C1994D392790')
insert into aspnet_Permissions values ('EB22F983-92BC-4A2D-A81E-BAA65AE99E5A','HasAdjustPriorityAuthority','892170D7-F95A-4AE1-A7E7-C1994D392790')
insert into aspnet_Permissions values ('85D18E28-348C-4E84-8166-C5B9EDC57134','HasRetestAuthority','892170D7-F95A-4AE1-A7E7-C1994D392790')
insert into aspnet_Permissions values ('6C10FE04-8C39-4318-AFCD-C8B1E16D2F7A','HasEditItemAuthority','892170D7-F95A-4AE1-A7E7-C1994D392790')
insert into aspnet_Permissions values ('88AFFD56-6C5F-4A20-A81A-D1568357802A','HasOverrideCompletedTestAuthority','892170D7-F95A-4AE1-A7E7-C1994D392790')
insert into aspnet_Permissions values ('58EA4BB2-2F5B-4564-8372-E8C9DEA13C7E','HasRelabAuthority','892170D7-F95A-4AE1-A7E7-C1994D392790')
insert into aspnet_Permissions values ('219DB97E-C97A-4036-B4D2-E922FF68F697','HasScanForTestAuthority','892170D7-F95A-4AE1-A7E7-C1994D392790')
insert into aspnet_Permissions values ('737bbcce-c65a-4524-9615-17fec17e0f53','HasDocumentAuthority','892170D7-F95A-4AE1-A7E7-C1994D392790')
GO
DECLARE @maxid int
SELECT @maxid = MAX(lookupID)+1 FROM lookups
insert into Lookups values (@maxid,'Level','Expert',1)
GO
PRINT N'Creating [Relab].[remispResultsFileProcessing]'
GO
CREATE PROCEDURE Relab.remispResultsFileProcessing
AS
BEGIN
	DECLARE @ID INT
	DECLARE @idoc INT
	DECLARE @RowID INT
	DECLARE @xml XML
	DECLARE @xmlPart XML
	DECLARE @FinalResult BIT
	DECLARE @EndDate NVARCHAR(MAX)

	SELECT TOP 1 @ID=ID, @xml = ResultsXML
	FROM Relab.Results
	WHERE ISNULL(IsProcessed,0)=0

	SELECT @xmlPart = T.c.query('.') 
	FROM @xml.nodes('/TestResults/Header') T(c)

	exec sp_xml_preparedocument @idoc OUTPUT, @xmlPart

	SELECT * 
	INTO #temp
	FROM OPENXML(@idoc, '/')

	--Insert Header values
	INSERT INTO Relab.ResultsHeader (ResultID, Name, Value)
	SELECT @ID As ResultID, LocalName AS Name,(SELECT t2.text FROM #temp t2 WHERE t2.ParentID=t.ID) AS Value
	FROM #temp t
	WHERE t.NodeType=1 AND t.ParentID IS NOT NULL AND t.LocalName NOT IN ('FinalResult','DateCompleted')
		AND LTRIM(RTRIM(CONVERT(NVARCHAR(1500), (SELECT t2.text FROM #temp t2 WHERE t2.ParentID=t.ID)))) <> ''

	select @FinalResult = (CASE WHEN T.c.query('FinalResult').value('.', 'nvarchar(max)') = 'Pass' THEN 1 ELSE 0 END),
		@EndDate = T.c.query('DateCompleted').value('.', 'nvarchar(max)')
	FROM @xmlPart.nodes('/Header') T(c)

	SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ' ')
	SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ':')
	SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ':')

	SELECT  ROW_NUMBER() OVER (ORDER BY T.c) AS RowID, T.c.query('.') AS value 
	INTO #temp2
	FROM   @xml.nodes('/TestResults/Measurements/Measurement') T(c)

	SELECT @RowID = MIN(RowID) FROM #temp2

	WHILE (@RowID IS NOT NULL)
	BEGIN
		SELECT @xmlPart  = value FROM #temp2 WHERE RowID=@RowID	

		select T.c.query('MeasurementName').value('.', 'nvarchar(max)') AS MeasurementType,
			T.c.query('LowerLimit').value('.', 'nvarchar(max)') AS LowerLimit,
			T.c.query('UpperLimit').value('.', 'nvarchar(max)') AS UpperLimit,
			T.c.query('MeasuredValue').value('.', 'nvarchar(max)') AS MeasurementValue,
			(CASE WHEN T.c.query('PassFail').value('.', 'nvarchar(max)') = 'Pass' THEN 1 ELSE 0 END) AS PassFail,
			T.c.query('Units').value('.', 'nvarchar(max)') AS UnitType,
			T.c.query('FileName').value('.', 'nvarchar(max)') AS [FileName]
		INTO #measurement
		FROM @xmlPart.nodes('/Measurement') T(c)
		
		INSERT INTO Lookups (LookupID, Type,[Values], IsActive)
		SELECT DISTINCT (SELECT MAX(LookupID)+1 FROM Lookups) AS LookupID, 'UnitType' AS Type, LTRIM(RTRIM(UnitType)) AS [values], 1
		FROM #measurement 
		WHERE LTRIM(RTRIM(UnitType)) NOT IN (SELECT [Values] FROM Lookups WHERE Type='UnitType') AND UnitType IS NOT NULL AND UnitType NOT IN ('N/A')
		
		INSERT INTO Lookups (LookupID, Type,[Values], IsActive)
		SELECT DISTINCT (SELECT MAX(LookupID)+1 FROM Lookups) AS LookupID, 'MeasurementType' AS Type, LTRIM(RTRIM(MeasurementType)) AS [values], 1
		FROM #measurement 
		WHERE LTRIM(RTRIM(MeasurementType)) NOT IN (SELECT [Values] FROM Lookups WHERE Type='MeasurementType') AND MeasurementType IS NOT NULL AND MeasurementType NOT IN ('N/A')
		
		INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, [File], PassFail)
		SELECT @ID As ResultID, l2.LookupID AS MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, l.[LookupID] AS MeasurementUnitTypeID, FileName AS [File], CONVERT(BIT, PassFail)
		FROM #measurement
			LEFT OUTER JOIN Lookups l ON l.Type='UnitType' AND l.[Values]=LTRIM(RTRIM(#measurement.UnitType))
			LEFT OUTER JOIN Lookups l2 ON l2.Type='MeasurementType' AND l2.[Values]=LTRIM(RTRIM(#measurement.MeasurementType))
		
		DECLARE @ResultMeasurementID INT
		SELECT @ResultMeasurementID = MAX(ID)
		FROM Relab.ResultsMeasurements
		WHERE ResultID=@ID 
			
		INSERT INTO Relab.ResultsParameters (ResultMeasurementID, ParameterName, Value)
		SELECT @ResultMeasurementID AS ResultMeasurementID, T.c.value('@ParameterName','nvarchar(max)') AS ParameterName, T.c.query('.').value('.', 'nvarchar(max)') AS Value
		FROM @xmlPart.nodes('/Measurement/Parameters/Parameter') T(c)
		
		DROP TABLE #measurement
		
		SELECT @RowID = MIN(RowID) FROM #temp2 WHERE RowID > @RowID
	END

	UPDATE Relab.Results SET PassFail=@FinalResult, EndDate=CONVERT(DATETIME, @EndDate), IsProcessed=1 WHERE ID=@ID

	DROP TABLE #temp
	DROP TABLE #temp2
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Relab].[remispResultsSummary]'
GO
CREATE PROCEDURE [Relab].[remispResultsSummary] @BatchID INT
AS
BEGIN
	SELECT r.ID, r.VerNum, ts.TestStageName, t.TestName, tu.BatchUnitNumber, CASE WHEN PassFail=1 THEN 'Pass' ELSE 'Fail' END AS PassFail, 
		CONVERT(varchar, EndDate, 106) AS EndDate, r.ResultsXML
	FROM Relab.Results r
		INNER JOIN TestStages ts ON r.TestStageID=ts.ID
		INNER JOIN Tests t ON r.TestID=t.ID
		INNER JOIN TestUnits tu ON tu.ID=r.TestUnitID
	WHERE tu.BatchID=@BatchID
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Relab].[ResultsParametersComma]'
GO
/*
select * from Relab.Results
select * from Relab.ResultsHeader
select * from Relab.ResultsMeasurements
select * from Relab.ResultsParameters
*/

CREATE FUNCTION Relab.ResultsParametersComma(@ResultMeasurementID INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @listStr NVARCHAR(MAX)
	SELECT @listStr = COALESCE(@listStr+', ' ,'') + ParameterName + ': ' + Value
	FROM Relab.ResultsParameters
	WHERE Relab.ResultsParameters.ResultMeasurementID=@ResultMeasurementID
	
	Return @listStr
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Relab].[remispResultsSummaryExport]'
GO
CREATE PROCEDURE [Relab].[remispResultsSummaryExport] @BatchID INT, @ResultID INT = NULL
AS
BEGIN
	SELECT b.QRANumber, tu.BatchUnitNumber As Unit, tu.BSN, ts.TestStageName AS TestStage, t.TestName, r.VerNum As Version,
		lm.[Values] AS MeasurementType, m.LowerLimit, m.UpperLimit, m.MeasurementValue AS Result, lu.[Values] AS Units,
		CASE WHEN m.PassFail=1 THEN 'Pass' ELSE 'Fail' END AS PassFail, Relab.ResultsParametersComma(m.ID) AS Parameters
	FROM Relab.Results r
		INNER JOIN TestStages ts ON r.TestStageID=ts.ID
		INNER JOIN Tests t ON r.TestID=t.ID
		INNER JOIN TestUnits tu ON tu.ID=r.TestUnitID
		INNER JOIN Batches b ON b.ID=tu.BatchID
		INNER JOIN Relab.ResultsMeasurements m ON m.ResultID=r.ID
		INNER JOIN Lookups lm ON m.MeasurementTypeID=lm.LookupID
		INNER JOIN Lookups lu ON m.MeasurementUnitTypeID=lu.LookupID
	WHERE b.ID=@BatchID AND (@ResultID IS NULL OR (@ResultID IS NOT NULL AND r.ID=@ResultID))
	ORDER BY tu.BatchUnitNumber, Version, ts.TestStageName, TestName
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispYourBatchesGetActiveBatches]'
GO
CREATE PROCEDURE [dbo].[remispYourBatchesGetActiveBatches] @UserID int, @ByPassProductCheck INT = 0
AS	
	SELECT BatchesRows.row,BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,BatchesRows.RequestPurpose,batchesrows.ProductType, batchesrows.AccessoryGroupName,
		batchesrows.ProductID,BatchesRows.TestCenterLocationID,
		BatchesRows.TestCenterLocation,BatchesRows.TestStageName,BatchesRows.RFBands, BatchesRows.TestStageCompletionStatus, 
		batchesrows.testUnitCount,BatchesRows.RQID As ReqID,
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,
		(
			testunitcount -
			(select COUNT(*) 
			from TestUnits as tu
				INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
		) as HasUnitsToReturnToRequestor,
		(
			select AssignedTo 
			from TaskAssignments as ta
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
			where ta.BatchID = BatchesRows.ID and ta.Active=1
		) as ActiveTaskAssignee,
		CONVERT(BIT, 0) AS HasBatchSpecificExceptions, batchesrows.ProductTypeID, batchesrows.AccessoryGroupID
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
			b.BatchStatus,b.Comment,(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
			b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority,p.ProductGroupName,b.ProductTypeID,b.AccessoryGroupID,p.ID as ProductID,b.QRANumber,
			b.RequestPurpose,b.TestCenterLocationID,b.TestStageName, j.WILocation,
			(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
			l2.[Values] As AccessoryGroupName, l.[Values] As ProductType,b.RQID,l3.[Values] As TestCenterLocation
			FROM Batches as b
				inner join Products p on p.ID=b.ProductID
				LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs
				LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  
			WHERE BatchStatus NOT IN(5,7) AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
		) AS BatchesRows
	ORDER BY BatchesRows.QRANumber
	RETURN
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Relab].[remispResultsHeaders]'
GO
/*
select * from Relab.Results
select * from Relab.ResultsHeader
select * from Relab.ResultsMeasurements
select * from Relab.ResultsParameters
*/


CREATE PROCEDURE [Relab].[remispResultsHeaders] @ResultID INT
AS
BEGIN
	SELECT Name, Value
	FROM Relab.ResultsHeader
	WHERE ResultID=@ResultID
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Relab].[remispResultMeasurements]'
GO
CREATE PROCEDURE [Relab].[remispResultMeasurements] @ResultID INT, @OnlyFails INT = 0
AS
BEGIN
	SELECT rm.ID, lt.[Values] As MeasurementType, LowerLimit, UpperLimit, MeasurementValue, lu.[Values] As UnitType, 
		CASE WHEN PassFail=1 THEN 'Pass' ELSE 'Fail' END AS PassFail,
		Relab.ResultsParametersComma(rm.ID) AS [Parameters]
	FROM Relab.ResultsMeasurements rm
		INNER JOIN Lookups lu ON lu.Type='UnitType' AND lu.LookupID=rm.MeasurementUnitTypeID
		INNER JOIN Lookups lt ON lt.Type='MeasurementType' AND lt.LookupID=rm.MeasurementTypeID
	WHERE ResultID=@ResultID AND ((@OnlyFails = 1 AND PassFail=0) OR (@OnlyFails = 0))
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispUsersSelectSingleItemByBadgeNumber]'
GO
ALTER PROCEDURE [dbo].[remispUsersSelectSingleItemByBadgeNumber] @BadgeNumber int
AS
	SELECT u.BadgeNumber,u.ConcurrencyID,u.ID,u.LastUser,u.LDAPLogin, u.TestCentreID, ISNULL(u.IsActive,1) As IsActive, u.DefaultPage, Lookups.[values] As TestCentre,
		u.ByPassProduct
	FROM Users as u
		LEFT OUTER JOIN Lookups ON Type='TestCenter' AND LookupID=TestCentreID
	WHERE BadgeNumber = @BadgeNumber
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[aspnet_GetPermissionsByRole]'
GO
CREATE PROCEDURE [dbo].[aspnet_GetPermissionsByRole] @ApplicationName nvarchar(256), @RoleName nvarchar(256)
AS
BEGIN
	DECLARE @ApplicationId uniqueidentifier
	SELECT  @ApplicationId = NULL
	SELECT  @ApplicationId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
	
	IF (@ApplicationId IS NULL)
		RETURN

	DECLARE @RoleId uniqueidentifier

	SELECT @RoleId = RoleId
	FROM dbo.aspnet_Roles
	WHERE LOWER(@RoleName) = LoweredRoleName AND ApplicationId = @ApplicationId

	IF (@RoleId IS NULL)
		RETURN

	SELECT Permission
	FROM aspnet_Permissions p
		INNER JOIN aspnet_PermissionsInRoles pr ON pr.PermissionID=p.PermissionID
	WHERE pr.RoleId = @RoleId
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[aspnet_GetRolesByPermission]'
GO
CREATE PROCEDURE [dbo].[aspnet_GetRolesByPermission] @ApplicationName nvarchar(256), @PermissionName nvarchar(256)
AS
BEGIN
	DECLARE @ApplicationId uniqueidentifier
	SELECT  @ApplicationId = NULL
	SELECT  @ApplicationId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
	
	IF (@ApplicationId IS NULL)
		RETURN

	DECLARE @PermissionID uniqueidentifier

	SELECT @PermissionID = PermissionID
	FROM dbo.aspnet_Permissions
	WHERE Permission=@PermissionName AND ApplicationId = @ApplicationId

	IF (@PermissionID IS NULL)
		RETURN

	SELECT r.RoleName, ISNULL(r.hasProductCheck,0) AS hasProductCheck
	FROM aspnet_Permissions p
		INNER JOIN aspnet_PermissionsInRoles pr ON pr.PermissionID=p.PermissionID
		INNER JOIN aspnet_Roles r ON pr.RoleID=r.RoleId
	WHERE pr.PermissionID=@PermissionID
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispUsersSelectSingleItemByUserName]'
GO
ALTER PROCEDURE [dbo].[remispUsersSelectSingleItemByUserName] @LDAPLogin nvarchar(255) = '', @UserID INT = 0
AS
	SELECT Users.BadgeNumber,Users.ConcurrencyID,Users.ID,Users.LastUser,Users.LDAPLogin, Users.TestCentreID, ISNULL(Users.IsActive, 1) AS IsActive, 
		Users.DefaultPage, Lookups.[Values] As TestCentre, Users.ByPassProduct
	FROM Users
		LEFT OUTER JOIN Lookups ON Type='TestCenter' AND LookupID=TestCentreID
	WHERE (@UserID = 0 AND LDAPLogin = @LDAPLogin) OR (@UserID > 0 AND Users.ID=@UserID)
GO
GRANT EXECUTE ON remispUsersSelectSingleItemByUserName TO Remi
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remifnUserCanDelete]'
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
		FROM UsersProducts
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM ProductConfigurationUpload
		WHERE LTRIM(RTRIM(LastUser))=@UserName)
	
	RETURN ISNULL(@Exists, 1)
END
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
	@determineDelete INT = 1,
	@RecordCount int = NULL OUTPUT
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Users)
		RETURN
	END

	SELECT UsersRows.BadgeNumber,UsersRows.ConcurrencyID,UsersRows.ID,usersrows.TestCentre, UsersRows.LastUser,UsersRows.LDAPLogin,UsersRows.Row, UsersRows.IsActive, 
		CASE WHEN @determineDelete = 1 THEN dbo.remifnUserCanDelete(UsersRows.LDAPLogin) ELSE 0 END AS CanDelete, UsersRows.DefaultPage, UsersRows.TestCentreID,
		ByPassProduct
	FROM     
		(SELECT ROW_NUMBER() OVER (ORDER BY ID) AS Row, Users.BadgeNumber,Users.ConcurrencyID,Users.ID,Users.LastUser,Users.LDAPLogin, 
			Lookups.[Values] AS TestCentre, ISNULL(Users.IsActive,1) AS IsActive, Users.DefaultPage, Users.TestCentreID, Users.ByPassProduct
		FROM Users
			LEFT OUTER JOIN Lookups ON Type='TestCenter' AND LookupID=TestCentreID
		) AS UsersRows
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
	@TestCentreID INT = null,
	@LastUser nvarchar(255),
	@ConcurrencyID rowversion OUTPUT,
	@IsActive INT = 1,
	@ByPassProduct INT = 0,
	@DefaultPage NVARCHAR(255)
AS
	DECLARE @ReturnValue int

	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO Users (LDAPLogin, BadgeNumber, TestCentreID, LastUser, IsActive, DefaultPage, ByPassProduct)
		VALUES
		(
			@LDAPLogin,
			@BadgeNumber,
			@TestCentreID,
			@LastUser,
			@IsActive,
			@DefaultPage,
			@ByPassProduct
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
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
	update UsersProducts 
	set LastUser = (SELECT LDAPLogin FROM Users WHERE ID=@UserID) 
	FROM UsersProducts
	where UserID = @userIDToDelete

	delete from UsersProducts where UserID = @userIDToDelete

	update	Users set LastUser = (SELECT LDAPLogin FROM Users WHERE ID=@UserID)  where ID = @userIDToDelete
	delete from users where ID = @userIDToDelete
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispUsersSelectListByTestCentre]'
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

	SELECT Users.BadgeNumber, Users.ConcurrencyID, Users.ID, Users.LastUser, Users.LDAPLogin, 
		Lookups.[Values] AS TestCentre, ISNULL(Users.IsActive,1) AS IsActive, Users.DefaultPage, Users.TestCentreID, Users.ByPassProduct, 
		CASE WHEN @determineDelete = 1 THEN dbo.remifnUserCanDelete(Users.LDAPLogin) ELSE 0 END AS CanDelete
	FROM Users
		LEFT OUTER JOIN Lookups ON Type='TestCenter' AND LookupID=TestCentreID
	WHERE (TestCentreID=@TestLocation OR @TestLocation = 0)
		AND 
		(
			(@IncludeInActive = 0 AND ISNULL(Users.IsActive, 1)=1)
			OR
			@IncludeInActive = 1
		)
	ORDER BY IsActive DESC, LDAPLogin
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
	update UsersProducts 
	set lastuser = (SELECT LDAPLogin FROM Users WHERE ID=@UserID)
	FROM UsersProducts
		INNER JOIN Products p ON UsersProducts.ProductID=p.ID
	WHERE p.ID = @ProductID and UserID = @UserIDToRemove

	delete UsersProducts
	from UsersProducts
		INNER JOIN Products p ON UsersProducts.ProductID=p.ID
	WHERE p.ID = @ProductID and UserID = @UserIDToRemove
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispProductManagersAssignUser]'
GO
ALTER PROCEDURE [dbo].[remispProductManagersAssignUser]
/*	'===============================================================
	'   NAME:                	remispProductManagersAssignUser
	'   DATE CREATED:       	11 Sept 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates or updates an item in a table: product managers
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@ProductID INT,
	@Username nvarchar(255),
	@LastUser nvarchar(255)	
AS
	DECLARE @ReturnValue int
	Declare @ID int
	Declare @UserID INT
	SELECT @UserID = ID FROM Users WHERE LDAPLogin=@Username

	SET @ID = (Select ID from UsersProducts where productID = @ProductID and UserID = @UserID)

	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO UsersProducts (ProductID, UserID, Lastuser)
		VALUES (@ProductID, @UserID, @LastUser)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	
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
PRINT N'Altering [dbo].[remispProductManagersSelectList]'
GO
ALTER PROCEDURE [dbo].[remispProductManagersSelectList] @UserID INT
AS
	SELECT p.ProductGroupName, p.ID  
	FROM UsersProducts AS uxpg
		INNER JOIN Products p ON p.ID=uxpg.ProductID
	WHERE uxpg.UserID = @UserID
	ORDER BY p.ProductGroupName
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Relab].[remispResultsFileUpload]'
GO
CREATE PROCEDURE Relab.remispResultsFileUpload @XML AS NTEXT
AS
BEGIN
DECLARE @TestStageID INT
DECLARE @TestID INT
DECLARE @TestUnitID INT
DECLARE @VerNum INT
DECLARE @ResultsXML XML

DECLARE @TestName NVARCHAR(400)
DECLARE @TestStageName NVARCHAR(400)
DECLARE @QRANumber NVARCHAR(11)
DECLARE @JobName NVARCHAR(400)
DECLARE @TestUnitNumber INT

SELECT @ResultsXML = CONVERT(XML, @XML)

SELECT @TestName = T.c.query('TestName').value('.', 'nvarchar(max)'),
	@QRANumber = T.c.query('JobNumber').value('.', 'nvarchar(max)'),
	@TestUnitNumber = T.c.query('UnitNumber').value('.', 'int'),
	@TestStageName = T.c.query('TestStage').value('.', 'nvarchar(max)'),
	@JobName = T.c.query('TestType').value('.', 'nvarchar(max)')
FROM @ResultsXML.nodes('/TestResults/Header') T(c)

SELECT @TestUnitID = tu.ID
FROM TestUnits tu
	INNER JOIN Batches b ON tu.BatchID=b.ID
WHERE QRANumber=@QRANumber AND tu.BatchUnitNumber=@TestUnitNumber

SELECT @TestStageID = ts.ID 
FROM Jobs j
	INNER JOIN TestStages ts ON j.ID=ts.JobID
WHERE j.JobName=@JobName AND ts.TestStageName=@TestStageName

SELECT @TestID = t.ID
FROM Tests t
WHERE t.TestName=@TestName

SELECT @VerNum = ISNULL(COUNT(*), 0)+1 FROM Relab.Results WHERE TestStageID=@TestStageID AND TestID=@TestID AND TestUnitID=@TestUnitID

INSERT INTO Relab.Results (TestStageID, TestID,TestUnitID, VerNum, ResultsXML)
VALUES (@TestStageID, @TestID, @TestUnitID, @VerNum, @XML)

END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [Relab].[ResultsParametersComma]'
GO
GRANT EXECUTE ON  [Relab].[ResultsParametersComma] TO [remi]
GO
PRINT N'Altering permissions on [Relab].[remispResultsFileProcessing]'
GO
GRANT EXECUTE ON  [Relab].[remispResultsFileProcessing] TO [remi]
GO
PRINT N'Altering permissions on [Relab].[remispResultsSummary]'
GO
GRANT EXECUTE ON  [Relab].[remispResultsSummary] TO [remi]
GO
PRINT N'Altering permissions on [Relab].[remispResultsSummaryExport]'
GO
GRANT EXECUTE ON  [Relab].[remispResultsSummaryExport] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispYourBatchesGetActiveBatches]'
GO
GRANT EXECUTE ON  [dbo].[remispYourBatchesGetActiveBatches] TO [remi]
GO
PRINT N'Altering permissions on [Relab].[remispResultsHeaders]'
GO
GRANT EXECUTE ON  [Relab].[remispResultsHeaders] TO [remi]
GO
PRINT N'Altering permissions on [Relab].[remispResultMeasurements]'
GO
GRANT EXECUTE ON  [Relab].[remispResultMeasurements] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[aspnet_GetPermissionsByRole]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_GetPermissionsByRole] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[aspnet_GetRolesByPermission]'
GO
GRANT EXECUTE ON  [dbo].[aspnet_GetRolesByPermission] TO [remi]
GO
PRINT N'Altering permissions on [Relab].[remispResultsFileUpload]'
GO
GRANT EXECUTE ON  [Relab].[remispResultsFileUpload] TO [remi]
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
ALTER PROCEDURE remispBatchDNPParametric @QRANumber NVARCHAR(11), @LDAPLogin NVARCHAR(255), @UnitNumber INT
AS
	DECLARE @UnitID INT
	DECLARE @TestID INT
	DECLARE @ID INT

	IF (@UnitNumber = 0)
	BEGIN
		SET @UnitNumber = NULL
	END

	SELECT ID
	INTO #tests
	FROM Tests
	WHERE TestType=1 AND TestName NOT IN ('Functional Test', 'SFI Functional', 'Visual Inspection')
	ORDER BY ID

	SELECT tu.ID
	INTO #units
	FROM TestUnits tu
		INNER JOIN Batches b ON tu.BatchID=b.ID
	WHERE b.QRANumber=@QRANumber AND ((@UnitNumber IS NULL) OR (@UnitNumber IS NOT NULL AND tu.BatchUnitNumber=@UnitNumber))
	ORDER BY tu.ID

	SELECT @TestID = MIN(ID) FROM #tests

	WHILE (@TestID IS NOT NULL)
	BEGIN
		SELECT @UnitID = MIN(ID) FROM #units
		PRINT @TestID
		
		WHILE (@UnitID IS NOT NULL)
		BEGIN
			SELECT @ID = MAX(ID)+1 FROM TestExceptions
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 3, @UnitID, @LDAPLogin)--TestUnit
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @TestID, @LDAPLogin)--Test
			
			SELECT @UnitID = MIN(ID) FROM #units WHERE ID > @UnitID
		END

		SELECT @TestID = MIN(ID) FROM #tests WHERE ID>@TestID
	END

	DELETE FROM TestExceptions WHERE ID IN (SELECT MIN(ID)
	FROM vw_ExceptionsPivoted
	WHERE TestUnitID IN (SELECT ID FROM #units)
		AND TestStageID IS NULL
		AND Test IN (SELECT ID FROM #tests)
	GROUP BY Test, TestUnitID
	HAVING COUNT(*)>1)

	DROP TABLE #tests
	DROP TABLE #units
GO
GRANT EXECUTE ON remispBatchDNPParametric TO Remi
GO
ALTER PROCEDURE [Relab].[remispOverallResultsSummary] @BatchID INT
AS
BEGIN
	SELECT DISTINCT j.JobName, ts.TestStageName, t.TestName, tu.BatchUnitNumber, Relab.DetermineOverallPassFail(r.TestStageID, r.TestID, r.TestUnitID) AS PassFail
	FROM Relab.Results r
		INNER JOIN TestStages ts ON r.TestStageID=ts.ID
		INNER JOIN Tests t ON r.TestID=t.ID
		INNER JOIN TestUnits tu ON tu.ID=r.TestUnitID
		INNER JOIN Jobs j ON j.ID=ts.JobID
	WHERE tu.BatchID=@BatchID
END
GO
GRANT EXECUTE ON [Relab].[remispOverallResultsSummary] TO Remi
GO
ALTER FUNCTION Relab.DetermineOverallPassFail(@TestStageID INT, @TestID INT, @TestUnitID INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @PassCount INT
	DECLARE @FailCount INT
	DECLARE @PassFail NVARCHAR(5)
	SET @PassCount = 0
	SET @FailCount = 0
	
	SELECT @PassCount = COUNT(*)
	FROM Relab.Results
	WHERE TestStageID=@TestStageID AND TestID=@TestID AND TestUnitID=@TestUnitID AND PassFail=1
	
	SELECT @FailCount = COUNT(*)
	FROM Relab.Results
	WHERE TestStageID=@TestStageID AND TestID=@TestID AND TestUnitID=@TestUnitID AND PassFail=0
	
	If (@FailCount = 0)
	BEGIN
		SET @PassFail = 'True'
	END
	ELSE
	BEGIN
		SET @PassFail = 'False'
	END
	
	RETURN @PassFail
END
GO
GRANT EXECUTE ON Relab.DetermineOverallPassFail TO Remi
GO
ALTER procedure [dbo].[remispUsersSearch] @ProductID INT = 0, @TestCenterID INT = 0, @TrainingID INT = 0, @TrainingLevelID INT = 0, @ByPass INT = 0
AS
BEGIN
	SELECT DISTINCT u.ID, u.LDAPLogin
	FROM Users u
		LEFT OUTER JOIN UserTraining ut ON ut.UserID = u.ID
		LEFT OUTER JOIN UsersProducts up ON up.UserID = u.ID
	WHERE u.IsActive=1 AND (
			(u.TestCentreID=@TestCenterID) 
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
END
GO
GRANT EXECUTE ON remispUsersSearch TO REMI
GO
create PROCEDURE [dbo].remispGetBatchDocuments @QRANumber nvarchar(11)
AS
BEGIN
	DECLARE @JobName NVARCHAR(400)
	SELECT @JobName = JobName FROM Batches WHERE QRANumber=@QRANumber

	SELECT (j.JobName + ' WI') AS WIType, j.WILocation AS Location
	FROM Jobs j
	WHERE j.JobName=@JobName AND LTRIM(RTRIM(ISNULL(j.WILocation, ''))) <> ''
	UNION
	SELECT DISTINCT tname AS WIType, TestWI AS Location
	FROM [dbo].[vw_GetTaskInfo]
	WHERE QRANumber=@QRANumber and processorder > 0 AND testtype IN (1,2) AND LTRIM(RTRIM(ISNULL(TestWI,''))) <> ''
	UNION
	SELECT (j.JobName + ' Procedure') AS WIType, j.ProcedureLocation AS Location
	FROM Jobs j
	WHERE j.JobName=@JobName AND LTRIM(RTRIM(ISNULL(j.ProcedureLocation, ''))) <> ''
	UNION
	SELECT 'Specification' AS WIType, 'https://hwqaweb.rim.net/pls/trs/data_entry.main?req=QRA-ENG-SP-11-0001' AS Location
END
GO
GRANT EXECUTE ON remispGetBatchDocuments TO REMI
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
	   TestStageID, TestWI
FROM   
	(
		SELECT b.qranumber,b.ID AS BatchID,
		ts.processorder, ts.teststagename AS tsname, t.testname AS tname, t.testtype, ts.teststagetype, t.duration AS genericTestDuration, ts.ID AS TestStageID,
		t.WILocation As TestWI,
			t.resultbasedontime, 
			(
				SELECT bstd.duration 
				FROM   batchspecifictestdurations AS bstd 
				WHERE  bstd.testid = t.id 
					   AND bstd.batchid = b.id
			) AS specificTestDuration,
			(				
				SELECT Cast(tu.batchunitnumber AS VARCHAR(MAX)) + ', ' 
				FROM testunits AS tu 
				WHERE tu.batchid = b.id 
					AND 
					(
						NOT EXISTS 
						(
							SELECT DISTINCT 1
							FROM vw_ExceptionsPivoted as pvt
							where pvt.ID IN (SELECT ID FROM TestExceptions WHERE LookupID=3 AND Value = tu.ID) AND
							(
								(pvt.TestStageID IS NULL AND pvt.Test = t.ID ) 
								OR 
								(pvt.Test IS NULL AND pvt.TestStageID = ts.id) 
								OR 
								(pvt.TestStageID = ts.id AND pvt.Test = t.ID)
							)
						)
					)
				FOR xml path ('')
			) AS TestUnitsForTest 
		FROM TestStages ts
		INNER JOIN Jobs j ON ts.JobID=j.ID
		INNER JOIN Batches b on j.jobname = b.jobname 
		INNER JOIN Tests t ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
		INNER JOIN Products p ON b.ProductID=p.ID
		WHERE --b.qranumber = @qranumber AND 
			NOT EXISTS 
			(
				SELECT DISTINCT 1
				FROM vw_ExceptionsPivoted as pvt
				WHERE pvt.testunitid IS NULL AND pvt.Test = t.ID
					AND ( pvt.teststageid IS NULL OR ts.id = pvt.teststageid ) 
					AND ( 
							(pvt.ProductID = p.ID AND pvt.reasonforrequest IS NULL)
							OR 
							(pvt.ProductID = p.ID AND pvt.reasonforrequest = b.requestpurpose ) 
							OR
							(pvt.ProductID IS NULL AND b.requestpurpose IS NOT NULL AND pvt.reasonforrequest = b.requestpurpose)
							OR
							(pvt.ProductID IS NULL AND pvt.reasonforrequest IS NULL)
						) 
					AND
						(
							(pvt.AccessoryGroupID IS NULL)
							OR
							(pvt.AccessoryGroupID IS NOT NULL AND pvt.AccessoryGroupID = b.AccessoryGroupID)
						)
					AND
						(
							(pvt.ProductTypeID IS NULL)
							OR
							(pvt.ProductTypeID IS NOT NULL AND pvt.ProductTypeID = b.ProductTypeID)
						)
			)
	) AS unitData 
WHERE TestUnitsForTest IS NOT NULL 
--ORDER  BY ProcessOrder
GO
ALTER PROCEDURE [dbo].[remispJobsSelectSingleItem] @ID int = null, @JobName nvarchar(300) = null
AS
BEGIN
	SELECT ID, JobName, WILocation, Comment, LastUser, ConcurrencyID, OperationsTest, TechnicalOperationsTest, MechanicalTest, ProcedureLocation
	FROM Jobs
	WHERE ((@ID > 0 and @JobName is null) and ID = @ID) 
		OR ((@ID is null and @JobName is not null) and JobName = @JobName)
END
GO
GRANT EXECUTE ON remispJobsSelectSingleItem TO REMI
GO
ALTER PROCEDURE [dbo].[remispJobsInsertUpdateSingleItem]
/*	'===============================================================
	'   NAME:                	remispJobsInsertUpdateSingleItem
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates or updates an item in a table: Jobs
    '   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@ID int OUTPUT,
	@JobName nvarchar(400),
	@WILocation nvarchar(400)=null,
	@Comment nvarchar(1000)=null,
	@LastUser nvarchar(255),
	@ConcurrencyID rowversion OUTPUT,
	@OperationsTest bit = 0,
	@TechOperationsTest bit = 0,
	@MechanicalTest bit = 0,
	@ProcedureLocation nvarchar(400)=null
	AS

	DECLARE @ReturnValue int
	
	set @ID = (select ID from Jobs where jobs.JobName=@JobName)
	
	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO Jobs
		(
			JobName, 
			WILocation,
			Comment,
			LastUser,
			OperationsTest,
			TechnicalOperationsTest,
			MechanicalTest,
			ProcedureLocation
		)
		VALUES
		(
			@JobName, 
			@WILocation,
			@Comment,
			@LastUser,
			@OperationsTest,
			@TechOperationsTest,
			@MechanicalTest,
			@ProcedureLocation
		)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE Jobs SET
			JobName = @JobName, 
			LastUser = @LastUser,
			Comment = @Comment,
			WILocation = @WILocation,
			OperationsTest = @OperationsTest,
			TechnicalOperationsTest = @TechOperationsTest,
			MechanicalTest = @MechanicalTest,
			ProcedureLocation = @ProcedureLocation
		WHERE 
			ID = @ID
			--AND ConcurrencyID = @ConcurrencyID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM Jobs WHERE ID = @ReturnValue)
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
GRANT EXECUTE ON remispJobsInsertUpdateSingleItem TO REMI
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
COMMIT TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO