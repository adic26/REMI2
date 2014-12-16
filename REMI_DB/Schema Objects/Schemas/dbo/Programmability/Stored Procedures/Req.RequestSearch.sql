ALTER PROCEDURE [Req].[RequestSearch] @RequestTypeID INT, @tv dbo.SearchFields READONLY, @UserID INT = NULL
AS
BEGIN
	SET NOCOUNT ON
	CREATE TABLE dbo.#executeSQL (ID INT IDENTITY(1,1), sqlvar NTEXT)
	CREATE TABLE dbo.#Request (RequestID INT PRIMARY KEY, BatchID INT, RequestNumber NVARCHAR(11))

	SELECT * INTO dbo.#temp FROM @tv

	UPDATE t
	SET t.ColumnName= '[' + rfs.Name + ']'
	FROM Req.ReqFieldSetup rfs WITH(NOLOCK)
		INNER JOIN dbo.#temp t WITH(NOLOCK) ON rfs.ReqFieldSetupID=t.ID
	WHERE rfs.RequestTypeID=@RequestTypeID AND t.TableType='Request'

	DECLARE @ColumnName NVARCHAR(255)
	DECLARE @whereStr NVARCHAR(MAX)
	DECLARE @rows NVARCHAR(MAX)
	DECLARE @ParameterColumnNames NVARCHAR(MAX)
	DECLARE @InformationColumnNames NVARCHAR(MAX)
	DECLARE @SQL NVARCHAR(MAX)

	SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + rfs.Name
		FROM Req.ReqFieldSetup rfs WITH(NOLOCK)
		WHERE rfs.RequestTypeID=@RequestTypeID
		ORDER BY '],[' +  rfs.Name
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

	SET @SQL = 'ALTER TABLE dbo.#Request ADD '+ replace(@rows, ']', '] NVARCHAR(4000)')
	EXEC sp_executesql @SQL	

	INSERT INTO #executeSQL (sqlvar)
	VALUES ('INSERT INTO dbo.#Request SELECT *
		FROM 
			(
			SELECT r.RequestID, r.BatchID, r.RequestNumber, rfd.Value, rfs.Name 
			FROM Req.Request r WITH(NOLOCK)
				INNER JOIN Req.ReqFieldData rfd WITH(NOLOCK) ON rfd.RequestID=r.RequestID
				INNER JOIN Req.ReqFieldSetup rfs WITH(NOLOCK) ON rfs.ReqFieldSetupID=rfd.ReqFieldSetupID
				INNER JOIN Req.RequestType rt WITH(NOLOCK) ON rt.RequestTypeID=rfs.RequestTypeID
			WHERE rt.RequestTypeID=' + CONVERT(NVARCHAR, @RequestTypeID) + '
			) req PIVOT (MAX(Value) FOR Name IN (' + REPLACE(@rows, ',', ',
			') + ')) AS pvt ')

	IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType='Request') > 0)
	BEGIN
		INSERT INTO #executeSQL (sqlvar)
		VALUES (' WHERE ')

		DECLARE @ID INT
		SELECT @ID = MIN(ID) FROM dbo.#temp WHERE TableType='Request'

		WHILE (@ID IS NOT NULL)
		BEGIN
			INSERT INTO #executeSQL (sqlvar)
			VALUES ('
				(')

			IF ((SELECT TOP 1 1 FROM dbo.#temp WHERE ID = @ID AND TableType='Request' AND LTRIM(RTRIM(SearchTerm)) NOT LIKE '-%') = 1)
			BEGIN
				INSERT INTO #executeSQL (sqlvar)
				VALUES ('
						(')
			END

			DECLARE @NOLIKE INT
			SET @NOLIKE = 0
			SET @ColumnName = ''
			SET @whereStr = ''
			SELECT @ColumnName=ColumnName FROM dbo.#temp WHERE ID = @ID AND TableType='Request'

			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(SearchTerm)) + ''','
			FROM dbo.#temp
			WHERE ID = @ID AND TableType='Request' AND LTRIM(RTRIM(SearchTerm)) NOT LIKE '*%' AND LTRIM(RTRIM(SearchTerm)) NOT LIKE '-%'

			IF (LEN(LTRIM(RTRIM(@whereStr))) > 0)
			BEGIN
				INSERT INTO #executeSQL (sqlvar)
				VALUES (@ColumnName + ' IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')')
				SET @NOLIKE = 1
			END

			SET @whereStr = ''
			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(SearchTerm)) + ''','
			FROM dbo.#temp
			WHERE ID = @ID AND TableType='Request' AND LTRIM(RTRIM(SearchTerm)) LIKE '*%'

			SET @whereStr = REPLACE(REPLACE(REPLACE(@whereStr, '''*', 'LIKE ''%'), ''',', '%'''), 'LIKE ', ' OR ' + @ColumnName + ' LIKE ')

			IF (LEN(LTRIM(RTRIM(@whereStr))) > 0)
			BEGIN
				INSERT INTO #executeSQL (sqlvar)
				VALUES (CASE WHEN @NOLIKE = 0 THEN SUBSTRING(@whereStr,4, LEN(@whereStr)) ELSE @whereStr END)
			END

			IF ((SELECT TOP 1 1 FROM dbo.#temp WHERE ID = @ID AND TableType='Request' AND LTRIM(RTRIM(SearchTerm)) NOT LIKE '-%') = 1)
			BEGIN
				INSERT INTO #executeSQL (sqlvar)
				VALUES (')
						')
			END

			SET @whereStr = ''
			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(SearchTerm)) + ''','
			FROM dbo.#temp
			WHERE ID = @ID AND TableType='Request' AND LTRIM(RTRIM(SearchTerm)) LIKE '-%'

			SET @whereStr = REPLACE(REPLACE(REPLACE(@whereStr, '''-', 'NOT LIKE ''%'), ''',', '%'''), 'NOT LIKE ', ' AND ' + @ColumnName + ' NOT LIKE ')

			IF (LEN(LTRIM(RTRIM(@whereStr))) > 0)
			BEGIN
				IF ((SELECT TOP 1 1 FROM dbo.#temp WHERE ID = @ID AND TableType='Request' AND LTRIM(RTRIM(SearchTerm)) NOT LIKE '-%') = 1)
				BEGIN
					INSERT INTO #executeSQL (sqlvar)
					VALUES (@whereStr)
				END
				ELSE
				BEGIN
					INSERT INTO #executeSQL (sqlvar)
					VALUES (SUBSTRING(@whereStr, 6, LEN(@whereStr)))
				END
			END

			INSERT INTO #executeSQL (sqlvar)
			VALUES ('
				) AND ')

			SELECT @ID = MIN(ID) FROM dbo.#temp WHERE ID > @ID AND TableType='Request'
		END

		INSERT INTO #executeSQL (sqlvar)
		VALUES (' 1=1 ')
		--SET @sql = SUBSTRING(@sql, 0, LEN(@sql)-2)
	END

	SET @SQL =  REPLACE((select sqlvar AS [text()] from dbo.#executeSQL for xml path('')), '&#x0D;','')
	EXEC sp_executesql @SQL

	IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType <> 'Request') > 0)
	BEGIN
		SET @SQL = ''
		TRUNCATE TABLE dbo.#executeSQL

		CREATE TABLE dbo.#RequestResults (RequestID INT, BatchID INT, RequestNumber NVARCHAR(11), BatchUnitNumber INT, IMEI NVARCHAR(150), BSN BIGINT, ID INT, ResultID INT, XMLID INT)
		CREATE TABLE dbo.#parameters (ResultMeasurementID INT)
		CREATE TABLE dbo.#information (RID INT, ResultInfoArchived BIT)
		
		CREATE INDEX [Request_BatchID] ON dbo.#Request([BatchID])

		SET @SQL = 'ALTER TABLE dbo.#RequestResults ADD ' + replace(@rows, ']', '] NVARCHAR(4000)')
		EXEC sp_executesql @SQL

		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType IN ('Test', 'Stage')) > 0)
		BEGIN
			ALTER TABLE dbo.#RequestResults ADD TestName NVARCHAR(400), TestStageName NVARCHAR(400), 
				TestRunStartDate DATETIME, TestRunEndDate DATETIME, 
				MeasurementName NVARCHAR(150), MeasurementValue NVARCHAR(500), 
				UpperLimit NVARCHAR(255), LowerLimit NVARCHAR(255), Archived BIT, Comment NVARCHAR(400), 
				DegradationVal DECIMAL(10,3), Description NVARCHAR(800), PassFail BIT, ReTestNum INT,
				MeasurementUnitType NVARCHAR(150)
		END

		SET @rows = REPLACE(@rows, '[', 'r.[')

		INSERT INTO #executeSQL (sqlvar)
		VALUES ('INSERT INTO dbo.#RequestResults 
		SELECT r.RequestID, r.BatchID, r.RequestNumber, tu.BatchUnitNumber, tu.IMEI, tu.BSN, ')

		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType IN ('Test', 'Stage')) > 0)
		BEGIN
			INSERT INTO #executeSQL (sqlvar)
			VALUES ('m.ID, rs.ID AS ResultID, x.ID AS XMLID, ')
		END
		ELSE
		BEGIN
			INSERT INTO #executeSQL (sqlvar)
			VALUES (', 0 AS ID, 0 AS ResultID, 0 AS XMLID, ')
		END

		INSERT INTO #executeSQL (sqlvar)
		VALUES (@rows)

		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType IN ('Test', 'Stage')) > 0)
		BEGIN
			INSERT INTO #executeSQL (sqlvar)
			VALUES (', t.TestName, ts.TestStageName, x.StartDate AS TestRunStartDate, x.EndDate AS TestRunEndDate, 
				mn.[Values] As MeasurementName, m.MeasurementValue, m.UpperLimit, m.LowerLimit, m.Archived, m.Comment, m.DegradationVal, m.Description, m.PassFail, m.ReTestNum, 
				mut.[Values] As MeasurementUnitType ')
		END

		INSERT INTO #executeSQL (sqlvar)
		VALUES ('FROM dbo.#Request r WITH(NOLOCK)
			INNER JOIN dbo.Batches b WITH(NOLOCK) ON b.ID=r.BatchID
			INNER JOIN dbo.TestUnits tu WITH(NOLOCK) ON tu.BatchID=b.ID ')

		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType IN ('Test', 'Stage', 'Measurement')) > 0)
		BEGIN
			DECLARE @ResultArchived INT
			DECLARE @TestRunStartDate DATETIME
			DECLARE @TestRunEndDate DATETIME

			SELECT @ResultArchived = ID FROM dbo.#temp WHERE TableType='ResultArchived'
			SELECT @TestRunStartDate = SearchTerm FROM dbo.#temp WHERE TableType='TestRunStartDate'
			SELECT @TestRunEndDate = SearchTerm FROM dbo.#temp WHERE TableType='TestRunEndDate'

			IF @ResultArchived IS NULL
				SET @ResultArchived = 0

			INSERT INTO #executeSQL (sqlvar)
			VALUES ('INNER JOIN Relab.Results rs WITH(NOLOCK) ON rs.TestUnitID=tu.ID
				INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) ON m.ResultID=rs.ID
				INNER JOIN dbo.Lookups mn WITH(NOLOCK) ON mn.LookupID = m.MeasurementTypeID 
				INNER JOIN dbo.Lookups mut WITH(NOLOCK) ON mut.LookupID = m.MeasurementUnitTypeID 
				INNER JOIN dbo.Tests t WITH(NOLOCK) ON rs.TestID=t.ID
				INNER JOIN dbo.TestStages ts WITH(NOLOCK) ON rs.TestStageID=ts.ID
				INNER JOIN Relab.ResultsXML x WITH(NOLOCK) ON x.ID=m.XMLID
			WHERE ((' + CONVERT(NVARCHAR,@ResultArchived) + ' = 0 AND m.Archived=0) OR (' + CONVERT(NVARCHAR, @ResultArchived) + '=1)) ')

			IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType = 'Measurement') > 0)
			BEGIN				
				SET @whereStr = ''
				SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(SearchTerm)) + ''','
				FROM dbo.#temp
				WHERE TableType='Measurement' AND LTRIM(RTRIM(SearchTerm)) LIKE '*%'

				SET @whereStr = REPLACE(REPLACE(REPLACE(@whereStr, '''*', 'LIKE ''%'), ''',', '%'''), 'LIKE ', ' OR mn.[Values] LIKE ')

				INSERT INTO #executeSQL (sqlvar)
				VALUES ('AND ( ' + SUBSTRING(@whereStr,4, LEN(@whereStr)) + ' )')
			END

			IF (@TestRunStartDate IS NOT NULL AND @TestRunEndDate IS NOT NULL)
			BEGIN
				INSERT INTO #executeSQL (sqlvar)
				VALUES (' AND x.StartDate BETWEEN ''' + CONVERT(NVARCHAR,@TestRunStartDate) + ''' AND ''' + CONVERT(NVARCHAR,@TestRunEndDate) + ''' ')
			END
		END

		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType='Unit') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(ISNULL(SearchTerm, ''))) + ''','
			FROM dbo.#temp
			WHERE TableType = 'Unit'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND tu.BatchUnitNumber IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')')
		END

		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType='IMEI') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(ISNULL(SearchTerm, ''))) + ''','
			FROM dbo.#temp
			WHERE TableType = 'IMEI'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND tu.IMEI IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')')
		END

		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType='BSN') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(SearchTerm)) + ''','
			FROM dbo.#temp
			WHERE TableType = 'BSN'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND tu.BSN IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')')
		END

		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType='Test') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + LTRIM(RTRIM(ID)) + ','
			FROM dbo.#temp
			WHERE TableType = 'Test'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND t.ID IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')')
		END

		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType='Stage') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + LTRIM(RTRIM(ID)) + ','
			FROM dbo.#temp
			WHERE TableType = 'Stage'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND ts.ID IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ') ')
		END

		SET @SQL =  REPLACE(REPLACE((select sqlvar AS [text()] from dbo.#executeSQL for xml path('')), '&#x0D;',''), '&gt;', ' > ')
		EXEC sp_executesql @SQL
		SET @SQL = ''
		TRUNCATE TABLE dbo.#executeSQL

		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType IN ('Test', 'Stage', 'Measurement')) > 0)
		BEGIN
			SELECT @ParameterColumnNames=  ISNULL(STUFF(
			( 
			SELECT DISTINCT '],[' + rp.ParameterName
			FROM dbo.#RequestResults rr WITH(NOLOCK)
				LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rr.ID=rp.ResultMeasurementID
			WHERE rp.ParameterName <> 'Command'
			ORDER BY '],[' +  rp.ParameterName
			FOR XML PATH('')), 1, 2, '') + ']','[na]')

			IF (@ParameterColumnNames <> '[na]')
			BEGIN
				SET @SQL = 'ALTER TABLE dbo.#parameters ADD ' + replace(@ParameterColumnNames, ']', '] NVARCHAR(250)')
				EXEC sp_executesql @SQL

				SET @SQL = 'INSERT INTO dbo.#parameters SELECT *
				FROM (
					SELECT rp.ResultMeasurementID, rp.ParameterName, rp.Value
					FROM dbo.#RequestResults rr WITH(NOLOCK)
						INNER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rr.ID=rp.ResultMeasurementID
					) te PIVOT (MAX(Value) FOR ParameterName IN (' + @ParameterColumnNames + ')) AS pvt'

				EXEC sp_executesql @SQL
			END
			ELSE
			BEGIN
				SET @ParameterColumnNames = NULL
			END

			DECLARE @ResultInfoArchived INT
			SELECT @ResultInfoArchived = ID FROM dbo.#temp WHERE TableType='ResultInfoArchived'

			IF @ResultInfoArchived IS NULL
				SET @ResultInfoArchived = 0

			SELECT @InformationColumnNames=  ISNULL(STUFF(
			( 
			SELECT DISTINCT '],[' + ri.Name
			FROM dbo.#RequestResults rr WITH(NOLOCK)
				INNER JOIN Relab.ResultsXML x WITH(NOLOCK) ON x.ResultID = rr.ResultID
				LEFT OUTER JOIN Relab.ResultsInformation ri WITH(NOLOCK) ON x.ID=ri.XMLID
			WHERE ri.Name NOT IN ('Start UTC','Start','End', 'STEF Plugin Version')
				AND ((@ResultInfoArchived = 0 AND ri.IsArchived=0) OR (@ResultInfoArchived=1))
			ORDER BY '],[' +  ri.Name
			FOR XML PATH('')), 1, 2, '') + ']','[na]')

			IF (@InformationColumnNames <> '[na]')
			BEGIN
				SET @SQL = 'ALTER TABLE dbo.#information ADD ' + replace(@InformationColumnNames, ']', '] NVARCHAR(250)')
				EXEC sp_executesql @SQL

				SET @SQL = N'INSERT INTO dbo.#information SELECT *
				FROM (
					SELECT rr.ResultID AS RID, ri.IsArchived AS ResultInfoArchived, ri.Name, ri.Value
					FROM dbo.#RequestResults rr WITH(NOLOCK)
						INNER JOIN Relab.ResultsInformation ri WITH(NOLOCK) ON rr.XMLID=ri.XMLID
						WHERE ri.Name NOT IN (''Start UTC'',''Start'',''End'', ''STEF Plugin Version'') AND
							((@ResultInfoArchived = 0 AND ri.IsArchived=0) OR (@ResultInfoArchived=1)) 
					) te PIVOT (MAX(Value) FOR Name IN ('+ @InformationColumnNames +')) AS pvt'

				EXEC sp_executesql @SQL, N'@ResultInfoArchived int', @ResultInfoArchived
			END
			ELSE
			BEGIN
				SET @InformationColumnNames = NULL
			END
		END

		SET @whereStr = ''

		IF (@UserID > 0 AND @UserID IS NOT NULL)
		BEGIN
			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + LTRIM(RTRIM(ColumnName)) + ','
			FROM dbo.UserSearchFilter
			WHERE UserID=@UserID AND RequestTypeID=@RequestTypeID
			ORDER BY SortOrder
		END

		SET @whereStr = REPLACE(REPLACE(@whereStr 
				, 'Params', CASE WHEN (SELECT 1 FROM UserSearchFilter WHERE FilterType=3) = 1 THEN @ParameterColumnNames ELSE '' END)
				, 'Info', CASE WHEN (SELECT 1 FROM UserSearchFilter WHERE FilterType=4) = 1 THEN @InformationColumnNames ELSE '' END)

		IF (ISNULL(@whereStr, '') = '')
		BEGIN
			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + '[' + COLUMN_NAME + '],' 
			FROM tempdb.INFORMATION_SCHEMA.COLUMNS 
			WHERE (TABLE_NAME like '#RequestResults%' OR TABLE_NAME LIKE '#parameters%' OR TABLE_NAME LIKE '#information%')
				AND COLUMN_NAME NOT IN ('RequestID', 'XMLID', 'ID', 'BatchID', 'ResultMeasurementID', 'ResultID', 'RID')
		END

		SET @SQL = 'SELECT DISTINCT ' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ' FROM dbo.#RequestResults rr 
			LEFT OUTER JOIN dbo.#parameters p ON rr.ID=p.ResultMeasurementID
			LEFT OUTER JOIN dbo.#information i ON i.RID = rr.ResultID '
		EXEC sp_executesql @SQL

		DROP TABLE dbo.#parameters
		DROP TABLE dbo.#information
		DROP TABLE dbo.#RequestResults
	END
	ELSE
	BEGIN
		SET @whereStr = ''

		IF (@UserID > 0 AND @UserID IS NOT NULL)
		BEGIN
			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + LTRIM(RTRIM(ColumnName)) + ','
			FROM dbo.UserSearchFilter
			WHERE UserID=@UserID AND FilterType = 1 AND RequestTypeID=@RequestTypeID 
			ORDER BY SortOrder
		END

		IF (ISNULL(@whereStr, '') = '')
		BEGIN
			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + '[' + COLUMN_NAME + '],' 
			FROM tempdb.INFORMATION_SCHEMA.COLUMNS 
			WHERE (TABLE_NAME like '#Request%')
				AND COLUMN_NAME NOT IN ('RequestID', 'BatchID')
		END

		SET @SQL = 'SELECT DISTINCT ' +  SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ' FROM dbo.#Request r '

		EXEC sp_executesql @SQL
	END

	DROP TABLE dbo.#executeSQL
	DROP TABLE dbo.#temp
	DROP TABLE dbo.#Request
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Req].[RequestSearch] TO REMI
GO
--DECLARE @table AS dbo.SearchFields
--INSERT INTO @table(TableType, ID, SearchTerm)
--VALUES ('Request', 51, '*Windermere')
----,('Request', 51, '-Windermere E R135')
----,('Request', 51, '3G SIMs')
---- ,('Request', 51, '*Lisbon')
----,('Request', 49, 'Handheld')
----,('Request', 49, '*Accessory')
-- --,('Test', 1099, 'Sensor Test')
----,('Test', 1280, 'Functional')
--,('Test', 1020, 'Radiated RF Test')
------ --,('Test', 1103, 'Camera Front')
----,('Stage', 3218, 'Post 360hrs')
----,('Stage', 2246, 'Analysis')
----,('Stage', 3220, 'Post 720hrs')
----,('BSN', 0, '1151185790')
----,('Unit', 0, '5')
----,('Unit', 0, '1')
--------,('IMEI', 0, '')
----,('ResultArchived', 0, '')
--------,('ResultInfoArchived', 0, '')
----, ('TestRunStartDate', 0, '2014-04-11 08:56:12.000')
----, ('TestRunEndDate', 0, '2014-06-13 12:48:08.000')
----,('Measurement', 0, '*RxBER')
--EXEC [Req].[RequestSearch] 1, @table--, 251