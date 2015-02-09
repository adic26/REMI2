/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 2/6/2015 12:14:06 PM

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
PRINT N'Altering [Relab].[remispResultsFileProcessing]'
GO
ALTER PROCEDURE [Relab].[remispResultsFileProcessing]
AS
BEGIN
	BEGIN TRANSACTION

	DECLARE @ID INT
	DECLARE @idoc INT
	DECLARE @RowID INT
	DECLARE @InfoRowID INT
	DECLARE @MaxID INT
	DECLARE @VerNum INT
	DECLARE @ResultID INT
	DECLARE @UnitID INT
	DECLARE @Val INT
	DECLARE @JobID INT
	DECLARE @FunctionalType INT
	DECLARE @UnitTypeLookupTypeID INT
	DECLARE @MeasurementTypeLookupTypeID INT
	DECLARE @TestStageID INT
	DECLARE @BaselineID INT
	DECLARE @TestID INT
	DECLARE @xml XML
	DECLARE @xmlPart XML
	DECLARE @LookupTypeName NVARCHAR(100)
	DECLARE @LookupTypeNameID INT
	DECLARE @TrackingLocationTypeName NVARCHAR(200)
	DECLARE @TestStageName NVARCHAR(400)
	DECLARE @DegradationVal DECIMAL(10,3)
	SET @ID = NULL
	CREATE TABLE #files ([FileName] NVARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS)

	BEGIN TRY
		IF ((SELECT COUNT(*) FROM Relab.ResultsXML x WHERE ISNULL(ErrorOccured, 0) = 0 AND ISNULL(IsProcessed,0)=0)=0)
		BEGIN
			PRINT 'No Files To Process'
			GOTO HANDLE_SUCCESS
			RETURN
		END
		ELSE
		BEGIN
			SET NOCOUNT ON

			SELECT @MeasurementTypeLookupTypeID=LookupTypeID FROM LookupType WHERE Name='MeasurementType'
			SELECT @UnitTypeLookupTypeID=LookupTypeID FROM LookupType WHERE Name='UnitType'
			
			SELECT @Val = COUNT(*) FROM Relab.ResultsXML x WHERE ISNULL(isProcessed,0)=0 AND ISNULL(ErrorOccured, 0) = 0
			
			SELECT TOP 1 @ID=x.ID, @xml = x.ResultXML, @VerNum = x.VerNum, @ResultID = x.ResultID
			FROM Relab.ResultsXML x
			WHERE ISNULL(IsProcessed,0)=0 AND ISNULL(ErrorOccured, 0) = 0
			ORDER BY ResultID, VerNum ASC
			
			SELECT @TestID = r.TestID , @TestStageName = ts.TestStageName, @UnitID = r.TestUnitID, @TestStageID  = r.TestStageID, @JobID = ts.JobID
			FROM Relab.Results r
				INNER JOIN TestStages ts ON r.TestStageID=ts.ID
			WHERE r.ID=@ResultID
			
			SELECT @BaselineID = ts.ID
			FROM TestStages ts
			WHERE JobID=@JobID AND LTRIM(RTRIM(LOWER(ts.TestStageName)))='baseline'
			
			SELECT @TrackingLocationTypeName =tlt.TrackingLocationTypeName, @DegradationVal = t.DegradationVal
			FROM Tests t
				INNER JOIN TrackingLocationsForTests tlft ON tlft.TestID=t.ID
				INNER JOIN TrackingLocationTypes tlt ON tlft.TrackingLocationtypeID=tlt.ID
			WHERE t.ID=@TestID
			
			PRINT '# Files To Process: ' + CONVERT(VARCHAR, @Val)
			PRINT 'XMLID: ' + CONVERT(VARCHAR, @ID)
			PRINT 'ResultID: ' + CONVERT(VARCHAR, @ResultID)
			PRINT 'TestID: ' + CONVERT(VARCHAR, @TestID)
			PRINT 'UnitID: ' + CONVERT(VARCHAR, @UnitID)
			PRINT 'JobID: ' + CONVERT(VARCHAR, @JobID)
			PRINT 'TestStageID: ' + CONVERT(VARCHAR, @TestStageID)
			PRINT 'TestStageName: ' + CONVERT(VARCHAR, @TestStageName)
			PRINT 'TrackingLocationTypeName: ' + CONVERT(VARCHAR, @TrackingLocationTypeName)
			PRINT 'DegradationVal: ' + CONVERT(VARCHAR, ISNULL(@DegradationVal,0.0))
			PRINT 'BaselineID: ' + CONVERT(VARCHAR, @BaselineID)

			SELECT @xmlPart = T.c.query('.') 
			FROM @xml.nodes('/TestResults/Header') T(c)
					
			select @FunctionalType = T.c.query('FunctionalType').value('.', 'nvarchar(400)')
			FROM @xmlPart.nodes('/Header') T(c)

			IF (@TrackingLocationTypeName IS NOT NULL And @TrackingLocationTypeName = 'Functional Station' AND @FunctionalType <> 0)
			BEGIN
				PRINT @FunctionalType
				IF (@FunctionalType = 0)
				BEGIN
					SET @LookupTypeName = 'MeasurementType'
				END
				ELSE IF (@FunctionalType = 1)
				BEGIN
					SET @LookupTypeName = 'SFIFunctionalMatrix'
				END
				ELSE IF (@FunctionalType = 2)
				BEGIN
					SET @LookupTypeName = 'MFIFunctionalMatrix'
				END
				ELSE IF (@FunctionalType = 3)
				BEGIN
					SET @LookupTypeName = 'AccFunctionalMatrix'
				END
				
				PRINT 'Test IS ' + @LookupTypeName
			END
			ELSE
			BEGIN
				SET @LookupTypeName = 'MeasurementType'
				
				PRINT 'INSERT Lookups UnitType'
				SELECT DISTINCT (1) AS LookupID, T.c.query('Units').value('.', 'nvarchar(max)') AS UnitType, 1 AS Active
				INTO #LookupsUnitType
				FROM @xml.nodes('/TestResults/Measurements/Measurement') T(c)
				WHERE LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('Units').value('.', 'nvarchar(max)')))) NOT IN ( (SELECT [Values] FROM Lookups WHERE LookupTypeID=@UnitTypeLookupTypeID)) 
					AND CONVERT(VARCHAR(MAX), T.c.query('Units').value('.', 'nvarchar(max)')) NOT IN ('N/A')
				
				SELECT @MaxID = MAX(LookupID)+1 FROM Lookups
				
				INSERT INTO Lookups (LookupID, LookupTypeID,[Values], IsActive)
				SELECT (ROW_NUMBER() OVER (ORDER BY LookupID)) + @MaxID AS LookupID, @UnitTypeLookupTypeID AS LookupTypeID, UnitType AS [Values], Active
				FROM #LookupsUnitType
				
				DROP TABLE #LookupsUnitType
			
				PRINT 'INSERT Lookups MeasurementType'
				SELECT DISTINCT (1) AS LookupID, T.c.query('MeasurementName').value('.', 'nvarchar(max)') AS MeasurementType, 1 AS Active
				INTO #LookupsMeasurementType
				FROM @xml.nodes('/TestResults/Measurements/Measurement') T(c)
				WHERE LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('MeasurementName').value('.', 'nvarchar(max)')))) NOT IN ( (SELECT [Values] FROM Lookups WHERE LookupTypeID=@MeasurementTypeLookupTypeID)) 
					AND CONVERT(VARCHAR(MAX), T.c.query('MeasurementName').value('.', 'nvarchar(max)')) NOT IN ('N/A')
				
				SELECT @MaxID = MAX(LookupID)+1 FROM Lookups
				
				INSERT INTO Lookups (LookupID, LookupTypeID, [Values], IsActive)
				SELECT (ROW_NUMBER() OVER (ORDER BY LookupID)) + @MaxID AS LookupID, @MeasurementTypeLookupTypeID AS LookupTypeID, MeasurementType AS [Values], Active
				FROM #LookupsMeasurementType
			
				DROP TABLE #LookupsMeasurementType
			END
			
			PRINT 'Load Information into temp table'
			SELECT  ROW_NUMBER() OVER (ORDER BY T.c) AS RowID, T.c.query('.') AS value 
			INTO #temp3
			FROM @xml.nodes('/TestResults/Information/Info') T(c)
			
			SELECT @InfoRowID = MIN(RowID) FROM #temp3
			DECLARE @Version NVARCHAR(50)
			DECLARE @ProductConfigCommon NVARCHAR(50)
			DECLARE @SequenceConfigCommon NVARCHAR(50)
			DECLARE @StationConfigCommon NVARCHAR(50)
			DECLARE @TestConfigCommon NVARCHAR(50)
			DECLARE @Mode NVARCHAR(50)
			DECLARE @ConfigID INT
			SET @ConfigID = -1
			
			SELECT @Mode=T.c.query('Value').value('.', 'nvarchar(max)')
			FROM @xml.nodes('/TestResults/Information/Info') T(c)
			WHERE T.c.query('Name').value('.', 'nvarchar(max)') = 'OperatingMode'
			
			SELECT @Version=T.c.query('Value').value('.', 'nvarchar(max)')
			FROM @xml.nodes('/TestResults/Information/Info') T(c)
			WHERE T.c.query('Name').value('.', 'nvarchar(max)') = 'Test System Version'
			
			IF (@Version IS NOT NULL)
			BEGIN
				SELECT @Version = pvt.[1] + '.' + pvt.[2]
				FROM  
					(
						SELECT RowID, s as val
							FROM dbo.Split('.',@Version)
					) a
					PIVOT (
							MAX(val) 
							FOR RowID IN ([1],[2],[3],[4])
							) as pvt
			END
			
			WHILE (@InfoRowID IS NOT NULL)
			BEGIN
				SELECT @xmlPart  = value FROM #temp3 WHERE RowID=@InfoRowID	
				SET @ConfigID = NULL

				SELECT T.c.query('Name').value('.', 'nvarchar(max)') AS Name, T.c.query('Value').value('.', 'nvarchar(max)') AS Value, 0 AS ConfigID
				INTO #information
				FROM @xmlPart.nodes('/Info') T(c)
					
				IF EXISTS (SELECT 1 FROM #information WHERE Name='ProductConfigCommon')
				BEGIN
					SELECT @ProductConfigCommon=Value FROM #information WHERE Name='ProductConfigCommon'
					
					SELECT @ConfigID = c.ConfigID
					FROM dbo.Configurations c 
						INNER JOIN Lookups lct ON lct.LookupID=c.ConfigTypeID
						INNER JOIN Lookups lm ON lm.LookupID=c.ModeID
					WHERE lct.[Values] = 'ProductConfigCommon' AND c.[Version]=@Version AND lm.[Values] = @Mode
				END
					
				IF EXISTS (SELECT 1 FROM #information WHERE Name='SequenceConfigCommon')
				BEGIN
					SELECT @SequenceConfigCommon=Value FROM #information WHERE Name='SequenceConfigCommon'
					
					SELECT @ConfigID = c.ConfigID
					FROM dbo.Configurations c 
						INNER JOIN Lookups lct ON lct.LookupID=c.ConfigTypeID
						INNER JOIN Lookups lm ON lm.LookupID=c.ModeID
					WHERE lct.[Values] = 'SequenceConfigCommon' AND c.[Version]=@Version AND lm.[Values] = @Mode
				END
				
				IF EXISTS (SELECT 1 FROM #information WHERE Name='StationConfigCommon')
				BEGIN
					SELECT @StationConfigCommon=Value FROM #information WHERE Name='StationConfigCommon'
					
					SELECT @ConfigID = c.ConfigID
					FROM dbo.Configurations c 
						INNER JOIN Lookups lct ON lct.LookupID=c.ConfigTypeID
						INNER JOIN Lookups lm ON lm.LookupID=c.ModeID
					WHERE lct.[Values] = 'StationConfigCommon' AND c.[Version]=@Version AND lm.[Values] = @Mode
				END
				
				IF EXISTS (SELECT 1 FROM #information WHERE Name='TestConfigCommon')
				BEGIN
					SELECT @TestConfigCommon=Value FROM #information WHERE Name='TestConfigCommon'
					
					SELECT @ConfigID = c.ConfigID
					FROM dbo.Configurations c 
						INNER JOIN Lookups lct ON lct.LookupID=c.ConfigTypeID
						INNER JOIN Lookups lm ON lm.LookupID=c.ModeID
					WHERE lct.[Values] = 'TestConfigCommon' AND c.[Version]=@Version AND lm.[Values] = @Mode
				END
				
				IF (@ConfigID IS NOT NULL AND @ConfigID > 0)
				BEGIN
					UPDATE #information
					SET ConfigID=@ConfigID
				END				
				
				UPDATE ri
				SET IsArchived=1
				FROM Relab.ResultsInformation ri
					INNER JOIN Relab.ResultsXML rxml ON ri.XMLID=rxml.ID
					INNER JOIN #information i ON i.Name = ri.Name
				WHERE rxml.VerNum < @VerNum AND ISNULL(ri.IsArchived,0)=0 AND rxml.ResultID=@ResultID
					
				PRINT 'INSERT Version ' + CONVERT(NVARCHAR, @VerNum) + ' Information'
				INSERT INTO Relab.ResultsInformation(XMLID, Name, Value, IsArchived, ConfigID)
				SELECT @ID AS XMLID, Name, Value, 0, @ConfigID
				FROM #information

				SELECT @InfoRowID = MIN(RowID) FROM #temp3 WHERE RowID > @InfoRowID
				
				DROP TABLE #information
			END

			PRINT 'Load Informational Measurements into temp table'
			SELECT  ROW_NUMBER() OVER (ORDER BY T.c) AS RowID, T.c.query('.') AS value 
			INTO #temp4
			FROM @xml.nodes('/TestResults/Measurements/Measurement') T(c)
			WHERE LOWER(T.c.query('MeasurementName').value('.', 'nvarchar(max)')) IN
				('apx software version','id power supply 2','id power supply 1','id bt tester','tester sw version',
				'start','start utc','end','end utc', 'os','osversion','os version', 'cameraid','hwserialnumber','hardware id','hardwareid',
				'build','apx hardware model')
				
			SELECT @InfoRowID = MIN(RowID) FROM #temp4
			
			WHILE (@InfoRowID IS NOT NULL)
			BEGIN
				SELECT @xmlPart  = value FROM #temp4 WHERE RowID=@InfoRowID	
				
				SELECT T.c.query('MeasurementName').value('.', 'nvarchar(max)') AS Name, T.c.query('MeasuredValue').value('.', 'nvarchar(max)') AS Value
				INTO #information2
				FROM @xmlPart.nodes('/Info') T(c)
				
				UPDATE ri
				SET IsArchived=1
				FROM Relab.ResultsInformation ri
					INNER JOIN Relab.ResultsXML rxml ON ri.XMLID=rxml.ID
					INNER JOIN #information2 i ON i.Name = ri.Name
				WHERE rxml.VerNum < @VerNum AND ISNULL(ri.IsArchived,0)=0 AND rxml.ResultID=@ResultID
					
				PRINT 'INSERT Version ' + CONVERT(NVARCHAR, @VerNum) + ' Information'
				INSERT INTO Relab.ResultsInformation(XMLID, Name, Value, IsArchived)
				SELECT @ID AS XMLID, Name, Value, 0
				FROM #information2

				SELECT @InfoRowID = MIN(RowID) FROM #temp4 WHERE RowID > @InfoRowID
				
				DROP TABLE #information2
			END
			
			PRINT 'Load Measurements into temp table'
			SELECT  ROW_NUMBER() OVER (ORDER BY T.c) AS RowID, T.c.query('.') AS value 
			INTO #temp2
			FROM @xml.nodes('/TestResults/Measurements/Measurement') T(c)
			WHERE LOWER(T.c.query('MeasurementName').value('.', 'nvarchar(max)')) NOT IN
				('apx software version','id power supply 2','id power supply 1','id bt tester','tester sw version',
				'start','start utc','end','end utc', 'os','osversion','os version', 'cameraid','hwserialnumber','hardware id',
				'build','apx hardware model', 'cableloss')

			SELECT @RowID = MIN(RowID) FROM #temp2

			SELECT @LookupTypeNameID=LookupTypeID FROM LookupType WHERE Name=@LookupTypeName
			
			WHILE (@RowID IS NOT NULL)
			BEGIN
				DECLARE @FileName NVARCHAR(200)
				SET @FileName = NULL

				SELECT @xmlPart  = value FROM #temp2 WHERE RowID=@RowID

				SELECT CASE WHEN l2.LookupID IS NULL THEN l3.LookupID ELSE l2.LookupID END AS MeasurementTypeID,
					T.c.query('LowerLimit').value('.', 'nvarchar(max)') AS LowerLimit,
					T.c.query('UpperLimit').value('.', 'nvarchar(max)') AS UpperLimit,
					T.c.query('MeasuredValue').value('.', 'nvarchar(max)') AS MeasurementValue,
					(CASE WHEN T.c.query('PassFail').value('.', 'nvarchar(max)') = 'Pass' THEN 1 WHEN T.c.query('PassFail').value('.', 'nvarchar(max)') = 'Fail' Then 0 ELSE -1 END) AS PassFail,
					l.LookupID AS UnitTypeID,
					T.c.query('FileName').value('.', 'nvarchar(max)') AS [FileName], 
					[Relab].[ResultsXMLParametersComma] ((select T.c.query('.') from @xmlPart.nodes('/Measurement/Parameters') T(c))) AS Parameters,
					T.c.query('Comments').value('.', 'nvarchar(400)') AS [Comment],
					T.c.query('Description').value('.', 'nvarchar(800)') AS [Description],
					CAST(NULL AS DECIMAL(10,3)) AS DegradationVal
				INTO #measurement
				FROM @xmlPart.nodes('/Measurement') T(c)
					LEFT OUTER JOIN Lookups l ON l.LookupTypeID=@UnitTypeLookupTypeID AND l.[Values]=LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('Units').value('.', 'nvarchar(max)'))))
					LEFT OUTER JOIN Lookups l2 ON l2.LookupTypeID=@LookupTypeNameID AND l2.[Values]=LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('MeasurementName').value('.', 'nvarchar(max)'))))
					LEFT OUTER JOIN Lookups l3 ON l3.LookupTypeID=@MeasurementTypeLookupTypeID AND l3.[Values]=LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('MeasurementName').value('.', 'nvarchar(max)'))))

				UPDATE #measurement
				SET Comment=''
				WHERE Comment='N/A'

				UPDATE #measurement
				SET Description=null
				WHERE Description='N/A' or Description='NA'
				
				DELETE FROM #files

				IF (LTRIM(RTRIM(LOWER(@TestStageName))) NOT IN ('baseline', 'analysis') AND LTRIM(RTRIM(LOWER(@TestStageName))) NOT LIKE '%Calibra%' AND EXISTS(SELECT 1 FROM #measurement WHERE PassFail = -1))
				BEGIN
					DECLARE @BaselineResultID INT
					DECLARE @BaseRowID INT
					
					SELECT @BaselineResultID = r.ID
					FROM Relab.Results r
					WHERE r.TestUnitID=@UnitID AND r.TestID=@TestID AND r.TestStageID=@BaselineID

					PRINT 'BaselineResultID: ' + CONVERT(VARCHAR, @BaselineResultID)
					
					SELECT ROW_NUMBER() OVER (ORDER BY rm.ID) AS RowID, rm.MeasurementTypeID AS BaselineMeasurementTypeID, rm.MeasurementValue AS BaselineMeasurementValue, 
						LTRIM(RTRIM(ISNULL(Relab.ResultsParametersComma(rm.ID),''))) AS BaselineParameters,
						m.MeasurementTypeID, m.MeasurementValue, LTRIM(RTRIM(ISNULL(m.Parameters,''))) AS Parameters
					INTO #MeasurementCompare
					FROM Relab.ResultsMeasurements rm
						INNER JOIN #measurement m ON rm.MeasurementTypeID=m.MeasurementTypeID AND LTRIM(RTRIM(ISNULL(Relab.ResultsParametersComma(rm.ID),''))) = LTRIM(RTRIM(ISNULL(m.Parameters,'')))
					WHERE rm.ResultID=@BaselineResultID AND ISNULL(rm.Archived, 0) = 0 AND m.PassFail=-1

					SELECT @BaseRowID = MIN(RowID) FROM #MeasurementCompare
					
					WHILE (@BaseRowID IS NOT NULL)
					BEGIN
						DECLARE @BParmaeters NVARCHAR(MAX)
						DECLARE @BMeasurementTypeID INT
						DECLARE @temp TABLE (val DECIMAL(10,3))
						DECLARE @bv DECIMAL(10,3)
						DECLARE @v DECIMAL(10,3)
						DECLARE @result DECIMAL(10,3)
						DECLARE @bPassFail BIT
						SET @result = 0.0
						SET @v = 0.0
						SET @bv = 0.0
						
						SELECT @BMeasurementTypeID = MeasurementTypeID, @bv = CONVERT(DECIMAL(10,3), BaselineMeasurementValue), @v = CONVERT(DECIMAL(10,3), MeasurementValue), 
							@BParmaeters = Parameters
						FROM #MeasurementCompare 
						WHERE RowID=@BaseRowID

						PRINT 'Baseline Value: ' + CONVERT(VARCHAR, @bv)     
						PRINT 'Current Value: ' + CONVERT(VARCHAR, @v)
						PRINT 'BMeasurementTypeID: ' + CONVERT(VARCHAR, @BMeasurementTypeID)
						
						INSERT INTO @temp VALUES (@bv)
						INSERT INTO @temp VALUES (@v)
						
						SELECT @result = STDEV(val) FROM @temp
						
						PRINT 'STDEV Result: ' + CONVERT(VARCHAR, @result)
						
						UPDATE #measurement
						SET PassFail = (CASE WHEN (@result > @DegradationVal) THEN 0 ELSE 1 END),
							DegradationVal = @result
						WHERE MeasurementTypeID = @BMeasurementTypeID AND LTRIM(RTRIM(ISNULL(Parameters,'')))=LTRIM(RTRIM(ISNULL(@BParmaeters,'')))
						
						SELECT @BaseRowID = MIN(RowID) FROM #MeasurementCompare WHERE RowID > @BaseRowID
						DELETE FROM @temp
					END

					DROP TABLE #MeasurementCompare
				END
				
				IF (@VerNum = 1)
				BEGIN
					PRINT 'INSERT Version 1 Measurements'
					INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, PassFail, ReTestNum, Archived, XMLID, Comment, Description, DegradationVal)
					SELECT @ResultID As ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, UnitTypeID, CONVERT(BIT, PassFail), 1, 0, @ID, Comment, Description, DegradationVal AS DegradationVal
					FROM #measurement

					DECLARE @ResultMeasurementID INT
					SET @ResultMeasurementID = @@IDENTITY
					
					PRINT 'INSERT Version 1 Parameters'
					INSERT INTO Relab.ResultsParameters (ResultMeasurementID, ParameterName, Value)
					SELECT @ResultMeasurementID AS ResultMeasurementID, T.c.value('@ParameterName','nvarchar(max)') AS ParameterName, T.c.query('.').value('.', 'nvarchar(max)') AS Value
					FROM @xmlPart.nodes('/Measurement/Parameters/Parameter') T(c)

					SELECT @FileName = LTRIM(RTRIM([FileName]))
					FROM #measurement
					
					IF (@FileName IS NOT NULL AND @FileName <> '')
						BEGIN
							UPDATE Relab.ResultsMeasurementsFiles 
							SET ResultMeasurementID=@ResultMeasurementID 
							WHERE LOWER(LTRIM(RTRIM([FileName])))=LOWER(LTRIM(RTRIM(@FileName))) AND ResultMeasurementID IS NULL
						END
					
					INSERT INTO #files ([FileName])
					SELECT T.c.query('.').value('.', 'nvarchar(max)') AS [FileName]
					FROM @xmlPart.nodes('/Measurement/Files/FileName') T(c)
				
					UPDATE Relab.ResultsMeasurementsFiles 
					SET ResultMeasurementID=@ResultMeasurementID
					FROM Relab.ResultsMeasurementsFiles 
						INNER JOIN #files f ON f.[FileName] = LOWER(LTRIM(RTRIM(Relab.ResultsMeasurementsFiles.FileName)))
					WHERE ResultMeasurementID IS NULL
				END
				ELSE
				BEGIN
					DECLARE @MeasurementTypeID INT
					DECLARE @Parameters NVARCHAR(MAX)
					DECLARE @MeasuredValue NVARCHAR(500)
					DECLARE @OldMeasuredValue NVARCHAR(500)
					DECLARE @ReTestNum INT
					SET @ReTestNum = 1
					SET @OldMeasuredValue = NULL
					SET @MeasuredValue = NULL
					SET @Parameters = NULL
					SET @MeasurementTypeID = NULL
					SELECT @MeasurementTypeID=MeasurementTypeID, @Parameters=LTRIM(RTRIM(ISNULL(Parameters, ''))), @MeasuredValue=MeasurementValue FROM #measurement
					
					SELECT @OldMeasuredValue = MeasurementValue , @ReTestNum = reTestNum+1
					FROM Relab.ResultsMeasurements 
					WHERE ResultID=@ResultID AND MeasurementTypeID=@MeasurementTypeID AND LTRIM(RTRIM(ISNULL(Relab.ResultsParametersComma(ID),''))) = LTRIM(RTRIM(ISNULL(@Parameters,''))) AND Archived=0

					IF ((@OldMeasuredValue IS NOT NULL AND @OldMeasuredValue <> @MeasuredValue) OR (@OldMeasuredValue IS NOT NULL AND @OldMeasuredValue = @MeasuredValue))
					--That result has that measurement type and exact parameters but measured value is different
					--OR
					--That result has that measurement type and exact parameters and measured value is the same
					BEGIN
						PRINT 'INSERT ReTest Measurements'
						INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, PassFail, ReTestNum, Archived, XMLID, Comment, Description, DegradationVal)
						SELECT @ResultID As ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, UnitTypeID, CONVERT(BIT, PassFail), @ReTestNum, 0, @ID, Comment, Description, DegradationVal AS DegradationVal
						FROM #measurement
						
						DECLARE @ResultMeasurementID2 INT
						SET @ResultMeasurementID2 = @@IDENTITY
						
						SELECT @FileName = LTRIM(RTRIM([FileName]))
						FROM #measurement
					
						IF (@FileName IS NOT NULL AND @FileName <> '')
							BEGIN
								UPDATE Relab.ResultsMeasurementsFiles 
								SET ResultMeasurementID=@ResultMeasurementID2 
								WHERE LOWER(LTRIM(RTRIM(FileName)))=LOWER(LTRIM(RTRIM(@FileName))) AND ResultMeasurementID IS NULL
							END
					
						INSERT INTO #files ([FileName])
						SELECT T.c.query('.').value('.', 'nvarchar(max)') AS [FileName]
						FROM @xmlPart.nodes('/Measurement/Files/FileName') T(c)
					
						UPDATE Relab.ResultsMeasurementsFiles 
						SET ResultMeasurementID=@ResultMeasurementID2
						FROM Relab.ResultsMeasurementsFiles 
							INNER JOIN #files f ON f.[FileName] = LOWER(LTRIM(RTRIM(Relab.ResultsMeasurementsFiles.FileName)))
						WHERE ResultMeasurementID IS NULL
						
						IF (@Parameters <> '')
						BEGIN
							PRINT 'INSERT ReTest Parameters'
							INSERT INTO Relab.ResultsParameters (ResultMeasurementID, ParameterName, Value)
							SELECT @ResultMeasurementID2 AS ResultMeasurementID, T.c.value('@ParameterName','nvarchar(max)') AS ParameterName, T.c.query('.').value('.', 'nvarchar(max)') AS Value
							FROM @xmlPart.nodes('/Measurement/Parameters/Parameter') T(c)
						END

						UPDATE Relab.ResultsMeasurements 
						SET Archived=1 
						WHERE ResultID=@ResultID AND Archived=0 AND MeasurementTypeID=@MeasurementTypeID AND LTRIM(RTRIM(ISNULL(Relab.ResultsParametersComma(ID),''))) = LTRIM(RTRIM(ISNULL(@Parameters,''))) AND ReTestNum < @ReTestNum
					END
					ELSE
					--That result does not have that measurement type and exact parameters
					BEGIN
						PRINT 'INSERT New Measurements'
						INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, PassFail, ReTestNum, Archived, XMLID, Comment, Description, DegradationVal)
						SELECT @ResultID As ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, UnitTypeID, CONVERT(BIT, PassFail), 1, 0, @ID, Comment, Description, DegradationVal AS DegradationVal
						FROM #measurement

						DECLARE @ResultMeasurementID3 INT
						SET @ResultMeasurementID3 = @@IDENTITY
						
						SELECT @FileName = LTRIM(RTRIM([FileName]))
						FROM #measurement
					
						IF (@FileName IS NOT NULL AND @FileName <> '')
							BEGIN
								UPDATE Relab.ResultsMeasurementsFiles 
								SET ResultMeasurementID=@ResultMeasurementID3 
								WHERE LOWER(LTRIM(RTRIM(FileName)))=LOWER(@FileName) AND ResultMeasurementID IS NULL
							END
						
						INSERT INTO #files ([FileName])
						SELECT T.c.query('.').value('.', 'nvarchar(max)') AS [FileName]
						FROM @xmlPart.nodes('/Measurement/Files/FileName') T(c)
					
						UPDATE Relab.ResultsMeasurementsFiles 
						SET ResultMeasurementID=@ResultMeasurementID2
						FROM Relab.ResultsMeasurementsFiles 
							INNER JOIN #files f ON f.[FileName] = LOWER(LTRIM(RTRIM(Relab.ResultsMeasurementsFiles.FileName)))
						WHERE ResultMeasurementID IS NULL
					
						IF (@Parameters <> '')
						BEGIN								
							PRINT 'INSERT New Parameters'
							INSERT INTO Relab.ResultsParameters (ResultMeasurementID, ParameterName, Value)
							SELECT @ResultMeasurementID3 AS ResultMeasurementID, T.c.value('@ParameterName','nvarchar(max)') AS ParameterName, T.c.query('.').value('.', 'nvarchar(max)') AS Value
							FROM @xmlPart.nodes('/Measurement/Parameters/Parameter') T(c)
						END
					END
				END
				
				DROP TABLE #measurement
			
				SELECT @RowID = MIN(RowID) FROM #temp2 WHERE RowID > @RowID
			END
			
			DROP TABLE #files
			
			PRINT 'Update Result To Be Processed'
			UPDATE Relab.ResultsXML SET IsProcessed=1 WHERE ID=@ID
			
			UPDATE Relab.Results
			SET PassFail=CASE WHEN (SELECT COUNT(*) FROM Relab.ResultsMeasurements WHERE ResultID=@ResultID AND Archived=0 AND PassFail=0) > 0 THEN 0 ELSE 1 END
			WHERE ID=@ResultID
		
			DROP TABLE #temp2
			SET NOCOUNT OFF

			GOTO HANDLE_SUCCESS
		END
	END TRY
	BEGIN CATCH
		SET NOCOUNT OFF
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
			
			IF (@ID IS NOT NULL AND @ID > 0)
			BEGIN
				UPDATE Relab.ResultsXML SET ErrorOccured=1 WHERE ID=@ID
			END
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
PRINT N'Altering [Relab].[remispResultsInformation]'
GO
ALTER PROCEDURE [Relab].[remispResultsInformation] @ResultID INT, @IncludeArchived INT = 0
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @FalseBit BIT
	SET @FalseBit = CONVERT(BIT, 0)
	
	SELECT ri.Name, ri.Value, ri.XMLID, rxml.VerNum, ISNULL(ri.IsArchived, 0) AS IsArchived, c.Definition AS ConfigXML
	FROM Relab.ResultsInformation ri
		INNER JOIN Relab.ResultsXML rxml ON ri.XMLID=rxml.ID
		LEFT OUTER JOIN dbo.Configurations c ON c.ConfigID=ri.ConfigID
	WHERE rxml.ResultID=@ResultID AND ((@IncludeArchived = 0 AND ri.IsArchived=@FalseBit) OR (@IncludeArchived=1))

	SET NOCOUNT OFF
END
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
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	AND (@OnlyShowQRAWithResults = 0 OR (@OnlyShowQRAWithResults = 1 AND b.ID IN (SELECT tu.BatchID FROM Relab.Results r INNER JOIN TestUnits tu ON tu.ID=r.TestUnitID)))
	AND (b.DepartmentID IN (SELECT ud.LookupID 
							FROM UserDetails ud 
								INNER JOIN Lookups lt ON lt.LookupID=ud.LookupID
							WHERE ud.UserID=@UserID))
ORDER BY b.QRANumber DESC
RETURN
GO
GRANT EXECUTE ON remispYourBatchesGetActiveBatches TO Remi
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
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