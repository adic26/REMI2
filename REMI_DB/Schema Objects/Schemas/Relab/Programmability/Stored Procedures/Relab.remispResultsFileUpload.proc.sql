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
	DECLARE @TestStageType INT
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
	
	IF (@JobName IS NULL OR LTRIM(RTRIM(@JobName)) = '')
	BEGIN
		SELECT @JobName=JobName FROM Batches b WITH(NOLOCK) WHERE b.QRANumber=@QRANumber
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
	BEGIN
		SET @StartDate = DATEADD(DAY, -CONVERT(INT, SUBSTRING(@Duration, 1, CHARINDEX('.', @Duration)-1)), @EndDate)
		SET @Duration = SUBSTRING(@Duration, CHARINDEX('.', @Duration)+1, LEN(@Duration))
	END
	
	SELECT * INTO #dates FROM dbo.Split(':', @Duration)
	
	IF ((SELECT s FROM #dates WHERE RowID=1) IS NOT NULL)
	BEGIN
		SET @StartDate = DATEADD(HOUR, -CONVERT(INT, (SELECT s FROM #dates WHERE RowID=1)), @StartDate)
	END
	
	IF ((SELECT s FROM #dates WHERE RowID=2) IS NOT NULL)
	BEGIN
		SET @StartDate = DATEADD(MINUTE, -CONVERT(INT, (SELECT s FROM #dates WHERE RowID=2)), @StartDate)
	END
	
	IF ((SELECT s FROM #dates WHERE RowID=3) IS NOT NULL)
	BEGIN
		SET @StartDate = DATEADD(SECOND, -CONVERT(INT, (SELECT s FROM #dates WHERE RowID=3)), @StartDate)
	END

	DROP TABLE #dates
	select @StartDate,@EndDate

	SELECT @TestUnitID = tu.ID
	FROM TestUnits tu
		INNER JOIN Batches b ON tu.BatchID=b.ID
	WHERE QRANumber=@QRANumber AND tu.BatchUnitNumber=@TestUnitNumber
	
	PRINT 'Request Number: ' + CONVERT(VARCHAR, @QRANumber)
	PRINT 'Unit Number: ' + CONVERT(VARCHAR, @TestUnitNumber)
	PRINT 'Station Name: ' + CONVERT(VARCHAR, @StationName)
	PRINT 'Duration: ' + CONVERT(VARCHAR, @Duration)
	PRINT 'Date Started: ' + CONVERT(VARCHAR, @StartDate)
	PRINT 'Date Completed: ' + CONVERT(VARCHAR, @EndDate)
	PRINT 'JobName: ' + @JobName
	PRINT 'Test Stage: ' + @TestStageName
	PRINT 'Test Name: ' + @TestName

	IF (@TestUnitID IS NOT NULL)
	BEGIN
		PRINT 'TestUnitID: ' + CONVERT(VARCHAR, @TestUnitID)

		SELECT @TestStageID = ts.ID, @TestStageType=ts.TestStageType
		FROM Jobs j
			INNER JOIN TestStages ts ON j.ID=ts.JobID
		WHERE j.JobName=@JobName AND ts.TestStageName=@TestStageName
	
		PRINT 'TestStageID: ' + CONVERT(VARCHAR, @TestStageID)

		IF (@TestStageType = 1)
		BEGIN
			SELECT @TestID = t.ID
			FROM Tests t
			WHERE t.TestName=@TestName
		END
		ELSE IF (@TestStageType = 2)
		BEGIN
			SELECT @TestID = ts.TestID
			FROM TestStages ts
			WHERE ts.ID=@TestStageID
		END
		
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
GRANT EXECUTE ON [Relab].[remispResultsFileUpload] TO REMI
GO