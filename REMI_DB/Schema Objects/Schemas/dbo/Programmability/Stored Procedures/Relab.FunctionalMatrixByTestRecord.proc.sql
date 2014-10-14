ALTER PROCEDURE [Relab].[FunctionalMatrixByTestRecord] @TRID INT = NULL, @TestStageID INT, @TestID INT, @BatchID INT, @UnitIDs NVARCHAR(MAX) = NULL, @FunctionalType INT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	DECLARE @LookupType NVARCHAR(20)
	DECLARE @TestUnitID INT
	CREATE Table #units(id int) 
	INSERT INTO #units SELECT s FROM dbo.Split(',',@UnitIDs)
	
	IF (@TRID IS NOT NULL)
	BEGIN
		SELECT @TestUnitID = TestUnitID FROM TestRecords WHERE ID=@TRID
		INSERT INTO #units VALUES (@TestUnitID)
	END
	ELSE
	BEGIN
		EXEC(@UnitIDs)
	END
	
	IF (@FunctionalType = 1)
		SET @LookupType = 'SFIFunctionalMatrix'
	ELSE IF (@FunctionalType = 2)
		SET @LookupType = 'MFIFunctionalMatrix'
	ELSE IF (@FunctionalType = 3)
		SET @LookupType = 'AccFunctionalMatrix'
	ELSE
		SET @LookupType = 'SFIFunctionalMatrix'
	
	SELECT @rows=  ISNULL(STUFF(
		(SELECT DISTINCT '],[' + l.[Values]
		FROM dbo.Lookups l
		WHERE Type=@LookupType
		ORDER BY '],[' +  l.[Values]
		FOR XML PATH('')), 1, 2, '') + ']','[na]')
	
	SET @sql = 'SELECT *
		FROM (
			SELECT l.[Values], tu.ID AS TestUnitID, tu.BatchUnitNumber, 
				CASE 
					WHEN r.ID IS NULL 
					THEN -1
					ELSE (
						SELECT PassFail 
						FROM Relab.ResultsMeasurements rm 
							LEFT OUTER JOIN Lookups lr ON lr.Type=''' + CONVERT(VARCHAR, @LookupType) + ''' AND rm.MeasurementTypeID=lr.LookupID
						WHERE rm.ResultID=r.ID AND lr.[values] = l.[values] AND rm.Archived = 0)
				END As Row
			FROM dbo.Lookups l
			INNER JOIN TestUnits tu ON tu.BatchID = ' + CONVERT(VARCHAR, @BatchID) + ' AND 
				(
					(' + CONVERT(VARCHAR, ISNULL(CONVERT(VARCHAR,@TestUnitID), 'NULL')) + ' IS NULL)
					OR
					(' + CONVERT(VARCHAR, ISNULL(CONVERT(VARCHAR,@TestUnitID), 'NULL')) + ' IS NOT NULL AND tu.ID=' + CONVERT(VARCHAR, ISNULL(CONVERT(VARCHAR,@TestUnitID), 'NULL')) + ')
				)
			INNER JOIN #units ON tu.ID=@units.ID
			LEFT OUTER JOIN Relab.Results r ON r.TestID = ' + CONVERT(VARCHAR, @TestID) + ' AND r.TestStageID = ' + CONVERT(VARCHAR, @TestStageID) + ' 
				AND r.TestUnitID = tu.ID
			WHERE l.Type=''' + CONVERT(VARCHAR, @LookupType) + '''
			) te 
			PIVOT (MAX(row) FOR [Values] IN (' + @rows + ')) AS pvt
			ORDER BY BatchUnitNumber'

	PRINT @sql
	EXEC(@sql)
	DROP TABLE #units
	
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[FunctionalMatrixByTestRecord] TO Remi
GO