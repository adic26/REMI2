/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        CI0000001593275.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 6/28/2013 7:25:25 AM

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
PRINT N'Dropping constraints from [Relab].[ResultsMeasurements]'
GO
ALTER TABLE [Relab].[ResultsMeasurements] DROP CONSTRAINT [DF__ResultsMe__Archi__14BBFCF2]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Dropping constraints from [Relab].[ResultsXML]'
GO
ALTER TABLE [Relab].[ResultsXML] DROP CONSTRAINT [DF__ResultsXM__isPro__12D3B480]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[ResultsXML]'
GO
ALTER TABLE [Relab].[ResultsXML] ALTER COLUMN [isProcessed] [int] NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
CREATE PROCEDURE Relab.remispGetMeasurementParameterCommaSeparated @MeasurementID INT
AS
BEGIN
	select Relab.ResultsParametersNameComma(@MeasurementID,'N') AS ParameterName, Relab.ResultsParametersNameComma(@MeasurementID,'V') AS ParameterValue
END
GO
GRANT EXECUTE ON Relab.remispGetMeasurementParameterCommaSeparated TO REMI
GO
PRINT N'Creating [Relab].[remispResultVersions]'
GO
CREATE PROCEDURE Relab.remispResultVersions  @TestID INT, @BatchID INT
AS
BEGIN
	SELECT tu.BatchUnitNumber, ts.TestStageName As TestStage, rxml.ResultXML, rxml.StationName, rxml.StartDate, rxml.EndDate, ISNULL(rxml.lossFile,'') AS lossFile, 
		CASE WHEN rxml.isProcessed = 1 THEN 'Yes' ELSE 'No' END As Processed, rxml.VerNum
	FROM Relab.Results r
		INNER JOIN TestUnits tu ON r.TestUnitID=tu.ID
		INNER JOIN Relab.ResultsXML rxml ON r.ID=rxml.ResultID
		INNER JOIN TestStages ts ON ts.ID=r.TestStageID
	WHERE r.TestID=@TestID AND tu.BatchID=@BatchID
END
GO
GRANT EXECUTE ON [Relab].[remispResultVersions] TO Remi
GO

IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[vw_GetTaskInfo]'
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
	   TestStageID, TestWI, TestID
FROM   
	(
		SELECT b.qranumber,b.ID AS BatchID,
		ts.processorder, ts.teststagename AS tsname, t.testname AS tname, t.testtype, ts.teststagetype, t.duration AS genericTestDuration, ts.ID AS TestStageID,t.ID AS TestID,
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Relab].[remispGetTestsByBatches]'
GO
CREATE PROCEDURE Relab.remispGetTestsByBatches @BatchIDs NVARCHAR(MAX)
AS
BEGIN
	CREATE Table #batches(id int) 
	EXEC(@BatchIDs)
	DECLARE @Count INT
	
	SELECT @Count = COUNT(*) FROM #batches
	
	SELECT DISTINCT TestID, tname
	FROM dbo.vw_GetTaskInfo i
		INNER JOIN #batches b ON i.BatchID=b.ID
	WHERE i.processorder > -1 AND i.testtype=1
	GROUP BY TestID, tname
	HAVING COUNT(DISTINCT BatchID) >= @Count
	ORDER BY testid
	
	DROP TABLE #batches
END
GO
GRANT EXECUTE ON Relab.remispGetTestsByBatches TO REMI
GO
GRANT EXECUTE ON Relab.remispGetTestsByBatches TO REMI
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[ResultsMeasurements]'
GO
ALTER TABLE [Relab].[ResultsMeasurements] ALTER COLUMN [Archived] [bit] NOT NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Relab].[remispGetMeasurementsByTest]'
GO
create PROCEDURE Relab.remispGetMeasurementsByTest @BatchIDs NVARCHAR(MAX), @TestID INT
AS
BEGIN
	CREATE Table #batches(id int) 
	DECLARE @Count INT
	EXEC(@BatchIDs)
	
	SELECT @Count = COUNT(*) FROM #batches
	
	SELECT DISTINCT m.MeasurementTypeID, Lookups.[Values] As Measurement
	FROM TestUnits tu
		INNER JOIN Relab.Results r ON r.TestUnitID=tu.ID
		INNER JOIN Relab.ResultsMeasurements m on m.ResultID=r.ID 
		INNER JOIN Lookups ON m.MeasurementTypeID=Lookups.LookupID
		INNER JOIN #batches b ON tu.BatchID=b.ID
	WHERE r.TestID=@TestID AND 
		(
			ISNUMERIC(m.MeasurementValue)=1 OR LOWER(m.MeasurementValue) IN ('true', 'pass', 'fail', 'false')
		)
	GROUP BY m.MeasurementTypeID, Lookups.[Values]
	HAVING COUNT(DISTINCT b.ID) >= @Count
	
	DROP TABLE #batches
