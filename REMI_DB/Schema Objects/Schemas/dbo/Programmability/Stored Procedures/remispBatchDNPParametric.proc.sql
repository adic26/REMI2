ALTER PROCEDURE remispBatchDNPParametric @QRANumber NVARCHAR(11), @LDAPLogin NVARCHAR(255), @UnitNumber INT
AS
	DECLARE @UnitID INT
	DECLARE @TestID INT
	DECLARE @TestStageID INT
	DECLARE @ID INT
	DECLARE @JobID INT

	IF (@UnitNumber = 0)
	BEGIN
		SET @UnitNumber = NULL
	END

	SELECT @JobID=j.ID FROM Batches b INNER JOIN Jobs j ON j.JobName=b.JobName WHERE b.QRANumber=@QRANumber
	
	PRINT @JobID

	SELECT ID
	INTO #tests
	FROM Tests
	WHERE TestType=1 AND ID NOT IN (202, 1073, 1185, 1020, 1212, 1211, 1280, 1102, 1103, 233, 1222, 1013)
		AND ISNULL(IsArchived, 0) = 0
	ORDER BY ID

	SELECT ID
	INTO #stages
	FROM TestStages
	WHERE TestStageType=1 AND ISNULL(IsArchived, 0) = 0 AND TestStages.JobID=@JobID AND ProcessOrder > 0
	ORDER BY ID

	SELECT tu.ID
	INTO #units
	FROM TestUnits tu
		INNER JOIN Batches b ON tu.BatchID=b.ID
	WHERE b.QRANumber=@QRANumber AND ((@UnitNumber IS NULL) OR (@UnitNumber IS NOT NULL AND tu.BatchUnitNumber=@UnitNumber))
	ORDER BY tu.ID

	
	SELECT @TestStageID = MIN(ID) FROM #stages

	WHILE (@TestStageID IS NOT NULL)
	BEGIN
		SELECT @TestID = MIN(ID) FROM #tests

		WHILE (@TestID IS NOT NULL)
		BEGIN
			SELECT @UnitID = MIN(ID) FROM #units
			PRINT @TestID
		
			WHILE (@UnitID IS NOT NULL)
			BEGIN
				PRINT @UnitID
				SELECT @ID = MAX(ID)+1 FROM TestExceptions
				INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 3, @UnitID, @LDAPLogin)--TestUnit
				INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @TestID, @LDAPLogin)--Test
				INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 4, @TestStageID, @LDAPLogin)--TestStage
			
				SELECT @UnitID = MIN(ID) FROM #units WHERE ID > @UnitID
			END

			SELECT @TestID = MIN(ID) FROM #tests WHERE ID>@TestID
		END

		SELECT @TestStageID = MIN(ID) FROM #stages WHERE ID>@TestStageID
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