/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 2/2/2015 9:02:30 AM

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
ALTER TABLE Req.ReqFieldData ADD rv ROWVERSION
GO
ALTER TABLE Relab.ResultsInformation ADD rv ROWVERSION
GO
ALTER TABLE Relab.ResultsParameters ADD rv ROWVERSION
GO
ALTER TABLE Relab.ResultsXML ADD rv ROWVERSION
GO
ALTER TABLE Relab.ResultsMeasurementsFiles ADD rv ROWVERSION
GO
ALTER TABLE Relab.ResultsMeasurements ADD rv ROWVERSION
GO
ALTER TABLE Relab.Results ADD rv ROWVERSION
GO
ALTER TABLE Req.Request ADD rv ROWVERSION
GO
ALTER TABLE Req.RequestType ADD rv ROWVERSION
GO
PRINT N'Altering [Relab].[remispResultsMeasurementFileUpload]'
GO
ALTER PROCEDURE Relab.remispResultsMeasurementFileUpload @File VARBINARY(MAX), @ContentType NVARCHAR(50), @FileName NVARCHAR(200), @Success AS BIT = NULL OUTPUT
AS
BEGIN
	IF (DATALENGTH(@File) > 0)
	BEGIN
		INSERT INTO Relab.ResultsMeasurementsFiles ( ResultMeasurementID, [File], ContentType, FileName)
		VALUES (NULL, @File, @ContentType, @FileName)
		SET @Success = 1
	END
	ELSE
	BEGIN
		SET @Success = 0
	END

	PRINT @Success
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispSaveProduct]'
GO
ALTER PROCEDURE [dbo].[remispSaveProduct] @ProductID int , @isActive int, @ProductGroupName NVARCHAR(150), @QAP NVARCHAR(255), @TSDContact NVARCHAR(255), @Success AS BIT = NULL OUTPUT
AS
BEGIN
	IF (@ProductID = 0)--ensure we don't have it
	BEGIN
		SELECT @ProductID = ID
		FROM Products p
			INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
		WHERE LTRIM(RTRIM(lp.[values]))=LTRIM(RTRIM(@ProductGroupName))
	END

	IF (@ProductID = 0)--if we still dont have it insert it
	BEGIN
		DECLARE @LookupTypeID INT
		DECLARE @LookupID INT
		SELECT @LookupID = MAX(LookupID)+1 FROM Lookups
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Products'		
				
		INSERT INTO Lookups ([Values], LookupID, IsActive) VALUES (LTRIM(RTRIM(@ProductGroupName)), @LookupID, 1)
		INSERT INTO Products (LookupID, QAPLocation, TSDContact) 
		VALUES (@LookupID, @QAP, @TSDContact)

		SET @Success = 1
	END
	ELSE
	BEGIN
		UPDATE Products
		SET QAPLocation = @QAP, TSDContact = @TSDContact
		WHERE ID=@ProductID

		SET @Success = 1
	END