END
GO
GRANT EXECUTE ON Relab.remispGetMeasurementsByTest TO REMI
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Relab].[remispGetParametersByMeasurementTest]'
GO
create PROCEDURE Relab.remispGetParametersByMeasurementTest @BatchIDs NVARCHAR(MAX), @TestID INT, @MeasurementTypeID INT, @ParameterName NVARCHAR(255) = NULL
AS
BEGIN
	CREATE Table #batches(id int) 
	DECLARE @Count INT
	EXEC(@BatchIDs)
	
	SELECT @Count = COUNT(*) FROM #batches
	
	SELECT DISTINCT Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN @ParameterName IS NOT NULL THEN 'V' ELSE 'N' END) AS ParameterName
	FROM TestUnits tu
		INNER JOIN Relab.Results r ON r.TestUnitID=tu.ID
		INNER JOIN Relab.ResultsMeasurements m on m.ResultID=r.ID 
		INNER JOIN Relab.ResultsParameters p ON m.ID=p.ResultMeasurementID
		INNER JOIN #batches b ON tu.BatchID=b.ID
	WHERE m.MeasurementTypeID=@MeasurementTypeID AND r.TestID=@TestID AND m.Archived=0
		AND 
		(
			(@ParameterName IS NOT NULL AND Relab.ResultsParametersNameComma(p.ResultMeasurementID, 
											CASE WHEN @ParameterName IS NOT NULL THEN 'N' ELSE 'V' END)=@ParameterName
			) OR (@ParameterName IS NULL))
	GROUP BY p.ResultMeasurementID
	HAVING COUNT(DISTINCT b.ID) >= @Count	
	
	DROP TABLE #batches
END
GO
GRANT EXECUTE ON Relab.remispGetParametersByMeasurementTest TO REMI
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
create FUNCTION [Relab].[ResultsParametersNameComma](@ResultMeasurementID INT, @Display NVARCHAR(1))
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @listStr NVARCHAR(MAX)
	SELECT @listStr = COALESCE(@listStr+', ' ,'') + CASE WHEN @Display = 'V' THEN Value ELSE ParameterName END
	FROM Relab.ResultsParameters
	WHERE Relab.ResultsParameters.ResultMeasurementID=@ResultMeasurementID
	ORDER BY ParameterName ASC
	
	Return @listStr
END
GO
PRINT N'Creating [Relab].[remispGetUnitsByTestMeasurementParameters]'
GO
Create PROCEDURE Relab.remispGetUnitsByTestMeasurementParameters @BatchIDs NVARCHAR(MAX), @TestID INT, @MeasurementTypeID INT, @ParameterName NVARCHAR(255)=null, @ParameterValue NVARCHAR(255)=null
AS
BEGIN
	CREATE Table #batches(id int) 
	DECLARE @Count INT
	EXEC(@BatchIDs)
	
	SELECT DISTINCT tu.batchUnitNumber, tu.BatchID
	FROM TestUnits tu
		INNER JOIN Relab.Results r ON r.TestUnitID=tu.ID
		INNER JOIN Relab.ResultsMeasurements m on m.ResultID=r.ID 
		LEFT OUTER JOIN Relab.ResultsParameters p ON m.ID=p.ResultMeasurementID
		INNER JOIN #batches b ON tu.BatchID=b.ID
	WHERE m.MeasurementTypeID=@MeasurementTypeID AND r.TestID=@TestID AND m.Archived=0		
		AND 
		(
			(@ParameterName IS NOT NULL AND Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN @ParameterName IS NOT NULL THEN 'N' ELSE 'V' END)=@ParameterName
				AND 
				(
					(@ParameterValue IS NOT NULL AND  Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN @ParameterValue IS NOT NULL THEN 'V' ELSE 'N' END)=@ParameterValue) 
					OR 
					(@ParameterValue IS NULL)
				)
			) 
			OR 
			(@ParameterName IS NULL)
		)
	GROUP BY tu.BatchUnitNumber, tu.BatchID
	
	DROP TABLE #batches
END
GO
GRANT EXECUTE ON Relab.remispGetUnitsByTestMeasurementParameters TO REMI
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Relab].[ResultsXMLParametersComma]'
GO
create PROCEDURE Relab.remispGetUnitsByTestMeasurementParameters @BatchIDs NVARCHAR(MAX), @TestID INT, @MeasurementTypeID INT, @ParameterName NVARCHAR(255)=null, @ParameterValue NVARCHAR(255)=null
AS
BEGIN
	CREATE Table #batches(id int) 
	DECLARE @Count INT
	EXEC(@BatchIDs)
	
	SELECT DISTINCT tu.batchUnitNumber, tu.BatchID
	FROM TestUnits tu
		INNER JOIN Relab.Results r ON r.TestUnitID=tu.ID
		INNER JOIN Relab.ResultsMeasurements m on m.ResultID=r.ID 
		LEFT OUTER JOIN Relab.ResultsParameters p ON m.ID=p.ResultMeasurementID
		INNER JOIN #batches b ON tu.BatchID=b.ID
	WHERE m.MeasurementTypeID=@MeasurementTypeID AND r.TestID=@TestID 
		AND ((@ParameterName IS NOT NULL AND p.ParameterName=@ParameterName AND ((@ParameterValue IS NOT NULL AND p.Value=@ParameterValue) OR (@ParameterValue IS NULL))) OR (@ParameterName IS NULL))
		AND m.Archived=0
	GROUP BY tu.BatchUnitNumber, tu.BatchID
	
	DROP TABLE #batches
END
GO
GRANT EXECUTE ON Relab.remispGetUnitsByTestMeasurementParameters TO REMI
GO
CREATE FUNCTION [Relab].[ResultsXMLParametersComma](@Parameters XML)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @listStr NVARCHAR(MAX)
	
	SELECT @listStr = COALESCE(@listStr+', ' ,'') + CONVERT(VARCHAR(MAX), T.c.value('@ParameterName', 'nvarchar(max)')) + ': ' + CONVERT(VARCHAR(MAX), T.c.query('./child::text()'))
	FROM @Parameters.nodes('/child::*/child::*') T(c)	
	ORDER BY CONVERT(VARCHAR(MAX), T.c.value('@ParameterName', 'nvarchar(max)')), CONVERT(VARCHAR(MAX), T.c.query('./child::text()')) ASC
	
	Return @listStr
END


GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[ResultsParametersComma]'
GO

