ALTER PROCEDURE [Req].[RequestSearch] @RequestTypeID INT, @tv dbo.SearchFields READONLY
AS
BEGIN
	SET NOCOUNT ON
	CREATE TABLE #Request (RequestID INT, RequestNumber NVARCHAR(11))
	SELECT * INTO #temp FROM @tv
	
	UPDATE t
	SET t.ColumnName= '[' + rfs.Name + ']'
	FROM Req.ReqFieldSetup rfs
		INNER JOIN #temp t ON rfs.ReqFieldSetupID=t.ID
	WHERE rfs.RequestTypeID=@RequestTypeID AND t.TableType='Request'

	DECLARE @ColumnName NVARCHAR(255)
	DECLARE @whereStr NVARCHAR(MAX)
	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + rfs.Name
		FROM Req.ReqFieldSetup rfs WITH(NOLOCK)
		WHERE rfs.RequestTypeID=@RequestTypeID
		ORDER BY '],[' +  rfs.Name
		FOR XML PATH('')), 1, 2, '') + ']','[na]')
	
	SET @sql = 'ALTER TABLE #Request ADD ' + convert(varchar(8000), replace(@rows, ']', '] NVARCHAR(4000)'))
	EXEC (@sql)
	
	SET @sql = 'INSERT INTO #Request SELECT *
		FROM 
			(
			SELECT r.RequestID, r.RequestNumber, rfd.Value, rfs.Name 
			FROM Req.Request r WITH(NOLOCK)
				INNER JOIN Req.ReqFieldData rfd WITH(NOLOCK) ON rfd.RequestID=r.RequestID
				INNER JOIN Req.ReqFieldSetup rfs WITH(NOLOCK) ON rfs.ReqFieldSetupID=rfd.ReqFieldSetupID
				INNER JOIN Req.RequestType rt WITH(NOLOCK) ON rt.RequestTypeID=rfs.RequestTypeID
			WHERE rt.RequestTypeID=' + CONVERT(NVARCHAR, @RequestTypeID) + '
			) req PIVOT (MAX(Value) FOR Name IN (' + @rows + ')) AS pvt '

	IF ((SELECT COUNT(*) FROM #temp WHERE TableType='Request') > 0)
	BEGIN
		SET @sql += ' WHERE '
		
		DECLARE @ID INT
		SELECT @ID = MIN(ID) FROM #temp WHERE TableType='Request'
		
		WHILE (@ID IS NOT NULL)
		BEGIN
			SET @ColumnName = ''
			SET @whereStr = ''
			SELECT @ColumnName=ColumnName FROM #temp WHERE ID = @ID AND TableType='Request'
			
			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(SearchTerm)) + ''','
			FROM #temp
			WHERE ID = @ID AND TableType='Request'
			
			SET @sql += @ColumnName + ' IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ') AND '
			
			SELECT @ID = MIN(ID) FROM #temp WHERE ID > @ID AND TableType='Request'
		END
		
		SET @sql = SUBSTRING(@sql, 0, LEN(@sql)-2)
	END
	
	PRINT @sql
	EXEC (@sql)				
	
	IF ((SELECT COUNT(*) FROM #temp WHERE TableType <> 'Request') > 0)
	BEGIN
		CREATE TABLE #RequestResults (RequestID INT, RequestNumber NVARCHAR(11))
		CREATE TABLE #parameters (ResultMeasurementID INT)
		CREATE TABLE #information (RID INT, ResultInfoArchived BIT)
		
		SET @sql = 'ALTER TABLE #RequestResults ADD ' + convert(varchar(8000), replace(@rows, ']', '] NVARCHAR(4000)'))
		EXEC (@sql)
		
		IF ((SELECT COUNT(*) FROM #temp WHERE TableType IN ('Test', 'Stage')) > 0)
		BEGIN
			ALTER TABLE #RequestResults ADD BatchUnitNumber INT, IMEI NVARCHAR(150), BSN BIGINT, TestName NVARCHAR(400), TestStageName NVARCHAR(400), 
				TestRunStartDate DATETIME, TestRunEndDate DATETIME, MeasurementName NVARCHAR(150), MeasurementValue NVARCHAR(500), 
				UpperLimit NVARCHAR(255), LowerLimit NVARCHAR(255), Archived BIT, Comment NVARCHAR(400), 
				DegradationVal DECIMAL(10,3), Description NVARCHAR(800), PassFail BIT, ReTestNum INT,
				MeasurementUnitType NVARCHAR(150), ID INT, ResultID INT
		END
		ELSE
		BEGIN
			ALTER TABLE #RequestResults ADD BatchUnitNumber INT, IMEI NVARCHAR(150), BSN BIGINT, ID INT, ResultID INT
		END
		
		SET @rows = REPLACE(@rows, '[', 'r.[')

		SET @sql = 'INSERT INTO #RequestResults SELECT r.RequestID, r.RequestNumber, ' + @rows + ', tu.BatchUnitNumber, tu.IMEI, tu.BSN '
		
		IF ((SELECT COUNT(*) FROM #temp WHERE TableType IN ('Test', 'Stage')) > 0)
		BEGIN
			SET @sql += ', t.TestName, ts.TestStageName, x.StartDate AS TestRunStartDate, x.EndDate AS TestRunEndDate, 
				mn.[Values] As MeasurementName, m.MeasurementValue, m.UpperLimit, m.LowerLimit, m.Archived, m.Comment, m.DegradationVal, m.Description, m.PassFail, m.ReTestNum, 
				mut.[Values] As MeasurementUnitType, m.ID, rs.ID AS ResultID '
		END
		ELSE
		BEGIN
			SET @sql += ', 0 AS ID, 0 AS ResultID '
		END
		
		SET @sql += 'FROM #Request r WITH(NOLOCK)
			INNER JOIN Batches b WITH(NOLOCK) ON b.QRANumber=r.RequestNumber
			INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.BatchID=b.ID '

		IF ((SELECT COUNT(*) FROM #temp WHERE TableType IN ('Test', 'Stage')) > 0)
		BEGIN
			DECLARE @ResultArchived INT
			DECLARE @TestRunStartDate DATETIME
			DECLARE @TestRunEndDate DATETIME
			
			SELECT @ResultArchived = ID FROM #temp WHERE TableType='ResultArchived'
			SELECT @TestRunStartDate = SearchTerm FROM #temp WHERE TableType='TestRunStartDate'
			SELECT @TestRunEndDate = SearchTerm FROM #temp WHERE TableType='TestRunEndDate'
			
			IF @ResultArchived IS NULL
				SET @ResultArchived = 0
				
			SET @sql += 'INNER JOIN Relab.Results rs WITH(NOLOCK) ON rs.TestUnitID=tu.ID
				INNER JOIN Relab.ResultsXML x ON x.ResultID = rs.ID
				INNER JOIN Tests t WITH(NOLOCK) ON rs.TestID=t.ID
				INNER JOIN TestStages ts WITH(NOLOCK) ON rs.TestStageID=ts.ID
				INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) ON m.ResultID=rs.ID 
				INNER JOIN Lookups mn WITH(NOLOCK) ON mn.LookupID = m.MeasurementTypeID 
				INNER JOIN Lookups mut WITH(NOLOCK) ON mut.LookupID = m.MeasurementUnitTypeID 
			WHERE ((' + CONVERT(NVARCHAR,@ResultArchived) + ' = 0 AND m.Archived=0) OR (' + CONVERT(NVARCHAR, @ResultArchived) + '=1)) '
			
			IF (@TestRunStartDate IS NOT NULL AND @TestRunEndDate IS NOT NULL)
			BEGIN
				SET @sql += ' AND x.StartDate BETWEEN ''' + CONVERT(NVARCHAR,@TestRunStartDate) + ''' AND ''' + CONVERT(NVARCHAR,@TestRunEndDate) + ''' '
			END
		END
		
		IF ((SELECT COUNT(*) FROM #temp WHERE TableType='Unit') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(ISNULL(SearchTerm, ''))) + ''','
			FROM #temp
			WHERE TableType = 'Unit'
					
			SET @sql += ' AND tu.BatchUnitNumber IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')'
		END
		
		IF ((SELECT COUNT(*) FROM #temp WHERE TableType='IMEI') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(ISNULL(SearchTerm, ''))) + ''','
			FROM #temp
			WHERE TableType = 'IMEI'
					
			SET @sql += ' AND tu.IMEI IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')'
		END
				
		IF ((SELECT COUNT(*) FROM #temp WHERE TableType='BSN') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(SearchTerm)) + ''','
			FROM #temp
			WHERE TableType = 'BSN'
					
			SET @sql += ' AND tu.BSN IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')'
		END
		
		IF ((SELECT COUNT(*) FROM #temp WHERE TableType='Test') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + LTRIM(RTRIM(ID)) + ','
			FROM #temp
			WHERE TableType = 'Test'
					
			SET @sql += ' AND t.ID IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')'
		END
		
		IF ((SELECT COUNT(*) FROM #temp WHERE TableType='Stage') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + LTRIM(RTRIM(ID)) + ','
			FROM #temp
			WHERE TableType = 'Stage'

			SET @sql += ' AND ts.ID IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ') '
		END
		
		PRINT @sql
		EXEC (@sql)
		
		IF ((SELECT COUNT(*) FROM #temp WHERE TableType IN ('Test', 'Stage')) > 0)
		BEGIN
			SELECT @rows=  ISNULL(STUFF(
			( 
			SELECT DISTINCT '],[' + rp.ParameterName
			FROM #RequestResults rr WITH(NOLOCK)
				LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rr.ID=rp.ResultMeasurementID
			WHERE rp.ParameterName <> 'Command'
			ORDER BY '],[' +  rp.ParameterName
			FOR XML PATH('')), 1, 2, '') + ']','[na]')

			IF (@rows <> '[na]')
			BEGIN
				SET @sql = 'ALTER TABLE #parameters ADD ' + convert(varchar(8000), replace(@rows, ']', '] NVARCHAR(250)'))
				EXEC (@sql)
				
				EXEC ('INSERT INTO #parameters SELECT *
				FROM (
					SELECT rp.ResultMeasurementID, rp.ParameterName, rp.Value
					FROM #RequestResults rr WITH(NOLOCK)
						LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rr.ID=rp.ResultMeasurementID
					WHERE rp.ParameterName <> ''Command'' 
					) te PIVOT (MAX(Value) FOR ParameterName IN (' + @rows + ')) AS pvt')
			END
			
			DECLARE @ResultInfoArchived INT
			SELECT @ResultInfoArchived = ID FROM #temp WHERE TableType='ResultInfoArchived'
			
			IF @ResultInfoArchived IS NULL
				SET @ResultInfoArchived = 0
				
			SELECT @rows=  ISNULL(STUFF(
			( 
			SELECT DISTINCT '],[' + ri.Name
			FROM #RequestResults rr WITH(NOLOCK)
				INNER JOIN Relab.ResultsXML x WITH(NOLOCK) ON x.ResultID = rr.ResultID
				LEFT OUTER JOIN Relab.ResultsInformation ri WITH(NOLOCK) ON x.ID=ri.XMLID
			WHERE ri.Name NOT IN ('Start UTC','Start','End', 'STEF Plugin Version')
				AND ((@ResultInfoArchived = 0 AND ri.IsArchived=0) OR (@ResultInfoArchived=1))
			ORDER BY '],[' +  ri.Name
			FOR XML PATH('')), 1, 2, '') + ']','[na]')

			IF (@rows <> '[na]')
			BEGIN
				SET @sql = 'ALTER TABLE #information ADD ' + convert(varchar(8000), replace(@rows, ']', '] NVARCHAR(250)'))
				EXEC (@sql)
				
				EXEC ('INSERT INTO #information SELECT *
				FROM (
					SELECT rr.ResultID AS RID, ri.IsArchived AS ResultInfoArchived, ri.Name, ri.Value
					FROM #RequestResults rr WITH(NOLOCK)
						INNER JOIN Relab.ResultsXML x WITH(NOLOCK) ON x.ResultID = rr.ResultID
						LEFT OUTER JOIN Relab.ResultsInformation ri WITH(NOLOCK) ON x.ID=ri.XMLID
						WHERE ri.Name NOT IN (''Start UTC'',''Start'',''End'', ''STEF Plugin Version'') AND
							((' + @ResultInfoArchived + ' = 0 AND ri.IsArchived=0) OR (' + @ResultInfoArchived + '=1)) 
					) te PIVOT (MAX(Value) FOR Name IN (' + @rows + ')) AS pvt')
			END
		END
		
		SELECT *
		INTO #preSelect
		FROM #RequestResults rr 
			LEFT OUTER JOIN #parameters p ON rr.ID=p.ResultMeasurementID
			LEFT OUTER JOIN #information i ON i.RID = rr.ResultID
		
		ALTER TABLE #preSelect DROP COLUMN ID, ResultMeasurementID, ResultID
		
		SELECT * FROM #preSelect
		
		DROP TABLE #parameters
		DROP TABLE #information
		DROP TABLE #RequestResults
		DROP TABLE #preSelect
	END
	ELSE
	BEGIN
		SET @sql = 'SELECT r.* FROM #Request r '
		PRINT @sql
		EXEC (@sql)
	END	
	
	DROP TABLE #temp
	DROP TABLE #Request
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Req].[RequestSearch] TO REMI
GO
--DECLARE @table AS dbo.SearchFields
--INSERT INTO @table(TableType, ID, SearchTerm)
--VALUES ('Request', 51, 'Windermere B R132')
-- ,('Request', 51, 'Windermere E R135')
-- --,('Request', 51, 'Lisbon R070')
-- --,('Request', 49, 'Handheld')
---- --,('Test', 1099, 'Sensor Test')
--,('Test', 1280, 'Functional')
--, ('Test', 1020, 'Radiated RF Test')
------ --,('Test', 1103, 'Camera Front')
--,('Stage', 3218, 'Post 360hrs')
----,('Stage', 3220, 'Post 720hrs')
----,('BSN', 0, '1151185790')
--,('Unit', 0, '5')
--,('Unit', 0, '1')
----,('IMEI', 0, '')
----,('ResultArchived', 0, '')
----,('ResultInfoArchived', 0, '')
--, ('TestRunStartDate', 0, '2014-04-11 08:56:12.000')
--, ('TestRunEndDate', 0, '2014-06-13 12:48:08.000')
--EXEC [Req].[RequestSearch] 1, @table