END
GRANT EXECUTE ON remispSaveProduct TO REMI
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispSaveLookup]'
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
		
		SET @Success = 1
	END
	ELSE
	BEGIN
		UPDATE Lookups
		SET IsActive=@IsActive, Description=@Description, ParentID=@ParentID
		WHERE LookupTypeID=@LookupTypeID AND [values]=LTRIM(RTRIM(@Value))
		
		SET @Success = 1
	END

	PRINT @Success
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispJobOrientationSave]'
GO
ALTER PROCEDURE [dbo].[remispJobOrientationSave] @ID INT = 0, @Name NVARCHAR(150), @JobID INT, @ProductTypeID INT, @Description NVARCHAR(250), @IsActive BIT, @Definition NTEXT = NULL, @Success AS BIT = NULL OUTPUT
AS
BEGIN
	IF (@ID = 0)
	BEGIN
		DECLARE @XML XML
		DECLARE @NumUnits INT
		DECLARE @NumDrops INT
		SELECT @XML = CONVERT(XML, @Definition)
		
		SELECT @NumUnits=MAX(T.c.value('(@Unit)[1]', 'int')), @NumDrops =MAX(T.c.value('(@Drop)[1]', 'int'))
		FROM @XML.nodes('/Orientations/Orientation') as T(c)

		IF (@NumUnits IS NULL)
		BEGIN
			SET @NumUnits = 0
		END
		
		IF (@NumDrops IS NULL)
		BEGIN
			SET @NumDrops = 0
		END
				
		INSERT INTO JobOrientation (JobID, ProductTypeID, NumUnits, NumDrops, Description, IsActive, Definition, Name)
		VALUES (@JobID, @ProductTypeID, @NumUnits, @NumDrops, @Description, @IsActive, @XML, @Name)

		SET @Success = 1
	END
	ELSE
	BEGIN
		UPDATE JobOrientation
		SET IsActive = @IsActive, Name = @Name, Description=@Description, ProductTypeID=@ProductTypeID
		WHERE ID=@ID

		SET @Success = 1
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispResultsFileUpload]'
GO
ALTER PROCEDURE [Relab].[remispResultsFileUpload] @XML AS NTEXT, @LossFile AS NTEXT = NULL, @Success AS BIT = NULL OUTPUT
AS
BEGIN
	DECLARE @TestStageID INT
	DECLARE @TestID INT
	DECLARE @TestUnitID INT
	DECLARE @VerNum INT
	DECLARE @ResultID INT
	DECLARE @ResultsXML XML
	DECLARE @StartDate DATETIME
	DECLARE @EndDate NVARCHAR(MAX)
	DECLARE @Duration NVARCHAR(MAX)
	DECLARE @ResultsLossFile XML
	DECLARE @TestName NVARCHAR(400)
	DECLARE @TestStageName NVARCHAR(400)
	DECLARE @QRANumber NVARCHAR(11)
	DECLARE @JobName NVARCHAR(400)
	DECLARE @StationName NVARCHAR(400)
	DECLARE @FinalResult NVARCHAR(15)
	DECLARE @PassFail BIT
	DECLARE @TestUnitNumber INT
	DECLARE @Insert INT
	SET @Insert = 1

	SELECT @ResultsXML = CONVERT(XML, @XML)
	SELECT @ResultsLossFile = CONVERT(XML, @LossFile)

	SELECT @TestName = T.c.query('TestName').value('.', 'nvarchar(max)'),
		@QRANumber = T.c.query('JobNumber').value('.', 'nvarchar(max)'),
		@TestUnitNumber = T.c.query('UnitNumber').value('.', 'int'),
		@TestStageName = T.c.query('TestStage').value('.', 'nvarchar(max)'),
		@JobName = T.c.query('TestType').value('.', 'nvarchar(max)'),
		@FinalResult = T.c.query('FinalResult').value('.', 'nvarchar(max)'),
		@EndDate = T.c.query('DateCompleted').value('.', 'nvarchar(max)'),
		@Duration = T.c.query('Duration').value('.', 'nvarchar(max)'),
		@StationName = T.c.query('StationName').value('.', 'nvarchar(400)')
	FROM @ResultsXML.nodes('/TestResults/Header') T(c)
		
	IF (@QRANumber IS NULL OR LTRIM(RTRIM(@QRANumber)) = '')
	BEGIN
		SELECT @QRANumber = T.c.query('RequestNumber').value('.', 'nvarchar(max)')
		FROM @ResultsXML.nodes('/TestResults/Header') T(c)
	END
	IF (@JobName IS NULL OR LTRIM(RTRIM(@JobName)) = '')
	BEGIN
		SELECT @JobName = T.c.query('JobName').value('.', 'nvarchar(max)')
		FROM @ResultsXML.nodes('/TestResults/Header') T(c)
	END
	
	IF (@EndDate IS NULL OR LTRIM(RTRIM(@EndDate)) = '')
	BEGIN
		SELECT @EndDate = T.c.query('DateCompleted').value('.', 'nvarchar(max)')
		FROM @ResultsXML.nodes('/TestResults/Footer') T(c)
	END
	
	IF (@Duration IS NULL OR LTRIM(RTRIM(@Duration)) = '')
	BEGIN
		SELECT @Duration = T.c.query('Duration').value('.', 'nvarchar(max)')
		FROM @ResultsXML.nodes('/TestResults/Footer') T(c)
	END
	
	if (@FinalResult IS NOT NULL AND LTRIM(RTRIM(@FinalResult)) <> '')
	BEGIN
		IF (@FinalResult = 'Pass')
		BEGIN
			SET @PassFail = 1
		END
		ELSE
		BEGIN
			SET @PassFail = 0
		END
	END
	ELSE
	BEGIN
		IF (EXISTS (SELECT T.c.query('.').value('.', 'nvarchar(max)') FROM @ResultsXML.nodes('/TestResults/Measurements/Measurement/PassFail') T(c) WHERE LTRIM(RTRIM(T.c.query('.').value('.', 'nvarchar(max)'))) = 'fail'))
		BEGIN
			SET @PassFail = 0
		END
		ELSE
		BEGIN
			SET @PassFail = 1
		END
	END

	SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ' ')
	SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ':')
	SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ':')
					
	If (CHARINDEX('.', @Duration) > 0)
		SET @Duration = SUBSTRING(@Duration, 1, CHARINDEX('.', @Duration)-1)
			
	SET @StartDate=dateadd(s,-datediff(s,0,convert(DATETIME,@Duration)), CONVERT(DATETIME, @EndDate))

	SELECT @TestUnitID = tu.ID
	FROM TestUnits tu
		INNER JOIN Batches b ON tu.BatchID=b.ID
	WHERE QRANumber=@QRANumber AND tu.BatchUnitNumber=@TestUnitNumber
	
	PRINT 'QRA: ' + CONVERT(VARCHAR, @QRANumber)
	PRINT 'Unit Number: ' + CONVERT(VARCHAR, @TestUnitNumber)
	PRINT 'Unit Number: ' + CONVERT(VARCHAR, @TestUnitNumber)
	PRINT 'Duration: ' + CONVERT(VARCHAR, @Duration)
	PRINT 'Date Started: ' + CONVERT(VARCHAR, @StartDate)
	PRINT 'Date Completed: ' + CONVERT(VARCHAR, @EndDate)
	PRINT 'Test Stage: ' + @TestStageName
	PRINT 'Job: ' + @JobName
	PRINT 'Test Name: ' + @TestName

	IF (@TestUnitID IS NOT NULL)
	BEGIN
		PRINT 'TestUnitID: ' + CONVERT(VARCHAR, @TestUnitID)

		SELECT @TestStageID = ts.ID 
		FROM Jobs j
			INNER JOIN TestStages ts ON j.ID=ts.JobID
		WHERE j.JobName=@JobName AND ts.TestStageName=@TestStageName
	
		PRINT 'TestStageID: ' + CONVERT(VARCHAR, @TestStageID)

		SELECT @TestID = t.ID
		FROM Tests t
		WHERE t.TestName=@TestName
	
		PRINT 'TestID: ' + CONVERT(VARCHAR, @TestID)
	
		IF (@TestID = 1099)--sensor
		BEGIN
			IF ((SELECT COUNT(*) FROM @ResultsXML.nodes('/TestResults/Measurements/Measurement/FileName') T(c) WHERE LTRIM(RTRIM(T.c.query('.').value('.', 'nvarchar(max)'))) <> '')=0)
			BEGIN
				SET @Insert = 0
			END
		END
	
		IF (@Insert = 1)
		BEGIN	
			SELECT @ResultID=ID FROM Relab.Results WHERE TestStageID=@TestStageID AND TestID=@TestID AND TestUnitID=@TestUnitID
	
			IF (@ResultID IS NULL OR @ResultID = 0)
			BEGIN
				IF (@TestStageID IS NULL OR @TestID IS NULL)
					BEGIN
						INSERT INTO Relab.ResultsOrphaned (ResultXML, LossFile)
						VALUES (@XML, @ResultsLossFile)

						SET @Success = 0
						PRINT @Success
					END
				ELSE
					BEGIN
						INSERT INTO Relab.Results (TestStageID, TestID,TestUnitID, PassFail)
						VALUES (@TestStageID, @TestID, @TestUnitID, @PassFail)

						SELECT @ResultID=ID FROM Relab.Results WHERE TestStageID=@TestStageID AND TestID=@TestID AND TestUnitID=@TestUnitID

						INSERT INTO Relab.ResultsXML (ResultID, ResultXML, VerNum, StationName, StartDate, EndDate, LossFile)
						VALUES (@ResultID, @XML, 1, @StationName, @StartDate, CONVERT(DATETIME, @EndDate), @ResultsLossFile)

						SET @Success = 1
						PRINT @Success
					END
			END
			ELSE
			BEGIN
				SELECT @VerNum = ISNULL(COUNT(*), 0)+1 FROM Relab.ResultsXML WHERE ResultID=@ResultID

				INSERT INTO Relab.ResultsXML (ResultID, ResultXML, VerNum, StationName, StartDate, EndDate, LossFile)
				VALUES (@ResultID, @XML, @VerNum, @StationName, @StartDate, CONVERT(DATETIME, @EndDate), @ResultsLossFile)

				SET @Success = 1
				PRINT @Success
			END
		END
	END
	ELSE
	BEGIN
		INSERT INTO Relab.ResultsOrphaned (ResultXML, LossFile)
		VALUES (@XML, @ResultsLossFile)

		SET @Success = 0
		
		PRINT @Success
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispAddRemovePermissiontoRole]'
GO
ALTER PROCEDURE [dbo].[remispAddRemovePermissiontoRole] @Permission NVARCHAR(256), @Role NVARCHAR(256), @Success AS BIT = NULL OUTPUT
AS
BEGIN
	DECLARE @RoleID UNIQUEIDENTIFIER
	DECLARE @PermissionID UNIQUEIDENTIFIER

	SELECT @PermissionID = PermissionID FROM aspnet_Permissions WHERE Permission=@Permission
	SELECT @RoleID = RoleID FROM aspnet_Roles WHERE RoleName=@Role
	
	IF EXISTS (SELECT 1 FROM aspnet_PermissionsInRoles WHERE PermissionID=@PermissionID AND RoleID=@RoleID)
		BEGIN
			DELETE FROM aspnet_PermissionsInRoles WHERE PermissionID=@PermissionID AND RoleID=@RoleID
			SET @Success = 1
		END
	ELSE
		BEGIN
			INSERT INTO aspnet_PermissionsInRoles (PermissionID, RoleID) VALUES (@PermissionID, @RoleID)
			SET @Success = 1
		END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[TestsAccess]'