ALTER FUNCTION [Relab].[ResultsParametersComma](@ResultMeasurementID INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @listStr NVARCHAR(MAX)
	SELECT @listStr = COALESCE(@listStr+', ' ,'') + ParameterName + ': ' + Value
	FROM Relab.ResultsParameters
	WHERE Relab.ResultsParameters.ResultMeasurementID=@ResultMeasurementID
	ORDER BY ParameterName, Value ASC
	
	Return @listStr
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispResultsFileProcessing]'
GO
ALTER PROCEDURE Relab.remispResultsFileProcessing
AS
BEGIN
	BEGIN TRANSACTION

	BEGIN TRY
		DECLARE @ID INT
		DECLARE @idoc INT
		DECLARE @RowID INT
		DECLARE @xml XML
		DECLARE @xmlPart XML
		DECLARE @FinalResult BIT
		DECLARE @StartDate DATETIME
		DECLARE @EndDate NVARCHAR(MAX)
		DECLARE @Duration NVARCHAR(MAX)
		DECLARE @StationName NVARCHAR(400)
		DECLARE @MaxID INT
		DECLARE @VerNum INT
		DECLARE @ResultID INT
		DECLARE @ResultMeasurementID INT

		IF ((SELECT COUNT(*) FROM Relab.ResultsXML WHERE ISNULL(IsProcessed,0)=0)=0)
		BEGIN
			GOTO HANDLE_SUCCESS
			RETURN
		END
		
		SELECT TOP 1 @ID=ID, @xml = ResultXML, @VerNum = VerNum, @ResultID = ResultID
		FROM Relab.ResultsXML
		WHERE ISNULL(IsProcessed,0)=0
		ORDER BY ResultID, VerNum ASC

		SELECT @xmlPart = T.c.query('.') 
		FROM @xml.nodes('/TestResults/Header') T(c)
				
		select @EndDate = T.c.query('DateCompleted').value('.', 'nvarchar(max)'),
			@Duration = T.c.query('Duration').value('.', 'nvarchar(max)'),
			@StationName = T.c.query('StationName').value('.', 'nvarchar(400)')
		FROM @xmlPart.nodes('/Header') T(c)

		SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ' ')
		SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ':')
		SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ':')
				
		If (CHARINDEX('.', @Duration) > 0)
			SET @Duration = SUBSTRING(@Duration, 1, CHARINDEX('.', @Duration)-1)
		
		SET @StartDate=dateadd(s,-datediff(s,0,convert(DATETIME,@Duration)), CONVERT(DATETIME, @EndDate))
	
		PRINT 'INSERT Lookups UnitType'
		SELECT DISTINCT (1) AS LookupID, T.c.query('Units').value('.', 'nvarchar(max)') AS UnitType, 1 AS Active
		INTO #LookupsUnitType
		FROM @xml.nodes('/TestResults/Measurements/Measurement') T(c)
		WHERE LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('Units').value('.', 'nvarchar(max)')))) NOT IN ( (SELECT [Values] FROM Lookups WHERE Type='UnitType')) 
			AND CONVERT(VARCHAR(MAX), T.c.query('Units').value('.', 'nvarchar(max)')) NOT IN ('N/A')
		
		SELECT @MaxID = MAX(LookupID)+1 FROM Lookups
		
		INSERT INTO Lookups (LookupID, Type,[Values], IsActive)
		SELECT (ROW_NUMBER() OVER (ORDER BY LookupID)) + @MaxID AS LookupID, 'UnitType' AS Type, UnitType AS [Values], Active
		FROM #LookupsUnitType
		
		DROP TABLE #LookupsUnitType
		
		PRINT 'INSERT Lookups MeasurementType'
		SELECT DISTINCT (1) AS LookupID, T.c.query('MeasurementName').value('.', 'nvarchar(max)') AS MeasurementType, 1 AS Active
		INTO #LookupsMeasurementType
		FROM @xml.nodes('/TestResults/Measurements/Measurement') T(c)
		WHERE LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('MeasurementName').value('.', 'nvarchar(max)')))) NOT IN ( (SELECT [Values] FROM Lookups WHERE Type='MeasurementType')) 
			AND CONVERT(VARCHAR(MAX), T.c.query('MeasurementName').value('.', 'nvarchar(max)')) NOT IN ('N/A')
		
		SELECT @MaxID = MAX(LookupID)+1 FROM Lookups
		
		INSERT INTO Lookups (LookupID, Type, [Values], IsActive)
		SELECT (ROW_NUMBER() OVER (ORDER BY LookupID)) + @MaxID AS LookupID, 'MeasurementType' AS Type, MeasurementType AS [Values], Active
		FROM #LookupsMeasurementType
		
		DROP TABLE #LookupsMeasurementType
		
		PRINT 'Load Measurements into temp table'
		SELECT  ROW_NUMBER() OVER (ORDER BY T.c) AS RowID, T.c.query('.') AS value 
		INTO #temp2
		FROM @xml.nodes('/TestResults/Measurements/Measurement') T(c)

		SELECT @RowID = MIN(RowID) FROM #temp2
		
		WHILE (@RowID IS NOT NULL)
		BEGIN
			SELECT @xmlPart  = value FROM #temp2 WHERE RowID=@RowID	

			select l2.LookupID AS MeasurementTypeID,
				T.c.query('LowerLimit').value('.', 'nvarchar(max)') AS LowerLimit,
				T.c.query('UpperLimit').value('.', 'nvarchar(max)') AS UpperLimit,
				T.c.query('MeasuredValue').value('.', 'nvarchar(max)') AS MeasurementValue,
				(CASE WHEN T.c.query('PassFail').value('.', 'nvarchar(max)') = 'Pass' THEN 1 ELSE 0 END) AS PassFail,
				l.LookupID AS UnitTypeID,
				T.c.query('FileName').value('.', 'nvarchar(max)') AS [FileName], 
				[Relab].[ResultsXMLParametersComma] ((select T.c.query('.') from @xmlPart.nodes('/Measurement/Parameters') T(c))) AS Parameters
			INTO #measurement
			FROM @xmlPart.nodes('/Measurement') T(c)
				LEFT OUTER JOIN Lookups l ON l.Type='UnitType' AND l.[Values]=LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('Units').value('.', 'nvarchar(max)'))))
				LEFT OUTER JOIN Lookups l2 ON l2.Type='MeasurementType' AND l2.[Values]=LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('MeasurementName').value('.', 'nvarchar(max)'))))

			IF (@VerNum = 1)
			BEGIN
				PRINT 'INSERT Measurements'
				INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, [File], PassFail, ReTestNum, Archived, XMLID)
				SELECT @ResultID As ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementTypeID, FileName AS [File], CONVERT(BIT, PassFail), 1, 0, @ID
				FROM #measurement
				
				SELECT @ResultMeasurementID = MAX(ID)
				FROM Relab.ResultsMeasurements
				WHERE ResultID=@ResultID 
				
				PRINT 'INSERT Parameters'
				INSERT INTO Relab.ResultsParameters (ResultMeasurementID, ParameterName, Value)
				SELECT @ResultMeasurementID AS ResultMeasurementID, T.c.value('@ParameterName','nvarchar(max)') AS ParameterName, T.c.query('.').value('.', 'nvarchar(max)') AS Value
				FROM @xmlPart.nodes('/Measurement/Parameters/Parameter') T(c)
			END
			ELSE
			BEGIN
				DECLARE @MeasurementTypeID INT
				DECLARE @Parameters NVARCHAR(MAX)
				DECLARE @MeasuredValue NVARCHAR(MAX)
				SELECT @MeasurementTypeID=MeasurementTypeID, @Parameters=Parameters, @MeasuredValue=MeasurementValue FROM #measurement

				IF EXISTS (SELECT 1 FROM Relab.ResultsMeasurements WHERE ResultID=@ResultID AND MeasurementTypeID=@MeasurementTypeID AND ISNULL(Relab.ResultsParametersComma(ID),'') = ISNULL(@Parameters,'') AND MeasurementValue <> @MeasuredValue)
				--That result has that measurement type and exact parameters but measured value is different
				BEGIN
					DECLARE @ReTestNum INT
					SELECT @ReTestNum=MAX(reTestNum)+1 
					FROM Relab.ResultsMeasurements 
					WHERE ResultID=@ResultID AND MeasurementTypeID=@MeasurementTypeID AND ISNULL(Relab.ResultsParametersComma(ID), '') = ISNULL(@Parameters, '')
					
					PRINT 'INSERT Measurements'
					INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, [File], PassFail, ReTestNum, Archived, XMLID)
					SELECT @ResultID As ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementTypeID, FileName AS [File], CONVERT(BIT, PassFail), @ReTestNum, 0, @ID
					FROM #measurement
					
					SELECT @ResultMeasurementID = MAX(ID)
					FROM Relab.ResultsMeasurements
					WHERE ResultID=@ResultID 
					
					PRINT 'INSERT Parameters'
					INSERT INTO Relab.ResultsParameters (ResultMeasurementID, ParameterName, Value)
					SELECT @ResultMeasurementID AS ResultMeasurementID, T.c.value('@ParameterName','nvarchar(max)') AS ParameterName, T.c.query('.').value('.', 'nvarchar(max)') AS Value
					FROM @xmlPart.nodes('/Measurement/Parameters/Parameter') T(c)
					
					UPDATE Relab.ResultsMeasurements 
					SET Archived=1 
					WHERE ResultID=@ResultID AND MeasurementTypeID=@MeasurementTypeID AND Relab.ResultsParametersComma(ID) = @Parameters AND ReTestNum < @ReTestNum
				END
				ELSE IF NOT EXISTS (SELECT 1 FROM Relab.ResultsMeasurements WHERE ResultID=@ResultID AND MeasurementTypeID=@MeasurementTypeID AND Relab.ResultsParametersComma(ID) = @Parameters)
				--That result does not have that measurement type and exact parameters
				BEGIN
					PRINT 'INSERT Measurements'
					INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, [File], PassFail, ReTestNum, Archived, XMLID)
					SELECT @ResultID As ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementTypeID, FileName AS [File], CONVERT(BIT, PassFail), 1, 0, @ID
					FROM #measurement
					
					SELECT @ResultMeasurementID = MAX(ID)
					FROM Relab.ResultsMeasurements
					WHERE ResultID=@ResultID 
					
					PRINT 'INSERT Parameters'
					INSERT INTO Relab.ResultsParameters (ResultMeasurementID, ParameterName, Value)
					SELECT @ResultMeasurementID AS ResultMeasurementID, T.c.value('@ParameterName','nvarchar(max)') AS ParameterName, T.c.query('.').value('.', 'nvarchar(max)') AS Value
					FROM @xmlPart.nodes('/Measurement/Parameters/Parameter') T(c)
				END
			END
			
			DROP TABLE #measurement
		
			SELECT @RowID = MIN(RowID) FROM #temp2 WHERE RowID > @RowID
		END
		
		PRINT 'Update Result'
		UPDATE Relab.ResultsXML 
		SET EndDate=CONVERT(DATETIME, @EndDate), StartDate =@StartDate, IsProcessed=1, StationName=@StationName
		WHERE ID=@ID
		
		UPDATE Relab.Results
		SET PassFail=CASE WHEN (SELECT COUNT(*) FROM Relab.ResultsMeasurements WHERE ResultID=@ResultID AND Archived=0 AND PassFail=0) > 0 THEN 0 ELSE 1 END
		WHERE ID=@ResultID
	
		DROP TABLE #temp2

		GOTO HANDLE_SUCCESS
	END TRY
	BEGIN CATCH
		  SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_SEVERITY() AS ErrorSeverity, ERROR_STATE() as ErrorState, ERROR_PROCEDURE() as ErrorProcedure, ERROR_LINE() as ErrorLine, ERROR_MESSAGE() as ErrorMessage

		  GOTO HANDLE_ERROR
	END CATCH

	HANDLE_SUCCESS:
		IF @@TRANCOUNT > 0
		BEGIN
			PRINT 'COMMIT TRANSACTION'
			COMMIT TRANSACTION
		END
		RETURN	
	
	HANDLE_ERROR:
		IF @@TRANCOUNT > 0
		BEGIN
			PRINT 'ROLLBACK TRANSACTION'
			ROLLBACK TRANSACTION
		END
		RETURN
