ALTER PROCEDURE [Req].[RequestSearch] @RequestTypeID INT, @tv dbo.SearchFields READONLY, @UserID INT = NULL
AS
BEGIN
	SET NOCOUNT ON
	CREATE TABLE dbo.#executeSQL (ID INT IDENTITY(1,1), sqlvar NTEXT)
	CREATE TABLE dbo.#Request (RequestID INT PRIMARY KEY, BatchID INT, RequestNumber NVARCHAR(11))
	CREATE TABLE dbo.#Infos (Name NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS, Val NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS)
	CREATE TABLE dbo.#Params (Name NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS, Val NVARCHAR(250) COLLATE SQL_Latin1_General_CP1_CI_AS)
	CREATE TABLE dbo.#ReqNum (RequestNumber NVARCHAR(11) COLLATE SQL_Latin1_General_CP1_CI_AS)

	SELECT * INTO dbo.#temp FROM @tv
	
	UPDATE t
	SET t.ColumnName= '[' + rfs.Name + ']'
	FROM Req.ReqFieldSetup rfs WITH(NOLOCK)
		INNER JOIN dbo.#temp t WITH(NOLOCK) ON rfs.ReqFieldSetupID=t.ID
	WHERE rfs.RequestTypeID=@RequestTypeID AND t.TableType='Request'
	
	DECLARE @ProductGroupColumn NVARCHAR(150) 
	DECLARE @DepartmentColumn NVARCHAR(150)
	DECLARE @ColumnName NVARCHAR(255)
	DECLARE @whereStr NVARCHAR(MAX)
	DECLARE @whereStr2 NVARCHAR(MAX)
	DECLARE @whereStr3 NVARCHAR(MAX)
	DECLARE @rows NVARCHAR(MAX)
	DECLARE @ParameterColumnNames NVARCHAR(MAX)
	DECLARE @InformationColumnNames NVARCHAR(MAX)
	DECLARE @SQL NVARCHAR(MAX)
	DECLARE @RecordCount INT
	DECLARE @ByPassProductCheck INT
	SELECT @RecordCount = COUNT(*) FROM dbo.#temp 
	SET @ByPassProductCheck = 0
	SELECT @ByPassProductCheck = u.ByPassProduct FROM Users u WITH(NOLOCK) WHERE u.ID=@UserID
	
	SELECT @ProductGroupColumn = fs.Name
	FROM Req.ReqFieldSetup fs WITH(NOLOCK)
		INNER JOIN Req.ReqFieldMapping fm WITH(NOLOCK) ON fs.Name=fm.ExtField AND fs.RequestTypeID=fm.RequestTypeID
	WHERE fs.RequestTypeID = @RequestTypeID AND fm.IntField='ProductGroup'
	
	SELECT @DepartmentColumn = fs.Name
	FROM Req.ReqFieldSetup fs WITH(NOLOCK)
		INNER JOIN Req.ReqFieldMapping fm WITH(NOLOCK) ON fs.Name=fm.ExtField AND fs.RequestTypeID=fm.RequestTypeID
	WHERE fs.RequestTypeID = @RequestTypeID AND fm.IntField='Department'
	
	SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + rfs.Name
		FROM Req.ReqFieldSetup rfs WITH(NOLOCK)
		WHERE rfs.RequestTypeID=@RequestTypeID AND ISNULL(rfs.Archived, 0) = CONVERT(BIT, 0)
		ORDER BY '],[' +  rfs.Name
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

	SET @SQL = 'ALTER TABLE dbo.#Request ADD '+ replace(@rows, ']', '] NVARCHAR(4000)')
	EXEC sp_executesql @SQL	
	
	IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType = 'ReqNum') > 0)
		BEGIN
			INSERT INTO dbo.#ReqNum (RequestNumber)
			SELECT SearchTerm
			FROM dbo.#temp WITH(NOLOCK)
			WHERE TableType = 'ReqNum'
		END

	SET @SQL = 'INSERT INTO dbo.#Request SELECT *
		FROM 
			(
			SELECT r.RequestID, r.BatchID, r.RequestNumber, rfd.Value, rfs.Name
			FROM Req.Request r WITH(NOLOCK)
				INNER JOIN Req.ReqFieldData rfd WITH(NOLOCK) ON rfd.RequestID=r.RequestID
				INNER JOIN Req.ReqFieldSetup rfs WITH(NOLOCK) ON rfs.ReqFieldSetupID=rfd.ReqFieldSetupID
				INNER JOIN Req.RequestType rt WITH(NOLOCK) ON rt.RequestTypeID=rfs.RequestTypeID '
			
			IF ((SELECT COUNT(*) FROM dbo.#ReqNum) > 0)
				BEGIN
					SET @SQL += ' INNER JOIN dbo.#ReqNum rn WITH(NOLOCK) ON rn.RequestNumber=r.RequestNumber '
				END
				
			SET @SQL += ' WHERE rt.RequestTypeID=' + CONVERT(NVARCHAR, @RequestTypeID)
			IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType IN ('BSN','IMEI')) > 0 AND (SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType NOT IN ('BSN','IMEI')) = 0)
			BEGIN
				SET @SQL += ' AND r.BatchID IN 
					(SELECT b.ID 
					FROM dbo.Batches b WITH(NOLOCK)
						INNER JOIN dbo.TestUnits tu WITH(NOLOCK) ON b.ID=tu.BatchID 
					WHERE b.QRANumber = r.RequestNumber AND ('

				IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType='BSN') > 0)
				BEGIN
					SET @whereStr = ''

					SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(ISNULL(SearchTerm, ''))) + ''','
					FROM dbo.#temp WITH(NOLOCK)
					WHERE TableType = 'BSN'

					SET @SQL += ' tu.BSN IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ') '
				END
				
				IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType='IMEI') > 0)
				BEGIN
					SET @whereStr = ''

					SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(SearchTerm)) + ''','
					FROM dbo.#temp WITH(NOLOCK)
					WHERE TableType = 'IMEI'
					
					IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType='BSN') > 0)
					BEGIN
						SET @SQL += ' OR '
					END

					SET @SQL += 'tu.IMEI IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ') '
				END
				
				SET @SQL += ' ) ) '
			END			
			
			SET @SQL += ' ) req PIVOT (MAX(Value) FOR Name IN (' + REPLACE(@rows, ',', ',
			') + ')) AS pvt '

	INSERT INTO #executeSQL (sqlvar)
	VALUES (@SQL)

	SET @SQL = ''
	
	IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType='Request') > 0)
	BEGIN
		INSERT INTO #executeSQL (sqlvar)
		VALUES (' WHERE ')

		DECLARE @ID INT
		SELECT @ID = MIN(ID) FROM dbo.#temp WITH(NOLOCK) WHERE TableType='Request'

		WHILE (@ID IS NOT NULL)
		BEGIN
			INSERT INTO #executeSQL (sqlvar)
			VALUES ('
				(')

			IF ((SELECT TOP 1 1 FROM dbo.#temp WITH(NOLOCK) WHERE ID = @ID AND TableType='Request' AND LTRIM(RTRIM(SearchTerm)) NOT LIKE '-%') = 1)
			BEGIN
				INSERT INTO #executeSQL (sqlvar)
				VALUES ('
						(')
			END

			DECLARE @NOLIKE INT
			SET @NOLIKE = 0
			SET @ColumnName = ''
			SET @whereStr = ''
			SELECT @ColumnName=ColumnName FROM dbo.#temp WITH(NOLOCK) WHERE ID = @ID AND TableType='Request'

			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(SearchTerm)) + ''','
			FROM dbo.#temp WITH(NOLOCK)
			WHERE ID = @ID AND TableType='Request' AND LTRIM(RTRIM(SearchTerm)) NOT LIKE '*%' AND LTRIM(RTRIM(SearchTerm)) NOT LIKE '-%'

			IF (LEN(LTRIM(RTRIM(@whereStr))) > 0)
			BEGIN
				INSERT INTO #executeSQL (sqlvar)
				VALUES (@ColumnName + ' IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')')
				SET @NOLIKE = 1
			END

			SET @whereStr = ''
			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(SearchTerm)) + ''','
			FROM dbo.#temp WITH(NOLOCK)
			WHERE ID = @ID AND TableType='Request' AND LTRIM(RTRIM(SearchTerm)) LIKE '*%'

			SET @whereStr = REPLACE(REPLACE(REPLACE(@whereStr, '''*', 'LIKE ''%'), ''',', '%'''), 'LIKE ', ' OR ' + @ColumnName + ' LIKE ')

			IF (LEN(LTRIM(RTRIM(@whereStr))) > 0)
			BEGIN
				INSERT INTO #executeSQL (sqlvar)
				VALUES (CASE WHEN @NOLIKE = 0 THEN SUBSTRING(@whereStr,4, LEN(@whereStr)) ELSE @whereStr END)
			END

			IF ((SELECT TOP 1 1 FROM dbo.#temp WITH(NOLOCK) WHERE ID = @ID AND TableType='Request' AND LTRIM(RTRIM(SearchTerm)) NOT LIKE '-%') = 1)
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
				IF ((SELECT TOP 1 1 FROM dbo.#temp WITH(NOLOCK) WHERE ID = @ID AND TableType='Request' AND LTRIM(RTRIM(SearchTerm)) NOT LIKE '-%') = 1)
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

			SELECT @ID = MIN(ID) FROM dbo.#temp WITH(NOLOCK) WHERE ID > @ID AND TableType='Request'
		END

		INSERT INTO #executeSQL (sqlvar)
		VALUES (' 1=1 ')
	END

	SET @SQL = REPLACE((select sqlvar AS [text()] from dbo.#executeSQL for xml path('')), '&#x0D;','')

	EXEC sp_executesql @SQL
	SET @SQL = ''
	
	IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType LIKE 'Batch%') > 0 AND (SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType='Request') > 0)
	BEGIN
		SET @SQL = 'DELETE FROM #Request WHERE RequestNumber NOT IN (SELECT DISTINCT RequestNumber
		FROM #Request r
			INNER JOIN Batches b ON r.RequestNumber=b.QRANumber
			LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName 
			INNER JOIN TestStages ts WITH(NOLOCK) ON ts.TestStageName=b.TestStageName
		WHERE 1=1 '
		
		IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType='BatchStageType') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(ISNULL(SearchTerm, ''))) + ''','
			FROM dbo.#temp WITH(NOLOCK)
			WHERE TableType = 'BatchStageType'

			SET @SQL += ' AND ts.TestStageType IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')'
		END
		
		IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType='BatchAssignedUser') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(ISNULL(SearchTerm, ''))) + ''','
			FROM dbo.#temp WITH(NOLOCK)
			WHERE TableType = 'BatchAssignedUser'

			SET @SQL += ' AND (
							SELECT top 1 u.ldaplogin 
							FROM TestUnits as tu WITH(NOLOCK), devicetrackinglog as dtl WITH(NOLOCK), TrackingLocations as tl WITH(NOLOCK), Users u WITH(NOLOCK)
							WHERE tl.ID = dtl.TrackingLocationID and tu.id  = dtl.testunitid and tu.batchid = b.id and  inuser = u.LDAPLogin and outuser is null
						  ) IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')'
		END

		IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType='BatchStatus') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(ISNULL(SearchTerm, ''))) + ''','
			FROM dbo.#temp WITH(NOLOCK)
			WHERE TableType = 'BatchStatus'

			SET @SQL += ' AND b.BatchStatus IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')'
		END
		
		DECLARE @BatchStartDate NVARCHAR(12)
		DECLARE @BatchEndDate NVARCHAR(12)

		SELECT @BatchStartDate = SearchTerm FROM dbo.#temp WITH(NOLOCK) WHERE TableType='BatchStartDate'
		SELECT @BatchEndDate = SearchTerm FROM dbo.#temp WITH(NOLOCK) WHERE TableType='BatchEndDate'
		
		IF (@BatchStartDate IS NOT NULL AND @BatchEndDate IS NOT NULL)
		BEGIN
			SET @SQL += ' AND b.ID IN (SELECT DISTINCT batchid FROM BatchesAudit WITH(NOLOCK) WHERE InsertTime >= ''' + CONVERT(NVARCHAR,@BatchStartDate) + ' 00:00:00.000'' AND InsertTime <= ''' + CONVERT(NVARCHAR,@BatchEndDate) + ' 23:59:59'') '
		END
		
		SET @SQL += ')'
		
		EXEC sp_executesql @SQL
		SET @SQL = ''
	END

	--START BUILDING MEASUREMENTS
	IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType NOT IN ('Request','ReqNum', 'IMEI', 'BSN') AND TableType NOT LIKE 'Batch%') > 0)
	BEGIN
		SET @SQL = ''
		TRUNCATE TABLE dbo.#executeSQL

		CREATE TABLE dbo.#RR (RequestID INT, BatchID INT, RequestNumber NVARCHAR(11), BatchUnitNumber INT, UnitIMEI NVARCHAR(150), UnitBSN BIGINT, ID INT, ResultID INT, XMLID INT)
		CREATE TABLE dbo.#RRParameters (ResultMeasurementID INT)
		CREATE TABLE dbo.#RRInformation (RID INT, ResultInfoArchived BIT)
		
		CREATE INDEX [Request_BatchID] ON dbo.#Request([BatchID])

		SET @SQL = 'ALTER TABLE dbo.#RR ADD ' + replace(@rows, ']', '] NVARCHAR(4000)')
		EXEC sp_executesql @SQL

		ALTER TABLE dbo.#RR ADD ResultLink NVARCHAR(100), TestName NVARCHAR(400), TestStageName NVARCHAR(400), 
			TestRunStartDate DATETIME, TestRunEndDate DATETIME, 
			MeasurementName NVARCHAR(150), MeasurementValue NVARCHAR(500), 
			LowerLimit NVARCHAR(255), UpperLimit NVARCHAR(255), Archived BIT, Comment NVARCHAR(1000), 
			DegradationVal DECIMAL(10,3), MeasurementDescription NVARCHAR(800), PassFail BIT, ReTestNum INT,
			MeasurementUnitType NVARCHAR(150)

		INSERT INTO #executeSQL (sqlvar)
		VALUES ('INSERT INTO dbo.#RR 
		SELECT r.RequestID, r.BatchID, r.RequestNumber, tu.BatchUnitNumber, tu.IMEI, tu.BSN, m.ID, rs.ID AS ResultID, x.ID AS XMLID, ')

		SET @rows = REPLACE(@rows, '[', 'r.[')
		INSERT INTO #executeSQL (sqlvar)
		VALUES (@rows)

		INSERT INTO #executeSQL (sqlvar)
		VALUES (', (''http://go/remi/Relab/Measurements.aspx?ID='' + CONVERT(VARCHAR, rs.ID) + ''&Batch='' + CONVERT(VARCHAR, b.ID)) AS ResultLink ')
		
		INSERT INTO #executeSQL (sqlvar)
		VALUES (', t.TestName, ts.TestStageName, x.StartDate AS TestRunStartDate, x.EndDate AS TestRunEndDate, 
			mn.[Values] As MeasurementName, m.MeasurementValue, m.LowerLimit, m.UpperLimit, m.Archived, m.Comment, m.DegradationVal, m.Description AS MeasurementDescription, m.PassFail, m.ReTestNum, 
			mut.[Values] As MeasurementUnitType ')

		INSERT INTO #executeSQL (sqlvar)
		VALUES (' FROM dbo.#Request r WITH(NOLOCK)
			INNER JOIN dbo.Batches b WITH(NOLOCK) ON b.ID=r.BatchID
			INNER JOIN dbo.TestUnits tu WITH(NOLOCK) ON tu.BatchID=b.ID ')

		DECLARE @ResultArchived INT
		DECLARE @TestRunStartDate NVARCHAR(12)
		DECLARE @TestRunEndDate NVARCHAR(12)

		SELECT @ResultArchived = ID FROM dbo.#temp WITH(NOLOCK) WHERE TableType='ResultArchived'
		SELECT @TestRunStartDate = SearchTerm FROM dbo.#temp WITH(NOLOCK) WHERE TableType='TestRunStartDate'
		SELECT @TestRunEndDate = SearchTerm FROM dbo.#temp WITH(NOLOCK) WHERE TableType='TestRunEndDate'

		IF @ResultArchived IS NULL
			SET @ResultArchived = 0

		INSERT INTO #executeSQL (sqlvar)
		VALUES ('INNER JOIN Relab.Results rs WITH(NOLOCK) ON rs.TestUnitID=tu.ID
			INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) ON m.ResultID=rs.ID
			INNER JOIN dbo.Lookups mn WITH(NOLOCK) ON mn.LookupID = m.MeasurementTypeID 
			LEFT OUTER JOIN dbo.Lookups mut WITH(NOLOCK) ON mut.LookupID = m.MeasurementUnitTypeID 
			INNER JOIN dbo.Tests t WITH(NOLOCK) ON rs.TestID=t.ID
			INNER JOIN dbo.TestStages ts WITH(NOLOCK) ON rs.TestStageID=ts.ID
			INNER JOIN dbo.Jobs j WITH(NOLOCK) ON j.ID=ts.JobID
			LEFT OUTER JOIN Relab.ResultsXML x WITH(NOLOCK) ON x.ID=m.XMLID
		WHERE ((' + CONVERT(NVARCHAR,@ResultArchived) + ' = 0 AND m.Archived=0) OR (' + CONVERT(NVARCHAR, @ResultArchived) + '=1)) ')

		IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType = 'Measurement') > 0)
		BEGIN				
			SET @whereStr = ''
			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(SearchTerm)) + ''','
			FROM dbo.#temp WITH(NOLOCK)
			WHERE TableType='Measurement' AND LTRIM(RTRIM(SearchTerm)) LIKE '*%'

			SET @whereStr = REPLACE(REPLACE(REPLACE(@whereStr, '''*', 'LIKE ''%'), ''',', '%'''), 'LIKE ', ' OR mn.[Values] LIKE ')

			INSERT INTO #executeSQL (sqlvar)
			VALUES ('AND ( ' + SUBSTRING(@whereStr,4, LEN(@whereStr)) + ' )')
		END

		IF (@TestRunStartDate IS NOT NULL AND @TestRunEndDate IS NOT NULL)
		BEGIN
			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND (x.StartDate >= ''' + CONVERT(NVARCHAR,@TestRunStartDate) + ' 00:00:00.000'' AND x.EndDate <= ''' + CONVERT(NVARCHAR,@TestRunEndDate) + ' 23:59:59'') ')
		END

		IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType='Unit') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(ISNULL(SearchTerm, ''))) + ''','
			FROM dbo.#temp WITH(NOLOCK)
			WHERE TableType = 'Unit'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND tu.BatchUnitNumber IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')')
		END

		IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType='IMEI') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(ISNULL(SearchTerm, ''))) + ''','
			FROM dbo.#temp WITH(NOLOCK)
			WHERE TableType = 'IMEI'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND tu.IMEI IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')')
		END

		IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType='BSN') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '''' ,'') + LTRIM(RTRIM(SearchTerm)) + ''','
			FROM dbo.#temp WITH(NOLOCK)
			WHERE TableType = 'BSN'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND tu.BSN IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')')
		END

		IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType='Test') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + LTRIM(RTRIM(ID)) + ','
			FROM dbo.#temp WITH(NOLOCK)
			WHERE TableType = 'Test'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND t.ID IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ')')
		END

		IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType='Stage') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + LTRIM(RTRIM(ID)) + ','
			FROM dbo.#temp WITH(NOLOCK)
			WHERE TableType = 'Stage'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND ts.ID IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ') ')
		END
		
		IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType='Job') > 0)
		BEGIN
			SET @whereStr = ''

			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + LTRIM(RTRIM(ID)) + ','
			FROM dbo.#temp WITH(NOLOCK)
			WHERE TableType = 'Job'

			INSERT INTO #executeSQL (sqlvar)
			VALUES (' AND j.ID IN (' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ') ')
		END
		
		SET @SQL =  REPLACE(REPLACE(REPLACE(REPLACE((select sqlvar AS [text()] from dbo.#executeSQL for xml path('')), '&#x0D;',''), '&gt;', ' >'), '&lt;', ' <'),'&amp;','&')
		EXEC sp_executesql @SQL

		SET @SQL = ''
		TRUNCATE TABLE dbo.#executeSQL

		IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType LIKE 'Param:%') > 0)
		BEGIN
			INSERT INTO dbo.#Params (Name, Val)
			SELECT REPLACE(TableType, 'Param:', ''), SearchTerm
			FROM dbo.#temp WITH(NOLOCK)
			WHERE TableType LIKE 'Param:%'
		END
		
		SELECT @ParameterColumnNames=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + rp.ParameterName
		FROM dbo.#RR rr WITH(NOLOCK)
			LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rr.ID=rp.ResultMeasurementID
		WHERE rp.ParameterName <> 'Command'
		ORDER BY '],[' +  rp.ParameterName
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

		IF (@ParameterColumnNames <> '[na]')
		BEGIN
			SET @SQL = 'ALTER TABLE dbo.#RRParameters ADD ' + replace(@ParameterColumnNames, ']', '] NVARCHAR(250)')
			EXEC sp_executesql @SQL
			SET @whereStr = ''
			
			DELETE p 
			FROM dbo.#Params p WITH(NOLOCK)
			WHERE p.Name IN (SELECT Name
					FROM 
						(
							SELECT Name
							FROM #Params WITH(NOLOCK)
						) param
					WHERE param.Name NOT IN (SELECT s FROM dbo.Split(',', LTRIM(RTRIM(REPLACE(REPLACE(@ParameterColumnNames, '[', ''), ']', ''))))))
			
			IF ((SELECT COUNT(*) FROM dbo.#Params WITH(NOLOCK)) > 0)
			BEGIN
				SET @whereStr = ' WHERE '
				SET @whereStr2 = ''
				SET @whereStr3 = ''
				
				SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS params
				INTO #buildparamtable
				FROM #Params WITH(NOLOCK)
				GROUP BY name
				
				SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS params
				INTO #buildparamtable2
				FROM #Params WITH(NOLOCK)
				GROUP BY name
				
				SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS params
				INTO #buildparamtable3
				FROM #Params WITH(NOLOCK)
				GROUP BY name
				
				UPDATE bt
				SET bt.params = REPLACE(REPLACE((
						SELECT ('''' + p.Val + ''',') As Val
						FROM #Params p WITH(NOLOCK)
						WHERE p.Name = bt.Name AND Val NOT LIKE '*%' AND Val NOT LIKE '-%'
						FOR XML PATH('')), '<Val>', ''), '</Val>','')
				FROM #buildparamtable bt WITH(NOLOCK)
				WHERE Params = ''
				
				UPDATE bt
				SET bt.params = REPLACE(REPLACE((
						SELECT ('LTRIM(RTRIM([' + Name + '])) LIKE ''' + REPLACE(p.Val, '*','%') + '%'' OR ') As Val
						FROM #Params p WITH(NOLOCK)
						WHERE p.Name = bt.Name AND Val LIKE '*%' AND Val NOT LIKE '-%'
						FOR XML PATH('')), '<Val>', ''), '</Val>','')
				FROM #buildparamtable2 bt WITH(NOLOCK)
				WHERE Params = '' OR Params IS NULL
				
				UPDATE bt
				SET bt.params = REPLACE(REPLACE((
						SELECT ('LTRIM(RTRIM([' + Name + '])) NOT LIKE ''' + REPLACE(p.Val, '-','%') + '%'' OR ') As Val
						FROM #Params p WITH(NOLOCK)
						WHERE p.Name = bt.Name AND Val LIKE '-%'
						FOR XML PATH('')), '<Val>', ''), '</Val>','')
				FROM #buildparamtable3 bt WITH(NOLOCK)
				WHERE Params = '' OR Params IS NULL
				
				SELECT @whereStr = COALESCE(@whereStr + '' ,'') + 'LTRIM(RTRIM([' + Name + '])) IN (' + SUBSTRING(params, 0, LEN(params)) + ') AND ' 
				FROM dbo.#buildparamtable WITH(NOLOCK) 
				WHERE Params IS NOT NULL
				
				IF (@whereStr <> ' WHERE ')
					SET @whereStr = SUBSTRING(@whereStr, 0, LEN(@whereStr)-2)

				SELECT @whereStr2 += COALESCE(@whereStr2 + '' ,'') + ' ( ' + SUBSTRING(params, 0, LEN(params)-1) + ' ) '
				FROM dbo.#buildparamtable2 WITH(NOLOCK)
				WHERE Params IS NOT NULL
				
				IF @whereStr2 IS NOT NULL AND LTRIM(RTRIM(@whereStr2)) <> ''
				BEGIN						
					IF (@whereStr <> ' WHERE ')
						SET @whereStr2 = ' AND ' + @whereStr2
					ELSE
						SET @whereStr2 = @whereStr2
				END
				
				SELECT @whereStr3 += COALESCE(@whereStr3 + '' ,'') + ' ( ' + SUBSTRING(params, 0, LEN(params)-1) + ' ) '
				FROM dbo.#buildparamtable3 WITH(NOLOCK)
				WHERE Params IS NOT NULL
				
				IF @whereStr3 IS NOT NULL AND LTRIM(RTRIM(@whereStr3)) <> ''
				BEGIN						
					IF (@whereStr <> ' WHERE ')
						SET @whereStr3 = ' AND ' + @whereStr3
					ELSE
						SET @whereStr3 = @whereStr3
				END
											
				SET @whereStr = REPLACE(@whereStr + @whereStr2 + @whereStr3,'&amp;','&')				

				DROP TABLE #buildparamtable
				DROP TABLE #buildparamtable2
			END

			SET @SQL = 'INSERT INTO dbo.#RRParameters SELECT *
			FROM (
				SELECT rp.ResultMeasurementID, rp.ParameterName, rp.Value
				FROM dbo.#RR rr WITH(NOLOCK)
					INNER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rr.ID=rp.ResultMeasurementID
				) te PIVOT (MAX(Value) FOR ParameterName IN (' + @ParameterColumnNames + ')) AS pvt
			 ' + @whereStr
				
			EXEC sp_executesql @SQL
		END
		ELSE
		BEGIN
			SET @ParameterColumnNames = NULL
		END

		DECLARE @ResultInfoArchived INT
		SELECT @ResultInfoArchived = ID FROM dbo.#temp WITH(NOLOCK) WHERE TableType='ResultInfoArchived'

		IF @ResultInfoArchived IS NULL
			SET @ResultInfoArchived = 0
							
		IF ((SELECT COUNT(*) FROM dbo.#temp WITH(NOLOCK) WHERE TableType LIKE 'Info:%') > 0)
		BEGIN
			INSERT INTO dbo.#Infos (Name, Val)
			SELECT REPLACE(TableType, 'Info:', ''), SearchTerm
			FROM dbo.#temp WITH(NOLOCK)
			WHERE TableType LIKE 'Info:%'
		END

		SELECT @InformationColumnNames=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + ri.Name
		FROM dbo.#RR rr WITH(NOLOCK)
			INNER JOIN Relab.ResultsXML x WITH(NOLOCK) ON x.ResultID = rr.ResultID
			LEFT OUTER JOIN Relab.ResultsInformation ri WITH(NOLOCK) ON x.ID=ri.XMLID
		WHERE ri.Name NOT IN ('Start UTC','Start','End', 'STEF Plugin Version')
			AND ((@ResultInfoArchived = 0 AND ri.IsArchived=0) OR (@ResultInfoArchived=1))
		ORDER BY '],[' +  ri.Name
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

		IF (@InformationColumnNames <> '[na]')
		BEGIN
			SET @SQL = 'ALTER TABLE dbo.#RRInformation ADD ' + replace(@InformationColumnNames, ']', '] NVARCHAR(250)')
			EXEC sp_executesql @SQL
			
			SET @whereStr = ''
			
			DELETE i 
			FROM dbo.#infos i WITH(NOLOCK)
			WHERE i.Name IN (SELECT Name
					FROM 
						(
							SELECT Name
							FROM #Infos WITH(NOLOCK)
						) inf
					WHERE inf.Name NOT IN (SELECT s FROM dbo.Split(',', LTRIM(RTRIM(REPLACE(REPLACE(@InformationColumnNames, '[', ''), ']', ''))))))

			IF ((SELECT COUNT(*) FROM dbo.#Infos WITH(NOLOCK)) > 0)
			BEGIN
				SET @whereStr = ' WHERE '
				SET @whereStr2 = ''
				SET @whereStr3 = ''
				
				SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS info
				INTO #buildinfotable
				FROM dbo.#infos WITH(NOLOCK)
				GROUP BY name
				
				SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS info
				INTO #buildinfotable2
				FROM dbo.#infos WITH(NOLOCK)
				GROUP BY name
				
				SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS info
				INTO #buildinfotable3
				FROM dbo.#infos WITH(NOLOCK)
				GROUP BY name
				
				UPDATE bt
				SET bt.info = REPLACE(REPLACE((
						SELECT ('''' + i.Val + ''',') As Val
						FROM dbo.#infos i WITH(NOLOCK)
						WHERE i.Name = bt.Name AND Val NOT LIKE '*%' AND Val NOT LIKE '-%'
						FOR XML PATH('')), '<Val>', ''), '</Val>','')
				FROM #buildinfotable bt WITH(NOLOCK)
				WHERE info = ''
				
				UPDATE bt
				SET bt.info = REPLACE(REPLACE((
						SELECT ('LTRIM(RTRIM([' + Name + '])) LIKE ''' + REPLACE(i.Val, '*','%') + '%'' OR ') As Val
						FROM dbo.#infos i WITH(NOLOCK)
						WHERE i.Name = bt.Name AND Val LIKE '*%'
						FOR XML PATH('')), '<Val>', ''), '</Val>','')
				FROM #buildinfotable2 bt WITH(NOLOCK)
				WHERE info = '' OR info IS NULL
				
				UPDATE bt
				SET bt.info = REPLACE(REPLACE((
						SELECT ('LTRIM(RTRIM([' + Name + '])) NOT LIKE ''' + REPLACE(i.Val, '-','%') + '%'' OR ') As Val
						FROM dbo.#infos i WITH(NOLOCK)
						WHERE i.Name = bt.Name AND Val LIKE '-%'
						FOR XML PATH('')), '<Val>', ''), '</Val>','')
				FROM #buildinfotable3 bt WITH(NOLOCK)
				WHERE info = '' OR info IS NULL
									
				SELECT @whereStr = COALESCE(@whereStr + '' ,'') + 'LTRIM(RTRIM([' + Name + '])) IN (' + SUBSTRING(info, 0, LEN(info)) + ') AND ' 
				FROM dbo.#buildinfotable WITH(NOLOCK) 
				WHERE info IS NOT NULL 
				
				IF (@whereStr <> ' WHERE ')
					SET @whereStr = SUBSTRING(@whereStr, 0, LEN(@whereStr)-2)
									
				SELECT @whereStr2 += COALESCE(@whereStr2 + '' ,'') + ' ( ' + SUBSTRING(info, 0, LEN(info)-1) + ' ) '
				FROM dbo.#buildinfotable2 WITH(NOLOCK) 
				WHERE info IS NOT NULL 
				
				IF @whereStr2 IS NOT NULL AND LTRIM(RTRIM(@whereStr2)) <> ''
				BEGIN						
					IF (@whereStr <> ' WHERE ')
						SET @whereStr2 = ' AND ' + @whereStr2
					ELSE
						SET @whereStr2 = @whereStr2
				END						
				
				SELECT @whereStr3 += COALESCE(@whereStr3 + '' ,'') + ' ( ' + SUBSTRING(info, 0, LEN(info)-1) + ' ) '
				FROM dbo.#buildinfotable3 WITH(NOLOCK) 
				WHERE info IS NOT NULL 
				
				IF @whereStr3 IS NOT NULL AND LTRIM(RTRIM(@whereStr3)) <> ''
				BEGIN						
					IF (@whereStr <> ' WHERE ')
						SET @whereStr3 = ' AND ' + @whereStr3
					ELSE
						SET @whereStr3 = @whereStr3
				END
											
				SET @whereStr = REPLACE(@whereStr + @whereStr2 + @whereStr3,'&amp;','&')

				DROP TABLE #buildinfotable
				DROP TABLE #buildinfotable2
			END

			SET @SQL = N'INSERT INTO dbo.#RRInformation SELECT *
			FROM (
				SELECT rr.ResultID AS RID, ri.IsArchived AS ResultInfoArchived, ri.Name, ri.Value
				FROM dbo.#RR rr WITH(NOLOCK)
					INNER JOIN Relab.ResultsInformation ri WITH(NOLOCK) ON rr.XMLID=ri.XMLID
				WHERE ri.Name NOT IN (''Start UTC'',''Start'',''End'', ''STEF Plugin Version'') AND
					((@ResultInfoArchived = 0 AND ri.IsArchived=0) OR (@ResultInfoArchived=1)) 
				) te PIVOT (MAX(Value) FOR Name IN ('+ @InformationColumnNames +')) AS pvt
			' + @whereStr

			EXEC sp_executesql @SQL, N'@ResultInfoArchived int', @ResultInfoArchived
		END
		ELSE
		BEGIN
			SET @InformationColumnNames = NULL
		END

		SET @whereStr = ''

		IF (@UserID > 0 AND @UserID IS NOT NULL)
		BEGIN
			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + LTRIM(RTRIM(ColumnName)) + ','
			FROM dbo.UserSearchFilter WITH(NOLOCK)
			WHERE UserID=@UserID AND RequestTypeID=@RequestTypeID
			ORDER BY SortOrder
		END
		
		DECLARE @LimitedByInfo INT
		DECLARE @LimitedByParam INT
		SET @LimitedByParam = 0
		SET @LimitedByInfo = 0
		
		IF ((SELECT COUNT(*) FROM dbo.#Infos) > 0)
			SET @LimitedByInfo = 1
		
		IF ((SELECT COUNT(*) FROM dbo.#Params) > 0)
			SET @LimitedByParam = 1

		SET @whereStr = REPLACE(REPLACE(@whereStr 
				, 'Params', CASE WHEN (SELECT 1 FROM UserSearchFilter WITH(NOLOCK) WHERE FilterType=3) = 1 THEN @ParameterColumnNames ELSE '' END)
				, 'Info', CASE WHEN (SELECT 1 FROM UserSearchFilter WITH(NOLOCK) WHERE FilterType=4) = 1 THEN @InformationColumnNames ELSE '' END)

		IF (ISNULL(@whereStr, '') = '')
		BEGIN
			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + '[' + COLUMN_NAME + '],' 
			FROM tempdb.INFORMATION_SCHEMA.COLUMNS WITH(NOLOCK) 
			WHERE (TABLE_NAME like '#RR%' OR TABLE_NAME LIKE '#RRParameters%' OR TABLE_NAME LIKE '#RRInformation%')
				AND COLUMN_NAME NOT IN ('RequestID', 'XMLID', 'ID', 'BatchID', 'ResultID', 'RID', 'ResultMeasurementID')
			ORDER BY TABLE_NAME
		END
		
		SET @whereStr = SUBSTRING(@whereStr, 0, LEN(@whereStr))

		SET @SQL = 'SELECT DISTINCT ' + @whereStr + '
			FROM dbo.#RR rr WITH(NOLOCK) 
				LEFT OUTER JOIN dbo.#RRParameters p WITH(NOLOCK) ON rr.ID=p.ResultMeasurementID
				LEFT OUTER JOIN dbo.#RRInformation i WITH(NOLOCK) ON i.RID = rr.ResultID
			WHERE ((' + CONVERT(NVARCHAR, @LimitedByInfo) + ' = 0) OR (' + CONVERT(NVARCHAR, @LimitedByInfo) + ' = 1 AND i.RID IS NOT NULL ))
				AND ((' + CONVERT(NVARCHAR, @LimitedByParam) + ' = 0) OR (' + CONVERT(NVARCHAR, @LimitedByParam) + ' = 1 AND p.ResultMeasurementID IS NOT NULL )) '
		
		IF (@SQL LIKE '%[' + @ProductGroupColumn + ']%' AND @UserID IS NOT NULL)
		BEGIN
			SET @SQL += 'AND (' + CONVERT(NVARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(NVARCHAR, @ByPassProductCheck) + ' = 0 
																	AND [' + @ProductGroupColumn + '] COLLATE SQL_Latin1_General_CP1_CI_AS IN (SELECT p.[values] 
																FROM UserDetails ud WITH(NOLOCK)
																	INNER JOIN Lookups p WITH(NOLOCK) ON p.LookupID=ud.LookupID 
																WHERE UserID=' + CONVERT(NVARCHAR, @UserID) + '))) '
		END
		
		IF (@SQL LIKE '%[' + @DepartmentColumn + ']%' AND @UserID IS NOT NULL)
		BEGIN
			SET @SQL += ' AND ([' + @DepartmentColumn + '] COLLATE SQL_Latin1_General_CP1_CI_AS IN (SELECT lt.[Values]
															FROM UserDetails ud WITH(NOLOCK)
																INNER JOIN Lookups lt WITH(NOLOCK) ON lt.LookupID=ud.LookupID
															WHERE ud.UserID=' + CONVERT(NVARCHAR, @UserID) + ')) '
		END
		
		PRINT @SQL
		EXEC sp_executesql @SQL

		DROP TABLE dbo.#RRParameters
		DROP TABLE dbo.#RRInformation
		DROP TABLE dbo.#RR
	END
	ELSE
	BEGIN
		SET @whereStr = ''

		IF (@UserID > 0 AND @UserID IS NOT NULL)
		BEGIN
			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + LTRIM(RTRIM(ColumnName)) + ','
			FROM dbo.UserSearchFilter WITH(NOLOCK)
			WHERE UserID=@UserID AND FilterType = 1 AND RequestTypeID=@RequestTypeID 
			ORDER BY SortOrder
		END

		IF (ISNULL(@whereStr, '') = '')
		BEGIN
			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + '[' + COLUMN_NAME + '],' 
			FROM tempdb.INFORMATION_SCHEMA.COLUMNS WITH(NOLOCK) 
			WHERE (TABLE_NAME like '#Request%') AND COLUMN_NAME NOT IN ('RequestID', 'BatchID')
			ORDER BY TABLE_NAME
		END

		SET @whereStr = SUBSTRING(@whereStr, 0, LEN(@whereStr))

		SET @SQL = 'SELECT DISTINCT ' + CASE WHEN @RecordCount = 0 THEN 'TOP 20' ELSE '' END + @whereStr + ' 
					FROM dbo.#Request r WITH(NOLOCK) 
					WHERE (1=1)'

		IF (@SQL LIKE '%[' + @ProductGroupColumn + ']%' AND @UserID IS NOT NULL)
		BEGIN
			SET @SQL += 'AND (' + CONVERT(NVARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(NVARCHAR, @ByPassProductCheck) + ' = 0 
															AND [' + @ProductGroupColumn + '] COLLATE SQL_Latin1_General_CP1_CI_AS IN (SELECT p.[values] 
																FROM UserDetails ud WITH(NOLOCK)
																	INNER JOIN Lookups p WITH(NOLOCK) ON p.LookupID=ud.LookupID 
																WHERE UserID=' + CONVERT(NVARCHAR, @UserID) + '))) '
		END
		
		IF (@SQL LIKE '%[' + @DepartmentColumn + ']%' AND @UserID IS NOT NULL)
		BEGIN
			SET @SQL += ' AND ([' + @DepartmentColumn + '] COLLATE SQL_Latin1_General_CP1_CI_AS IN (SELECT lt.[Values]
															FROM UserDetails ud WITH(NOLOCK)
																INNER JOIN Lookups lt WITH(NOLOCK) ON lt.LookupID=ud.LookupID
															WHERE ud.UserID=' + CONVERT(NVARCHAR, @UserID) + ')) '
		END
		
		SET @SQL += ' ORDER BY RequestNumber DESC '
		EXEC sp_executesql @SQL
	END

	DROP TABLE dbo.#executeSQL
	DROP TABLE dbo.#temp
	DROP TABLE dbo.#Request
	DROP TABLE dbo.#Infos
	DROP TABLE dbo.#ReqNum
	DROP TABLE dbo.#Params
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Req].[RequestSearch] TO REMI
GO
DECLARE @table AS dbo.SearchFields
INSERT INTO @table(TableType, ID, SearchTerm)
VALUES ('Request', 51, '*Windermere'),
--('Request', 51, '-Windermere E R135'),
--('Request', 51, '3G SIMs'),
--('Request', 51, '*Lisbon'),
--('Request', 49, 'Handheld'),
--('Request', 49, '*Accessory'),
--('Test', 1099, 'Sensor Test'),
--('Test', 1280, 'Functional'),
--('Test', 1020, 'Radiated RF Test'),
--('Test', 1561, 'Display Test'),
--('Test', 1103, 'Camera Front'),
--('Stage', 3616, '1 Drop'),
--('Job', 179, 'T004 DIRT RASS Drop'),
--('Job', 215, 'T013 Mechanical Suite'),
--('Stage', 2246, 'Analysis'),
--('Stage', 3220, 'Post 720hrs'),
--('BSN', 0, '1132205311'),
--('BSN', 0, '1151200936'),
--('ReqNum', 0, 'QRA-14-0038'),
--('ReqNum', 0, 'QRA-14-0597'),
--('Unit', 0, '5'),
--('Unit', 0, '1'),
--('IMEI', 0, '004402242039794'),
--('IMEI', 0, '351852062969380'),
--('ResultArchived', 0, ''),
--('Param:Band', 0, 'GPRS1800'),
--('Param:Band', 0, 'LTE17'),
--('Param:Channel', 0, '*700'),
--('Param:Channel', 0, '-512'),
--('ResultInfoArchived', 0, ''),
--('Info:HardwareID', 0, 'Rohde&Schwarz,CMW,1201.0002k50/119061,3.0.14'),
--('Info:HardwareID', 0, '*Rohde&Schwarz'),
--('Info:OSVersion', 0, 'NA'),
--('Info:OSVersion', 0, 'adsf'),
--('Info:CameraID', 0, 'Not Reported'),
--('Info:hoursintest', 0, '10'),
--('TestRunStartDate', 0, '2015-01-19'),
--('TestRunEndDate', 0, '2015-01-19'),
--('Measurement', 0, '*RxBER'),
--('Info:', 0, 'Rohde&Schwarz,CMW,1201.0002k50/119061,3.0.14')
--('BatchStageType',0,'1'),
--('BatchAssignedUser',0,'ogaudreault'),
--('BatchAssignedUser',0,'vpriala')
--('BatchStatus',0,'2')
('BatchStatus',0,'5')
--('BatchStartDate', 0, '2015-01-19'),
--('BatchEndDate', 0, '2015-04-19')
EXEC [Req].[RequestSearch] 1, @table, 251