GO
CREATE TABLE [dbo].[TestsAccess]
(
[TestAccessID] [int] NOT NULL IDENTITY(1, 1),
[TestID] [int] NOT NULL,
[LookupID] [int] NOT NULL
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_TestsAccess] on [dbo].[TestsAccess]'
GO
ALTER TABLE [dbo].[TestsAccess] ADD CONSTRAINT [PK_TestsAccess] PRIMARY KEY CLUSTERED  ([TestAccessID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispGetTestsAccess]'
GO
CREATE PROCEDURE [dbo].[remispGetTestsAccess] @TestID INT = 0
AS
BEGIN
	SELECT ta.TestAccessID, t.TestName, l.[Values] As Department
	FROM TestsAccess ta
		INNER JOIN Tests t ON t.ID=ta.TestID
		INNER JOIN Lookups l ON l.LookupID=ta.LookupID
	WHERE (@TestID > 0 AND ta.TestID=@TestID) OR (@TestID = 0)
	ORDER BY t.TestName
END
GO
grant execute on remispGetTestsAccess to remi
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [dbo].[TestsAccess]'
GO
ALTER TABLE [dbo].[TestsAccess] ADD CONSTRAINT [FK_TestsAccess_Tests] FOREIGN KEY ([TestID]) REFERENCES [dbo].[Tests] ([ID])
ALTER TABLE [dbo].[TestsAccess] ADD CONSTRAINT [FK_TestsAccess_Lookups] FOREIGN KEY ([LookupID]) REFERENCES [dbo].[Lookups] ([LookupID])
GO

insert into TestsAccess (TestID,LookupID)
select ID as testid, 5752 as lookupid
from tests
where isnull(IsArchived,0)=0 and TestType=1
GO
ALTER PROCEDURE [Req].[GetRequestSetupInfo] @ProductID INT, @JobID INT, @BatchID INT, @TestStageType INT, @BlankSelected INT, @UserID INT
AS
BEGIN
	SELECT ud.LookupID
	INTO #Departments
	FROM UserDetails ud
		INNER JOIN Lookups l ON l.LookupID=ud.LookupID
		INNER JOIN LookupType lt ON lt.LookupTypeID=l.LookupTypeID
	WHERE ud.UserID=@UserID AND lt.Name='Department'

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
				AND (@TestStageType = 1 AND t.ID IN (SELECT TestID FROM TestsAccess ta INNER JOIN #Departments d ON d.LookupID=ta.LookupID))
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
				AND (@TestStageType = 1 AND t.ID IN (SELECT TestID FROM TestsAccess ta INNER JOIN #Departments d ON d.LookupID=ta.LookupID))
			ORDER BY ts.ProcessOrder, t.TestName
		END
		ELSE
		BEGIN
			SELECT ts.ID As TestStageID, ts.TestStageName, t.ID AS TestID, t.TestName, CASE WHEN @BlankSelected = 1 THEN CONVERT(BIT, 0) ELSE CONVERT(BIT, 1) END AS Selected
			FROM Jobs j
				INNER JOIN TestStages ts ON j.ID=ts.JobID
				INNER JOIN Tests t WITH(NOLOCK) ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
			WHERE j.ID=@JobID AND ts.TestStageType=@TestStageType AND ts.ProcessOrder >= 0 AND ISNULL(ts.IsArchived, 0) = 0 AND ISNULL(t.IsArchived, 0) = 0
				AND (@TestStageType = 1 AND t.ID IN (SELECT TestID FROM TestsAccess ta INNER JOIN #Departments d ON d.LookupID=ta.LookupID))
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
			AND (@TestStageType = 1 AND t.ID IN (SELECT TestID FROM TestsAccess ta INNER JOIN #Departments d ON d.LookupID=ta.LookupID))
		ORDER BY ts.ProcessOrder, t.TestName		
	END
	
	DROP TABLE #Departments
END
GO
GRANT EXECUTE ON [Req].[GetRequestSetupInfo] TO REMI
GO
ALTER PROCEDURE [dbo].[remispScanGetData]
	@qranumber nvarchar(11),
	@unitnumber int,
	@Hostname nvarchar(255)=  null,
	@selectedTrackingLocationID int = null,
	@selectedTestName nvarchar(300)=null,
	@selectedTestStageName nvarchar(300)=null,
	@trackingLocationName nvarchar(255) = null
AS
declare @jobName nvarchar(400)
declare @jobID int
declare @testUnitID int
declare @BSN bigint
declare @selectedTLCapacityRemaining int
declare @currentTest nvarchar(300)
declare @currentTestStage nvarchar(300)
declare @currentTestRecordStatus int
declare @currentTestRecordID int
declare @currentTestID int
declare @currentTestRequiredTestTime float
declare @currentTestTotalTestTime float
declare @currentTestIsTimed bit
declare @currentTestType int
declare @batchStatus int
declare @inFA bit
declare @inQuarantine bit
declare @productGroup nvarchar(400)
declare @jobWILocation nvarchar(400)
declare @selectedTestWI nvarchar(400)
declare @ApplicableTestStages nvarchar(1000)=''
declare @ApplicableTests nvarchar(1000)=''
declare @selectedTestRequiredTestTime float
declare @selectedTestStageIsValid bit
declare @selectedTestIsValid bit
declare @selectedTestIsMarkedDoNotProcess bit
declare @selectedTestRecordStatus int
declare @selectedTestType int
declare @selectedTestIsValidForLocation bit
declare @selectedTestIsTimed bit
declare @selectedTestStageID int
declare @selectedTestID int
declare @selectedTestRecordID int
declare @selectedTestTotalTestTime float
declare @selectedTrackingLocationName nvarchar(400)
declare @selectedLocationNumberOfScans int
declare @selectedTrackinglocationCurrentTestName nvarchar(300)
declare @selectedTrackingLocationWILocation nvarchar(400)
declare @selectedTrackingLocationFunction int
declare @cprNumber nvarchar(500)
declare @hwrevision nvarchar(500)
declare @batchSpecificDuration float 
declare @exceptionsTable table(name nvarchar(300), TestUnitException nvarchar(50))
declare @currentDtlID int, @currentDtlInTime datetime, @currentDtlOutTime datetime, @currentDtlInUser nvarchar(255),
 @currentDtlOutUser nvarchar(255), @currentDtlTrackingLocationName nvarchar(400), @currentDtlTrackingLocationID int
declare @isBBX nvarchar(200)
declare @productID INT
declare @accessoryTypeID INT
declare @productTypeID INT
declare @accessoryType NVARCHAR(150)
declare @productType NVARCHAR(150)
Declare @NoBSN BIT
DECLARE @DepartmentID INT

--jobname, product group, job WI, jobID
select @jobName=b.jobname,@cprNumber =b.CPRNumber,@hwrevision = b.HWRevision, @productGroup=lp.[Values],@jobWILocation=j.WILocation,@jobid=j.ID, @batchStatus = b.BatchStatus ,
@productID=p.ID, @NoBSN=j.NoBSN, @productTypeID=b.ProductTypeID, @accessoryTypeID=b.AccessoryGroupID, @DepartmentID = DepartmentID
from Batches as b
	INNER JOIN jobs as j ON j.JobName = b.JobName
	INNER JOIN Products p ON p.ID=b.ProductID
	INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
where b.QRANumber = @qranumber

SELECT @productType=[values] FROM Lookups WHERE LookupID=@productTypeID
SELECT @accessoryType=[values] FROM Lookups WHERE LookupID=@accessoryTypeID

--*******************
---This section gets the IsBBX value as a bit
declare @IsBBXvaluetext nvarchar(200) = (select ValueText FROM ProductSettings as ps where ps.ProductID = @ProductID and KeyName = 'IsBBX')
declare @IsBBXDefaultvaluetext nvarchar(200) =(select top (1) DefaultValue FROM ProductSettings as ps where KeyName = 'IsBBX' and DefaultValue is not null)
set @isBBX = case when @IsBBXvaluetext is not null then @IsBBXvaluetext else @IsBBXDefaultvaluetext end;

--tracking location wi
select TOP 1 @selectedTrackingLocationID = tl.ID, @selectedTrackingLocationWILocation=tlt.WILocation,@selectedTrackingLocationName = TrackingLocationName,@selectedTrackingLocationFunction = tlt.TrackingLocationFunction 
from TrackingLocations as tl
	INNER JOIN TrackingLocationTypes as tlt ON tlt.ID = tl.TrackingLocationTypeID
	LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
where (@selectedTrackingLocationID IS NULL AND tlh.HostName = @Hostname and @HostName is not null AND 
		((tl.TrackingLocationname= @trackingLocationName AND @trackingLocationName IS NOT NULL) OR @trackingLocationName IS NULL)
	  )
	OR
	(@selectedTrackingLocationID IS NOT NULL AND tl.ID = @selectedTrackingLocationID)


-- tracking location current test name
set @selectedTrackinglocationCurrentTestName = (SELECT top(1) tu.CurrentTestName as CurrentTestName
		                    FROM TestUnits AS tu, DeviceTrackingLog AS dtl 
		             where tu.ID = dtl.TestUnitID and tu.CurrentTestName is not null and dtl.TrackingLocationID = @selectedTrackingLocationID and (dtl.OutUser IS NULL))
--test unit id, bsncurrent test/test stage

(select @testUnitID=tu.id,@bsn = tu.BSN,@currentTest=tu.CurrentTestName,@currentTeststage=tu.CurrentTestStageName from testunits as tu, Batches as b 
	where tu.BatchID = b.ID and b.QRANumber = @qranumber and tu.BatchUnitNumber = @unitnumber)

--teststage id

select @selectedTestStageID = ts.id 
from teststages as ts
where ts.JobID = @jobID and ts.TestStageName = @selectedTestStageName

--selected test details

SELECT  @selectedTestID=t.ID, @selectedTestIsTimed =t.resultbasedontime,@selectedTestType = t.TestType, @selectedTestWI = t.WILocation
from Tests AS t, TestStages as ts
WHERE ts.ID = @selectedTestStageID  
and (
		(ts.TestStagetype = 2 and t.TestName=ts.teststagename and t.TestName = @selectedTestName and t.id = ts.TestID) --if its an env teststage get the equivelant test
		or (ts.teststagetype = 1 and t.testtype = 1 and t.TestName = @selectedTestName)--otherwise if its a para test stage get the para test
		or (ts.teststagetype = 3 and t.testtype = 3 and t.TestName = @selectedTestName) --or the incoming eval test
	)
--current test details

SELECT  @currentTestID=t.ID, @currentTestIsTimed =t.resultbasedontime,@currentTestType = t.TestType 
from Tests AS t, TestStages as ts 
WHERE ts.TestStageName = @currentTestStage
and ts.JobID = @jobid
and (
		(ts.TestStagetype = 2 and t.TestName=ts.teststagename and t.TestName = @currentTest and t.id = ts.TestID) --if its an env teststage get the equivelant test
		or (ts.teststagetype = 1 and t.testtype = 1 and t.TestName = @currentTest)--otherwise if its a para test stage get the para test
		or (ts.teststagetype = 3 and t.testtype = 3 and t.TestName = @currentTest) --or the incoming eval test
	)
--selected test record id

select @selectedTestRecordID = Tr.id, @selectedTestRecordStatus = tr.Status
from TestRecords as tr 
where tr.JobName = @jobName and tr.TestStageName = @selectedTestStageName and tr.TestName = @selectedTestName and tr.TestUnitID = @testUnitID

--OLD test record id

select @currentTestRecordID = Tr.id, @currentTestRecordStatus = tr.Status 
from TestRecords as tr
where tr.JobName = @jobName and tr.TestStageName = @currentTestStage and tr.TestName = @currentTest and tr.TestUnitID = @testUnitID

--time info. adjusted to select the selected test batch specific duration if applicable
set @batchSpecificDuration = (select Duration from BatchSpecificTestDurations, Batches where TestID = @selectedTestID and BatchID = Batches.ID and Batches.QRANumber = @qranumber)
set @selectedTestRequiredTestTime = case when @batchSpecificDuration is not null then @batchSpecificDuration else (select Tests.Duration from Tests where ID = @selectedTestID) end

--now select the currentTest test duration
set @batchSpecificDuration = (select Duration from BatchSpecificTestDurations, Batches where TestID = @currentTestID and BatchID = Batches.ID and Batches.QRANumber = @qranumber)
set @currentTestRequiredTestTime = case when @batchSpecificDuration is not null then @batchSpecificDuration else (select Tests.Duration from Tests where ID = @currentTestID) end

set @selectedTestTotalTestTime = (Select sum(datediff(MINUTE,dtl.intime,
(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end ))) 
	 from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl 
	 where trXtl.TestRecordID = @selectedTestRecordID and dtl.ID = trXtl.TrackingLogID)
	 
set @currentTestTotalTestTime = (Select sum(datediff(MINUTE,dtl.intime,
(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end ))) 
	 from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl 
	 where trXtl.TestRecordID = @currentTestRecordID and dtl.ID = trXtl.TrackingLogID)
	 
--tlcapacity
set @selectedTLCapacityRemaining = (select tlt.UnitCapacity - (SELECT COUNT(dtl.ID)--currentcount
		                    FROM  DeviceTrackingLog AS dtl
		                                          where 
		                                           dtl.TrackingLocationID = @selectedTrackingLocationID
		                                          and (dtl.OutUser IS NULL))
		                                          
		                                          from TrackingLocations as tl, TrackingLocationTypes as tlt
		                                          where tl.id = @selectedTrackingLocationID
		                                          and tlt.ID = tl.TrackingLocationTypeID)
--teststage is valid
set @selectedTestStageIsValid = (case when (@selectedTestStageID IS NULL) then 0 else 1 end)

--testisvalid
set @selectedTestIsValid = (case when (@selectedTestID IS NULL) then 0 else 1 end)

-- is dnp'd
insert @exceptionsTable exec remispTestExceptionsGetTestUnitTable @qranumber, @unitnumber, @selectedTestStageName  
set @selectedTestIsMarkedDoNotProcess = (select (case when (TestUnitException = 'True') then 1 else 0 end) from @exceptionstable where name = @selectedTestName)

-- is in FA
set @inFA = case when (select COUNT (*) from TestRecords as tr where TestUnitID = @testUnitID and (tr.Status = 3 or tr.Status = 10 or tr.Status = 11)) > 0 then 1 else 0 end --status is FARaised

-- is in Quarantine
set @inQuarantine = case when (select COUNT (*) from TestRecords as tr where TestUnitID = @testUnitID and tr.Status = 9)>0 then 1 else 0 end --status is Quarantine


--number of scans
set @selectedLocationNumberOfScans = (select COUNT (*) from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl where trXtl.TestRecordID = @selectedTestRecordID and dtl.ID = trXtl.TrackingLogID)
--test valid for tracking location
set @selectedTestIsValidForLocation = case when (select 1 from Tests as t, TrackingLocations as tl, trackinglocationtypes as tlt, TrackingLocationsForTests as tltfort 
where tlt.ID = tltfort.TrackingLocationtypeID and t.ID = tltfort.TestID and t.ID = @selectedTestID and tlt.ID = tl.TrackingLocationTypeID and tl.ID = @selectedTrackingLocationID) IS not null then 1 else 0 end
--get applicable test stages
select @ApplicableTestStages = @ApplicableTestStages + ','  + TestStageName from TestStages where ISNULL(TestStages.IsArchived, 0)=0 AND testStages.TestStageType NOT IN (4,5, 0) AND TestStages.JobID = @jobID order by ProcessOrder

--get applicable tests
SELECT test.TestName, test.ProcessOrder
INTO #tests
FROM (
SELECT t.TestName, ts.ProcessOrder
FROM Tests t
	INNER JOIN TrackingLocationsForTests tlft ON t.ID = tlft.TestID
	INNER JOIN TrackingLocationTypes tlt ON tlt.ID = tlft.TrackingLocationtypeID
	INNER JOIN TrackingLocations tl ON tl.TrackingLocationTypeID = tlt.ID
	INNER JOIN TestStages ts ON ts.TestID = t.ID AND ts.JobID=@jobID AND t.TestType NOT IN (1, 3)
WHERE ISNULL(t.IsArchived, 0)=0 AND tl.ID = @selectedTrackingLocationID
UNION
SELECT t2.TestName, 0 AS ProcessOrder
FROM Tests t2
	INNER JOIN TrackingLocationsForTests tlft ON t2.ID = tlft.TestID
	INNER JOIN TrackingLocationTypes tlt ON tlt.ID = tlft.TrackingLocationtypeID
	INNER JOIN TrackingLocations tl ON tl.TrackingLocationTypeID = tlt.ID
	INNER JOIN TestsAccess ta ON ta.TestID=t2.id AND ta.LookupID IN (@DepartmentID)
WHERE ISNULL(t2.IsArchived, 0)=0 AND tl.ID = @selectedTrackingLocationID AND t2.TestType IN (1, 3)
) test
ORDER BY test.ProcessOrder

SELECT @ApplicableTests = @ApplicableTests + ','  + TestName FROM #tests
DROP TABLE #tests

set @ApplicableTestStages = SUBSTRING(@ApplicableTestStages,2,Len(@ApplicableTestStages))
set @ApplicableTests = SUBSTRING(@ApplicableTests,2,Len(@ApplicableTests))

----------------------------
---  Tracking Log Params ---
----------------------------
 
 select top(1) @currentDtlID=dtl.id,
 	@currentDtlInTime =InTime, 
 	@currentDtlOutTime=OutTime,
	@currentDtlInUser=InUser, 
	@currentDtlOutUser =OutUser,
	@currentDtlTrackingLocationName=trackinglocationname , 
	@currentDtlTrackingLocationID=tl.ID
	FROM DeviceTrackingLog as dtl, TrackingLocations as tl
	WHERE (dtl.TestUnitID = @testUnitID and tl.ID = dtl.TrackingLocationID)
	order by dtl.intime desc

----------------------
--  RETURN DATA ------
----------------------
select @currentDtlID as currentDtlID,
	@testUnitID as testunitID,
 	@currentDtlInTime as currentDtlInTime, 
 	@currentDtlOutTime as currentDtlOutTime,
	@currentDtlInUser as currentDtlInUser,
	@currentDtlOutUser as currentDtlOutUser,
	@currentDtlTrackingLocationName as currentDtlTrackingLocationName, 
	@currentDtlTrackingLocationID as currentDtlTrackingLocationID,		
	@currentTeststage as currentTestStage,
	@currentTest as currentTest,
	@currentTestRecordStatus as currentTestRecordStatus,
	@currentTestRecordID as currentTestRecordID,
	@currentTestRequiredTestTime as currentTestRequiredTestTime,
	@currentTestTotalTestTime as currentTestTotalTestTime,
	@currentTestIsTimed as currenttestIsTimed,
	@currentTestType as currenttestType,	
	@batchStatus as batchStatus,
	@inFA as inFA,	
    @productGroup as productGroup,
	@jobWILocation as jobWILocation,		
	@jobName as jobName,
	@BSN as bsn,	
	@isBBX as isBBX,	
	@selectedTLCapacityRemaining as selectedTLCapacityRemaining,
	@selectedTrackingLocationName as selectedTrackingLocationName,
	@selectedTrackingLocationID as selectedTrackingLocationID,
	@selectedTestStageIsValid as selectedTestStageIsValid,
	@selectedTestIsValid as selectedTestIsValid,
	@selectedTestIsMarkedDoNotProcess as selectedTestIsMarkedDoNotProcess,
	@selectedTestType as selectedTestType, 
	@selectedTrackinglocationCurrentTestName as selectedTrackinglocationCurrentTestName,
	@selectedTestRecordStatus as selectedTestRecordStatus,
	@selectedTrackingLocationWILocation as selectedTrackingLocationWILocation ,
	@selectedTrackingLocationFunction as selectedTrackingLocationFunction,
	@selectedTestRecordID as selectedTestRecordID,
	@selectedTestIsValidForLocation as selectedTestIsValidForLocation,
	@selectedTestIsTimed as selectedTestIsTimed,
	@selectedLocationNumberOfScans as selectedLocationNumberOfScans,	
	@selectedTestRequiredTestTime as selectedTestRequiredTestTime,
	@selectedTestTotalTestTime as selectedTestTotalTestTime,		
	@cprNumber as CPRNumber,
	@hwrevision as HWRevision,		
	@ApplicableTestStages as ApplicableTestStages, 
	@ApplicableTests as ApplicableTests,
	@selectedTestID as selectedTestID,
	@productID As ProductID,
	@selectedTestWI AS selectedTestWILocation, @NoBSN AS NoBSN, @productType AS ProductType, @productTypeID AS ProductTypeID, @accessoryType AS AccessoryType, @accessoryTypeID AS AccessoryTypeID
	
	exec remispTrackingLocationsSelectForTest @selectedTestID, @selectedTrackingLocationID
	 
IF (@@ERROR != 0)
	BEGIN
		RETURN -3
	END
	ELSE
	BEGIN
		RETURN 0
	END
GO
GRANT EXECUTE ON remispScanGetData TO REMI
GO
ALTER procedure [dbo].[remispGetFastScanData]
@qranumber nvarchar(11),
@unitnumber int,
@Hostname nvarchar(255)=  null,
@TLID int = null,
@testName nvarchar(300)=null,
@teststagename nvarchar(300)=null
AS
--initialise return data
declare @currenttlname nvarchar(400)
declare @tlCapacityRemaining int
declare @testunitcurrenttest nvarchar(300)
declare @testUnitCurrentTestStage nvarchar(300)
declare @teststageisvalid bit
declare @testisvalid bit
declare @isDNP bit
declare @testrecordstatus int
declare @OLDtestrecordstatus int
declare @numberoftests int
declare @batchstatus int
declare @inFA bit
declare @inQuarantine bit
declare @testType int
declare @trackinglocationCurrentTestName nvarchar(300)
declare @productname nvarchar(400)
declare @jobWILocation nvarchar(400)
declare @tlWILocation nvarchar(400)
declare @tlfunction int
declare @BSN bigint
declare @TestIsValidForLocation bit
declare @testIsTimed bit
declare @requiredTestTime float
declare @batchSpecificDuration float 
declare @totalTestTimeMinutes float
declare @ApplicableTestStages nvarchar(1000)=''
declare @ApplicableTests nvarchar(1000)=''
DECLARE @DepartmentID INT
-----------------------
--Vars for use in SP --
-----------------------

--jobname-- product group
declare @jobname nvarchar(400)

select @jobname=jobname, @productname=lp.[Values], @DepartmentID = DepartmentID from Batches inner join Products p on p.ID=Batches.ProductID 
				INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID where Batches.QRANumber = @qranumber

declare @jobID int
-- job WI
select @jobWILocation=j.WILocation,@jobid=j.ID from Jobs as j where j.JobName = @jobname

--tracking location id
if @tlid is null
begin
	SELECT TOP (1) @tlid = TrackingLocationID
	FROM TrackingLocationsHosts tlh
	WHERE tlh.HostName = @Hostname and @HostName is not null
end

--tracking location wi
set	@tlWILocation = (select tlt.WILocation from TrackingLocations as tl, TrackingLocationTypes as tlt where tl.ID = @tlid and tlt.ID = tl.TrackingLocationTypeID)

-- tracking location current test name

set @trackinglocationCurrentTestName = (SELECT     top(1) tu.CurrentTestName as CurrentTestName
		                    FROM TestUnits AS tu, DeviceTrackingLog AS dtl 
		                                          where tu.ID = dtl.TestUnitID 
		                                          and tu.CurrentTestName is not null
		                                          and dtl.TrackingLocationID = @TLID 
		                                          and (dtl.OutUser IS NULL))
--test unit id
declare @testunitid int
if (@qranumber is not null and @unitnumber is not null )
begin
	set @testunitid = (select tu.id from testunits as tu, Batches as b 
	where tu.BatchID = b.ID and b.QRANumber = @qranumber and tu.BatchUnitNumber = @unitnumber)
end
--test unit's current test stage
select @testunitcurrenttest=tu.CurrentTestName,@testunitcurrentteststage=tu.CurrentTestStageName 
from TestUnits as tu where tu.ID = @testunitid

--bsn
set @bsn = (select bsn from TestUnits where ID = @testunitid)

--teststage id
declare @teststageID int
set @teststageid = (select ts.id from teststages as ts, jobs as j
where j.JobName = @jobname and ts.JobID = j.ID and ts.TestStageName = @teststagename)

--test id
declare @testID int
set @testid = 	(SELECT  t.ID FROM  Tests AS t, TestStages as ts WHERE    
		    ts.ID = @TestStageID  
		    and ((ts.TestStagetype = 2 and t.TestName=ts.teststagename and t.TestName = @testName
		    and t.id = ts.TestID) --if its an env teststage get the equivelant test
		    or (ts.teststagetype = 1
		    and t.testtype = 1 and t.TestName = @testName)--otherwise if its a para test stage get the para test
		       or (ts.teststagetype = 3
		    and t.testtype = 3 and t.TestName = @testName))) --or the incoming eval test
--test id
declare @currentTestID int
set @currentTestID = 	(SELECT  t.ID FROM  Tests AS t, TestStages as ts WHERE    
		    ts.TestStageName = @testUnitCurrentTestStage
		    and ts.JobID = @jobid
		    and ((ts.TestStagetype = 2 and t.TestName=ts.teststagename and t.TestName = @testunitcurrenttest
		    and t.id = ts.TestID) --if its an env teststage get the equivelant test
		    or (ts.teststagetype = 1
		    and t.testtype = 1 and t.TestName = @testunitcurrenttest)--otherwise if its a para test stage get the para test
		       or (ts.teststagetype = 3
		    and t.testtype = 3 and t.TestName = @testunitcurrenttest))) --or the incoming eval test
--test record id
declare @trid int
set @trid = (select Tr.id from TestRecords as tr where
tr.JobName = @jobname and tr.TestStageName = @teststagename and tr.TestName = @testName and tr.TestUnitID = @testunitid)

--OLD test record id
declare @OLDtrid int
set @OLDtrid = (select Tr.id from TestRecords as tr where
tr.JobName = @jobname and tr.TestStageName = @testUnitCurrentTestStage and tr.TestName = @testunitcurrenttest and tr.TestUnitID = @testunitid)

--time info. adjusted to select the batch specific duration if applicable
set @testIsTimed = (select ResultBasedOntime from Tests where ID = @currentTestID)
set @batchSpecificDuration = (select Duration from BatchSpecificTestDurations, Batches where TestID = @testID and BatchID = Batches.ID and Batches.QRANumber = @qranumber)
set @requiredTestTime = case when @batchSpecificDuration is not null then @batchSpecificDuration else (select Tests.Duration from Tests where ID = @testID) end

set @totalTestTimeMinutes = (Select sum(datediff(MINUTE,dtl.intime,
(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end ))) 
	 from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl 
	 where trXtl.TestRecordID = @trid and dtl.ID = trXtl.TrackingLogID)


-----------------------
-- GET RETURN PARAMS --
-----------------------
-- batch status
set @batchstatus = (select BatchStatus from Batches where QRANumber = @qranumber)
--tlname
set	@currenttlname = (select trackinglocationname from TrackingLocations where id = @tlid)

--tlcapacity
set @tlCapacityRemaining = (select tlt.UnitCapacity - (SELECT COUNT(dtl.ID)--currentcount
		                    FROM  DeviceTrackingLog AS dtl
		                                          where 
		                                           dtl.TrackingLocationID = @tlid
		                                          and (dtl.OutUser IS NULL))
		                                          
		                                          from TrackingLocations as tl, TrackingLocationTypes as tlt
		                                          where tl.id = @tlid
		                                          and tlt.ID = tl.TrackingLocationTypeID)
--tlfunction
set @tlfunction = (select tlt.TrackingLocationFunction		                  	                                          
		                                          from TrackingLocations as tl, TrackingLocationTypes as tlt
		                                          where tl.id = @tlid
		                                          and tlt.ID = tl.TrackingLocationTypeID)


--teststage is valid
set @teststageisvalid = (case when (@teststageID IS NULL) then 0 else 1 end)

--testisvalid
set @testisvalid = (case when (@testID IS NULL) then 0 else 1 end)

--test type
set @testType = (select testtype from Tests where ID = @testID)

-- is dnp'd
declare @exceptionsTable table(name nvarchar(300), TestUnitException nvarchar(50))
insert @exceptionsTable exec remispTestExceptionsGetTestUnitTable @qranumber, @unitnumber, @teststagename  
set @isDNP = (select (case when (TestUnitException = 'True') then 1 else 0 end) from @exceptionstable where name = @testname)

-- is in FA
set @inFA = case when (select COUNT (*) from TestRecords as tr where TestUnitID = @testunitid and tr.Status = 3)>0 then 1 else 0 end --status is FARaised

-- is in FA
set @inQuarantine = case when (select COUNT (*) from TestRecords as tr where TestUnitID = @testunitid and tr.Status = 9)>0 then 1 else 0 end --status is Quarantine

--test record status
set @testrecordstatus = (select tr.Status from TestRecords as tr where tr.ID = @trid)
--test OLD record status
set @OLDtestrecordstatus = (select tr.Status from TestRecords as tr where tr.ID = @OLDtrid)

--number of scans
set @numberoftests = (select COUNT (*) from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl where trXtl.TestRecordID = @trid and dtl.ID = trXtl.TrackingLogID)
--test valid for tracking location
set @TestIsValidForLocation = case when (select 1 from Tests as t, TrackingLocations as tl, trackinglocationtypes as tlt, TrackingLocationsForTests as tltfort 
where tlt.ID = tltfort.TrackingLocationtypeID and t.ID = tltfort.TestID and t.ID = @testID and tlt.ID = tl.TrackingLocationTypeID and tl.ID = @TLID) IS not null then 1 else 0 end
--get applicable test stages
select @ApplicableTestStages = @ApplicableTestStages + ','  + TestStageName from TestStages where ISNULL(TestStages.IsArchived, 0)=0 AND testStages.TestStageType NOT IN (4,5, 0) AND TestStages.JobID = @jobID order by ProcessOrder


--get applicable tests
SELECT test.TestName, test.ProcessOrder
INTO #tests
FROM (
SELECT t.TestName, ts.ProcessOrder
FROM Tests t
	INNER JOIN TrackingLocationsForTests tlft ON t.ID = tlft.TestID
	INNER JOIN TrackingLocationTypes tlt ON tlt.ID = tlft.TrackingLocationtypeID
	INNER JOIN TrackingLocations tl ON tl.TrackingLocationTypeID = tlt.ID
	INNER JOIN TestStages ts ON ts.TestID = t.ID AND ts.JobID=@jobID AND t.TestType NOT IN (1, 3)
WHERE ISNULL(t.IsArchived, 0)=0 AND tl.ID = @tlid
UNION
SELECT t2.TestName, 0 AS ProcessOrder
FROM Tests t2
	INNER JOIN TrackingLocationsForTests tlft ON t2.ID = tlft.TestID
	INNER JOIN TrackingLocationTypes tlt ON tlt.ID = tlft.TrackingLocationtypeID
	INNER JOIN TrackingLocations tl ON tl.TrackingLocationTypeID = tlt.ID
	INNER JOIN TestsAccess ta ON ta.TestID=t2.id AND ta.LookupID IN (@DepartmentID)
WHERE ISNULL(t2.IsArchived, 0)=0 AND tl.ID = @tlid AND t2.TestType IN (1, 3)
) test
ORDER BY test.ProcessOrder

SELECT @ApplicableTests = @ApplicableTests + ','  + TestName FROM #tests
DROP TABLE #tests

set @ApplicableTests = SUBSTRING(@ApplicableTests,2,Len(@ApplicableTests))
set @ApplicableTestStages = SUBSTRING(@ApplicableTestStages,2,Len(@ApplicableTestStages))

----------------------------
---  Tracking Log Params ---
----------------------------

declare @dtlID int, @inTime datetime, @outtime datetime, @inuser nvarchar(255),
 @outuser nvarchar(255), @lasttrackinglocationname nvarchar(400), @LastTrackingLocationID int
 
 select   top(1)	@dtlID=dtl.id,
 	@inTime =InTime, 
 	@outtime=OutTime,
	@inuser=InUser, 
	@outuser =OutUser,
	@lasttrackinglocationname=trackinglocationname , 
	@LastTrackingLocationID=tl.ID 
	FROM     DeviceTrackingLog as dtl, TrackingLocations as tl
	WHERE     (dtl.TestUnitID = @TestUnitID and tl.ID = dtl.TrackingLocationID)
	order by dtl.intime desc;
----------------------
--  RETURN DATA ------
----------------------
select   @dtlID as LastLogID,
	@testunitid as TestUnitID,
 	@inTime as intime, 
 	@outtime as outtime,
	@InUser as inuser, 
	@OutUser as outuser,
	@lastTrackingLocationName as lasttrackinglocationname, 
	@LastTrackingLocationID as LastTrackingLocationID,
	@batchstatus as BatchStatus,
	@currenttlname as CurrentTrackingLocationName,
	@tlCapacityRemaining as CapacityRemaining,
	@TLID as CurrentTrackingLocationID,
	@testunitcurrentteststage as testUnitCurrentTestStage,
	@testunitcurrenttest as TestUnitCurrentTest ,
	@teststageisvalid as TestStageValid ,
	@testisvalid as TestValid,
	@isDNP as IsDNP,
	@inFA as IsInFA,
	@TestType as testType,
	@trackinglocationCurrentTestName as TrackingLocationCurrentTestName,
	@testrecordstatus  as TestRecordStatus,
	@OLDtestrecordstatus as OldTestRecordStatus,
	@numberoftests as NumberOfTests,
    @productname as ProductGroup,
	@jobWILocation as JobWI,
	@tlWILocation as TLWI,
	@trid as testrecordid,
	@tlfunction as tlfunction,
	@jobname as jobname,
	@BSN as BSN,
	@TestIsValidForLocation as TestIsValidForTrackingLocation,
	@testIsTimed as TestIsTimed,
	@requiredTestTime as TestDuration,
	@totalTestTimeMinutes as TotaltestTimeInMinutes,
	@ApplicableTestStages as ApplicableTestStages,
	@ApplicableTests as ApplicableTests
	
	exec remispTrackingLocationsSelectForTest @testid, @tlid;
	 
		IF (@@ERROR != 0)
	BEGIN
		RETURN -3
	END
	ELSE
	BEGIN
		RETURN 0
	END
GO
GRANT EXECUTE On remispGetFastScanData TO Remi
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