END
GO
GRANT EXECUTE ON Relab.remispResultsFileProcessing TO REMI
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispResultsSummary]'
GO
ALTER PROCEDURE [Relab].[remispResultsSummary] @BatchID INT
AS
BEGIN
	SELECT r.ID, ts.TestStageName, t.TestName, tu.BatchUnitNumber, CASE WHEN PassFail=1 THEN 'Pass' ELSE 'Fail' END AS PassFail
	FROM Relab.Results r
		INNER JOIN TestStages ts ON r.TestStageID=ts.ID
		INNER JOIN Tests t ON r.TestID=t.ID
		INNER JOIN TestUnits tu ON tu.ID=r.TestUnitID
	WHERE tu.BatchID=@BatchID
	ORDER BY tu.BatchUnitNumber, ts.TestStageName, t.TestName
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispResultsSummaryExport]'
GO
ALTER PROCEDURE [Relab].[remispResultsSummaryExport] @BatchID INT, @ResultID INT = NULL
AS
BEGIN
	SELECT b.QRANumber, tu.BatchUnitNumber As Unit, tu.BSN, ts.TestStageName AS TestStage, t.TestName, 
		lm.[Values] AS MeasurementType, m.LowerLimit, m.UpperLimit, m.MeasurementValue AS Result, lu.[Values] AS Units,
		CASE WHEN m.PassFail=1 THEN 'Pass' ELSE 'Fail' END AS PassFail, Relab.ResultsParametersComma(m.ID) AS Parameters, m.ReTestNum, m.Archived
	FROM Relab.Results r
		INNER JOIN TestStages ts ON r.TestStageID=ts.ID
		INNER JOIN Tests t ON r.TestID=t.ID
		INNER JOIN TestUnits tu ON tu.ID=r.TestUnitID
		INNER JOIN Batches b ON b.ID=tu.BatchID
		INNER JOIN Relab.ResultsMeasurements m ON m.ResultID=r.ID
		INNER JOIN Lookups lm ON m.MeasurementTypeID=lm.LookupID
		INNER JOIN Lookups lu ON m.MeasurementUnitTypeID=lu.LookupID
	WHERE b.ID=@BatchID AND (@ResultID IS NULL OR (@ResultID IS NOT NULL AND r.ID=@ResultID))
	ORDER BY tu.BatchUnitNumber, ts.TestStageName, TestName
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispYourBatchesGetActiveBatches]'
GO
ALTER PROCEDURE [dbo].[remispYourBatchesGetActiveBatches] @UserID int, @ByPassProductCheck INT = 0, @Year INT = 0, @OnlyShowQRAWithResults INT = 0
AS	
	SELECT BatchesRows.ID, BatchesRows.ProductGroupName,BatchesRows.QRANumber, (BatchesRows.QRANumber + ' ' + BatchesRows.ProductGroupName) AS Name
	FROM     
		(
			SELECT p.ProductGroupName,b.QRANumber, b.ID
				FROM Batches as b
				inner join Products p on p.ID=b.ProductID
			WHERE ( 
					(@Year = 0 AND BatchStatus NOT IN(5,7))
					OR
					(@Year > 0 AND b.QRANumber LIKE 'QRA-' + RIGHT(CONVERT(NVARCHAR, @Year), 2) + '%')
				  )
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
				AND (@OnlyShowQRAWithResults = 0 OR (@OnlyShowQRAWithResults = 1 AND b.ID IN (SELECT tu.BatchID FROM Relab.Results r INNER JOIN TestUnits tu ON tu.ID=r.TestUnitID)))
		) AS BatchesRows
	ORDER BY BatchesRows.QRANumber
	RETURN
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispResultMeasurements]'
GO
ALTER PROCEDURE [Relab].[remispResultMeasurements] @ResultID INT, @OnlyFails INT = 0, @IncludeArchived INT = 0
AS
BEGIN
	SET NOCOUNT ON
	SELECT rm.ID, lt.[Values] As MeasurementType, LowerLimit, UpperLimit, MeasurementValue, lu.[Values] As UnitType, 
		CASE WHEN PassFail=1 THEN 'Pass' ELSE 'Fail' END AS PassFail,
		Relab.ResultsParametersComma(rm.ID) AS [Parameters], rm.MeasurementTypeID, rm.ReTestNum, rm.Archived, rm.XMLID, 
		(SELECT MAX(VerNum) FROM Relab.ResultsXML WHERE ResultID=rm.ResultID) AS MaxVersion
	FROM Relab.ResultsMeasurements rm
		LEFT OUTER JOIN Lookups lu ON lu.Type='UnitType' AND lu.LookupID=rm.MeasurementUnitTypeID
		LEFT OUTER JOIN Lookups lt ON lt.Type='MeasurementType' AND lt.LookupID=rm.MeasurementTypeID
	WHERE ResultID=@ResultID AND ((@IncludeArchived = 0 AND rm.Archived=0) OR (@IncludeArchived=1)) AND ((@OnlyFails = 1 AND PassFail=0) OR (@OnlyFails = 0))
	ORDER BY lt.[Values],Relab.ResultsParametersComma(rm.ID), rm.ReTestNum, rm.Archived
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispResultMeasurements] TO Remi
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispResultsFileUpload]'
GO
ALTER PROCEDURE Relab.remispResultsFileUpload @XML AS NTEXT, @LossFile AS NTEXT = NULL
AS
BEGIN
	DECLARE @TestStageID INT
	DECLARE @TestID INT
	DECLARE @TestUnitID INT
	DECLARE @VerNum INT
	DECLARE @ResultID INT
	DECLARE @ResultsXML XML
	DECLARE @ResultsLossFile XML

	DECLARE @TestName NVARCHAR(400)
	DECLARE @TestStageName NVARCHAR(400)
	DECLARE @QRANumber NVARCHAR(11)
	DECLARE @JobName NVARCHAR(400)
	DECLARE @TestUnitNumber INT

	SELECT @ResultsXML = CONVERT(XML, @XML)
	SELECT @ResultsLossFile = CONVERT(XML, @LossFile)

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
	
	SELECT @ResultID=ID FROM Relab.Results WHERE TestStageID=@TestStageID AND TestID=@TestID AND TestUnitID=@TestUnitID
	
	IF (@ResultID IS NULL OR @ResultID = 0)
	BEGIN
		INSERT INTO Relab.Results (TestStageID, TestID,TestUnitID)
		VALUES (@TestStageID, @TestID, @TestUnitID)

		SELECT @ResultID=ID FROM Relab.Results WHERE TestStageID=@TestStageID AND TestID=@TestID AND TestUnitID=@TestUnitID
		
		INSERT INTO Relab.ResultsXML (ResultID, ResultXML, VerNum, LossFile)
		VALUES (@ResultID, @XML, 1, @ResultsLossFile)
	END
	ELSE
	BEGIN
		SELECT @VerNum = ISNULL(COUNT(*), 0)+1 FROM Relab.ResultsXML WHERE ResultID=@ResultID
		
		INSERT INTO Relab.ResultsXML (ResultID, ResultXML, VerNum, LossFile)
		VALUES (@ResultID, @XML, @VerNum, @ResultsLossFile)

	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispResultsGraph]'
