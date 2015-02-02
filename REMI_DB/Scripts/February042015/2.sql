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