GO
ALTER PROCEDURE Relab.remispResultsGraph @MeasurementTypeID INT, @batchIDs NVARCHAR(MAX), @UnitIDs NVARCHAR(MAX), @TestID INT, @ParameterName NVARCHAR(255)=NULL, @ParameterValue NVARCHAR(250)=NULL, @ShowUpperLowerLimits INT = 1, @Xaxis INT, @PlotValue INT
AS
BEGIN
	DECLARE @LoopValue NVARCHAR(500)
	DECLARE @ID INT
	DECLARE @query VARCHAR(MAX)
	DECLARE @query2 VARCHAR(MAX)
	CREATE TABLE #batches (id INT)
	CREATE TABLE #units (id INT)
	CREATE TABLE #Graph (RowID INT, YAxis NVARCHAR(500), XAxis NVARCHAR(500), LoopValue NVARCHAR(500), LowerLimit NVARCHAR(255), UpperLimit NVARCHAR(255))
	EXEC (@batchIDs)
	EXEC (@UnitIDs)
	SET @query = ''	
	SET @query2 = ''
	
	/*@Xaxis
	Units: 0
	Stages: 1
	Parameter: 2
	*/
	/*@PlotValue
	Units: 0
	Stages: 1
	*/
	
	IF (@Xaxis=0)
	BEGIN
		SET @query = 'INSERT INTO #Graph SELECT ROW_NUMBER() OVER (ORDER BY rm.MeasurementValue) AS RowID, ROUND(rm.MeasurementValue, 3) AS YAxis, 
		CASE WHEN '''+ ISNULL(@ParameterName,'')+''' = '''' THEN CONVERT(VARCHAR,tu.BatchUnitNumber) WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN CONVERT(VARCHAR,tu.BatchUnitNumber) ELSE CONVERT(VARCHAR,tu.BatchUnitNumber) +'': '' + Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN ''V'' ELSE ''N'' END) END AS XAxis, 
		ts.TestStageName AS LoopValue, rm.LowerLimit, rm.UpperLimit '		
	END
	ELSE IF (@Xaxis=1)
	BEGIN
		SET @query = 'INSERT INTO #Graph SELECT ROW_NUMBER() OVER (ORDER BY rm.MeasurementValue) AS RowID, ROUND(rm.MeasurementValue, 3) AS YAxis, 
		CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN CONVERT(VARCHAR,ts.TestStageName) ELSE CONVERT(VARCHAR,ts.TestStageName) +'': '' + Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN ''V'' ELSE ''N'' END) END AS XAxis, 
		tu.BatchUnitNumber AS LoopValue, rm.LowerLimit, rm.UpperLimit '		
	END
	ELSE IF (@Xaxis=2 AND @PlotValue = 1)
	BEGIN
		SET @query = 'INSERT INTO #Graph SELECT ROW_NUMBER() OVER (ORDER BY rm.MeasurementValue) AS RowID, ROUND(rm.MeasurementValue, 3) AS YAxis,
		CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END) ELSE Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END) +'': '' + Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN ''V'' ELSE ''N'' END) END AS XAxis, 
		ts.TestStageName AS LoopValue, rm.LowerLimit, rm.UpperLimit '
	END
	ELSE IF (@Xaxis=2 AND @PlotValue = 0)
	BEGIN
		SET @query = 'INSERT INTO #Graph SELECT ROW_NUMBER() OVER (ORDER BY rm.MeasurementValue) AS RowID, ROUND(rm.MeasurementValue, 3) AS YAxis, Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END) AS XAxis, tu.BatchUnitNumber AS LoopValue, rm.LowerLimit, rm.UpperLimit '
	END
	
	SET @query += 'FROM Relab.Results r
		INNER JOIN TestUnits tu ON r.TestUnitID=tu.ID
		INNER JOIN Relab.ResultsMeasurements rm ON r.ID=rm.ResultID
		INNER JOIN #batches b ON tu.batchID=b.ID
		INNER JOIN #units u ON u.id=tu.BatchUnitNumber
		INNER JOIN TestStages ts ON r.TestStageID=ts.ID
		LEFT OUTER JOIN Relab.ResultsParameters p ON p.ResultMeasurementID=rm.ID
	WHERE rm.MeasurementTypeID='+CONVERT(VARCHAR,@MeasurementTypeID)+' AND r.TestID='+CONVERT(VARCHAR,@TestID)+' AND ISNUMERIC(MeasurementValue)=1 AND MeasurementValue IS NOT NULL '
	
	IF (@Xaxis=2)
		BEGIN
			IF (@ParameterName IS NOT NULL)
				SET @query2 = ' AND (Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterName,'')+''' <> '''' THEN ''N'' ELSE ''V'' END)='''+ ISNULL(@ParameterName,'')+''') '
			
			IF (@ParameterValue IS NOT NULL)
				SET @query2 = ' AND (Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END)='''+ ISNULL(@ParameterValue,'')+''') '
		END
	ELSE
		BEGIN
			IF (@ParameterName IS NOT NULL)
				SET @query2 = ' AND (Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterName,'')+''' <> '''' THEN ''N'' ELSE ''V'' END)='''+ ISNULL(@ParameterName,'')+''') '
			IF (@ParameterValue IS NOT NULL)
				SET @query2 = ' AND (Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END)='''+ ISNULL(@ParameterValue,'')+''') '
		END

	SET @query2 += ' AND ISNULL(rm.Archived,0)=0 ORDER BY LoopValue'
	
	print @query
	print @query2
	
	EXEC(@query + @query2)
	
	UPDATE #Graph SET YAxis=1 WHERE YAxis IN ('True','Pass')
	UPDATE #Graph SET YAxis=0 WHERE YAxis IN ('Fail','False')	
	
	DECLARE select_cursor CURSOR FOR SELECT DISTINCT LoopValue FROM #Graph
	OPEN select_cursor

	FETCH NEXT FROM select_cursor INTO @LoopValue

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT DISTINCT YAxis, XAxis, LoopValue, LowerLimit, UpperLimit FROM #Graph WHERE LoopValue=@LoopValue
		FETCH NEXT FROM select_cursor INTO @LoopValue
	END
	
	CLOSE select_cursor
	DEALLOCATE select_cursor
	
	
	select UpperLimit, LowerLimit, COUNT(*) as va
	into #GraphLimits
	FROM #Graph
	GROUP BY UpperLimit, LowerLimit
	
	IF (@@ROWCOUNT = 1)
	BEGIN
		IF (@ShowUpperLowerLimits = 1)
		BEGIN
			SELECT DISTINCT ROUND(Lowerlimit, 3) AS YAxis, XAxis, (LoopValue + ' Lower Specification Limit') AS LoopValue 
			FROM #Graph
			WHERE LowerLimit IS NOT NULL AND ISNUMERIC(LowerLimit)=1 AND LoopValue = (SELECT MIN(LoopValue) FROM #Graph)
			
			SELECT DISTINCT ROUND(Upperlimit, 3) AS YAxis, XAxis, (LoopValue + ' Upper Specification Limit') AS LoopValue 
			FROM #Graph
			WHERE LowerLimit IS NOT NULL AND ISNUMERIC(LowerLimit)=1 AND LoopValue = (SELECT MIN(LoopValue) FROM #Graph)
		END	
	END
	
	DROP TABLE #Graph
	DROP TABLE #batches
	DROP TABLE #units
	DROP TABLE #GraphLimits
END
GO
GRANT EXECUTE ON Relab.remispResultsGraph TO REMI
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding constraints to [Relab].[ResultsMeasurements]'
GO
ALTER TABLE [Relab].[ResultsMeasurements] ADD CONSTRAINT [DF__ResultsMe__Archi__7F8BD5E2] DEFAULT ((0)) FOR [Archived]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding constraints to [Relab].[ResultsXML]'
GO
ALTER TABLE [Relab].[ResultsXML] ADD CONSTRAINT [DF__ResultsXM__isPro__7DA38D70] DEFAULT ((0)) FOR [isProcessed]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [Relab].[remispResultVersions]'
GO
GRANT EXECUTE ON  [Relab].[remispResultVersions] TO [remi]
GO
PRINT N'Altering permissions on [Relab].[remispGetTestsByBatches]'
GO
GRANT EXECUTE ON  [Relab].[remispGetTestsByBatches] TO [remi]
GO
PRINT N'Altering permissions on [Relab].[remispGetMeasurementsByTest]'
GO
GRANT EXECUTE ON  [Relab].[remispGetMeasurementsByTest] TO [remi]
GO
PRINT N'Altering permissions on [Relab].[remispGetParametersByMeasurementTest]'
GO
GRANT EXECUTE ON  [Relab].[remispGetParametersByMeasurementTest] TO [remi]
GO
PRINT N'Altering permissions on [Relab].[remispGetUnitsByTestMeasurementParameters]'
GO
GRANT EXECUTE ON  [Relab].[remispGetUnitsByTestMeasurementParameters] TO [remi]
GO
grant execute on relab.ResultsParametersNameComma to REMI
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispOverallResultsSummary]'
GO
ALTER PROCEDURE [Relab].[remispOverallResultsSummary] @BatchID INT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @query VARCHAR(8000)
	DECLARE @query2 VARCHAR(8000)
	DECLARE @query3 VARCHAR(8000)
	DECLARE @QRANumber NVARCHAR(11)
	DECLARE @RowID INT
	DECLARE @BatchUnitNumber INT
	DECLARE @StageCount INT
	CREATE TABLE #results (TestID INT)
	
	SELECT @QRANumber = QRANumber FROM Batches WHERE ID=@BatchID
	SELECT @StageCount = COUNT(DISTINCT TSName) FROM dbo.vw_GetTaskInfo where BatchID=@BatchID and Processorder > 0 AND Testtype=1
	SET @query2 = ''
	SET @query = ''
	SET @query3 =''
	
	EXECUTE ('ALTER TABLE #results ADD [' + @QRANumber + '] NVARCHAR(400) NULL ALTER TABLE #results ADD Completed NVARCHAR(3) NULL ALTER TABLE #results ADD [Pass/Fail] NVARCHAR(3) NULL')
	
	SET @query = 'INSERT INTO #results
	SELECT DISTINCT TestID, TName AS [' + @QRANumber + '],
		(
			CASE WHEN
				(
					SELECT COUNT(DISTINCT u.ID)
					FROM Relab.Results r 
						INNER JOIN TestUnits u ON u.ID=r.TestUnitID 
					WHERE r.TestID=i.TestID AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+'
				) = '+CONVERT(VARCHAR,@StageCount)+' THEN ''Y'' ELSE ''N'' END
		) AS Completed,
		(
			CASE
				WHEN 
				(
					SELECT TOP 1 1 
					FROM Relab.Results r
						INNER JOIN TestUnits u ON u.ID=r.TestUnitID 
					WHERE r.TestID=i.TestID AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+'
				) IS NULL THEN ''N/A''
				WHEN
				(
					SELECT COUNT(*)
					FROM Relab.Results r 
						INNER JOIN TestUnits u ON u.ID=r.TestUnitID 
					WHERE r.TestID=i.TestID AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+' AND PassFail=1
				) = 
				(
					SELECT COUNT(*)
					FROM Relab.Results r 
						INNER JOIN TestUnits u ON u.ID=r.TestUnitID 
					WHERE r.TestID=i.TestID AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+'
				) THEN ''P'' 
				ELSE ''F'' END
		) AS [Pass/Fail] '
		
	SET @query2 = ' FROM 
	TestUnits tu 
		INNER JOIN dbo.vw_GetTaskInfo i ON tu.BatchID=i.batchid
	WHERE processorder > 0 AND testtype=1 AND tu.BatchID='+CONVERT(VARCHAR,@BatchID)+'
	ORDER BY TName'
	EXECUTE (@query + @query2)
		
	SELECT ROW_NUMBER() OVER (ORDER BY tu.ID) AS RowID, tu.BatchUnitNumber, tu.ID
	INTO #units
	FROM TestUnits tu
	WHERE BatchID=@BatchID

	SELECT @RowID = MIN(RowID) FROM #units
			
	WHILE (@RowID IS NOT NULL)
	BEGIN
		SELECT @BatchUnitNumber=BatchUnitNumber FROM #units WHERE RowID=@RowID
		
		EXECUTE ('ALTER TABLE #results ADD [' + @BatchUnitNumber + '] NVARCHAR(3) NULL')
		
		SET @query3 = 'UPDATE #Results SET [' + CONVERT(VARCHAR,@BatchUnitNumber) + '] = (
		CASE
			WHEN 
			(
				SELECT TOP 1 1
				FROM Relab.Results r
					INNER JOIN TestUnits u ON u.ID=r.TestUnitID 
				WHERE r.TestID=#Results.TestID AND u.ID=r.TestUnitID AND u.BatchUnitNumber =' + CONVERT(VARCHAR,@BatchUnitNumber) + ' AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+'
			) IS NULL THEN ''N/A''
			WHEN
			(
				SELECT COUNT(*)
				FROM Relab.Results r 
					INNER JOIN TestUnits u ON u.ID=r.TestUnitID 
				WHERE r.TestID=#Results.TestID AND u.ID=r.TestUnitID AND PassFail=1 AND u.BatchUnitNumber =' + CONVERT(VARCHAR,@BatchUnitNumber) + ' AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+'
			) = 
			(
				SELECT COUNT(*)
				FROM Relab.Results r 
					INNER JOIN TestUnits u ON u.ID=r.TestUnitID 
				WHERE r.TestID=#Results.TestID AND u.ID=r.TestUnitID AND u.BatchUnitNumber =' + CONVERT(VARCHAR,@BatchUnitNumber) + 'AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+'
			) THEN ''P'' ELSE ''F'' END
		)'
		
		EXECUTE (@query3)
		
		SELECT @RowID = MIN(RowID) FROM #units WHERE RowID > @RowID
	END
	
	SELECT * FROM #results

	DROP TABLE #units
	DROP TABLE #results
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispOverallResultsSummary] TO Remi
GO

IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
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