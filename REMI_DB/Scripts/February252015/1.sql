/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 2/25/2015 9:53:24 AM

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
ALTER TABLE Relab.ResultsMeasurements ALTER COLUMN Comment NVARCHAR(1000) NULL
GO
PRINT N'Altering [Req].[RequestSearch]'
GO
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
	SELECT @ByPassProductCheck = u.ByPassProduct FROM Users u WHERE u.ID=@UserID
	
	SELECT @ProductGroupColumn = fs.Name
	FROM Req.ReqFieldSetup fs 
		INNER JOIN Req.ReqFieldMapping fm ON fs.Name=fm.ExtField AND fs.RequestTypeID=fm.RequestTypeID
	WHERE fs.RequestTypeID = @RequestTypeID AND fm.IntField='ProductGroup'
	
	SELECT @DepartmentColumn = fs.Name
	FROM Req.ReqFieldSetup fs
		INNER JOIN Req.ReqFieldMapping fm ON fs.Name=fm.ExtField AND fs.RequestTypeID=fm.RequestTypeID
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
	
	IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType = 'ReqNum') > 0)
		BEGIN
			INSERT INTO dbo.#ReqNum (RequestNumber)
			SELECT SearchTerm
			FROM dbo.#temp
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
				
			SET @SQL += ' WHERE rt.RequestTypeID=' + CONVERT(NVARCHAR, @RequestTypeID) + '
			) req PIVOT (MAX(Value) FOR Name IN (' + REPLACE(@rows, ',', ',
			') + ')) AS pvt '

	INSERT INTO #executeSQL (sqlvar)
	VALUES (@SQL)
	
	SET @SQL = ''
	
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
	END

	SET @SQL = REPLACE((select sqlvar AS [text()] from dbo.#executeSQL for xml path('')), '&#x0D;','')

	EXEC sp_executesql @SQL

	IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType NOT IN ('Request','ReqNum')) > 0)
	BEGIN
		SET @SQL = ''
		TRUNCATE TABLE dbo.#executeSQL

		CREATE TABLE dbo.#RR (RequestID INT, BatchID INT, RequestNumber NVARCHAR(11), BatchUnitNumber INT, IMEI NVARCHAR(150), BSN BIGINT, ID INT, ResultID INT, XMLID INT)
		CREATE TABLE dbo.#RRParameters (ResultMeasurementID INT)
		CREATE TABLE dbo.#RRInformation (RID INT, ResultInfoArchived BIT)
		
		CREATE INDEX [Request_BatchID] ON dbo.#Request([BatchID])

		SET @SQL = 'ALTER TABLE dbo.#RR ADD ' + replace(@rows, ']', '] NVARCHAR(4000)')
		EXEC sp_executesql @SQL

		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType IN ('Test', 'Stage')) > 0)
		BEGIN
			ALTER TABLE dbo.#RR ADD ResultLink NVARCHAR(100), TestName NVARCHAR(400), TestStageName NVARCHAR(400), 
				TestRunStartDate DATETIME, TestRunEndDate DATETIME, 
				MeasurementName NVARCHAR(150), MeasurementValue NVARCHAR(500), 
				LowerLimit NVARCHAR(255), UpperLimit NVARCHAR(255), Archived BIT, Comment NVARCHAR(1000), 
				DegradationVal DECIMAL(10,3), Description NVARCHAR(800), PassFail BIT, ReTestNum INT,
				MeasurementUnitType NVARCHAR(150)
		END

		SET @rows = REPLACE(@rows, '[', 'r.[')

		INSERT INTO #executeSQL (sqlvar)
		VALUES ('INSERT INTO dbo.#RR 
		SELECT r.RequestID, r.BatchID, r.RequestNumber, tu.BatchUnitNumber, tu.IMEI, tu.BSN ')

		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType IN ('Test', 'Stage')) > 0)
		BEGIN
			INSERT INTO #executeSQL (sqlvar)
			VALUES (',m.ID, rs.ID AS ResultID, x.ID AS XMLID, ')
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
			VALUES (', (''http://go/remi/Relab/Measurements.aspx?ID='' + CONVERT(VARCHAR, rs.ID) + ''&Batch='' + CONVERT(VARCHAR, b.ID)) AS ResultLink ')
		
		
			INSERT INTO #executeSQL (sqlvar)
			VALUES (', t.TestName, ts.TestStageName, x.StartDate AS TestRunStartDate, x.EndDate AS TestRunEndDate, 
				mn.[Values] As MeasurementName, m.MeasurementValue, m.LowerLimit, m.UpperLimit, m.Archived, m.Comment, m.DegradationVal, m.Description, m.PassFail, m.ReTestNum, 
				mut.[Values] As MeasurementUnitType ')
		END

		INSERT INTO #executeSQL (sqlvar)
		VALUES (' FROM dbo.#Request r WITH(NOLOCK)
			INNER JOIN dbo.Batches b WITH(NOLOCK) ON b.ID=r.BatchID
			INNER JOIN dbo.TestUnits tu WITH(NOLOCK) ON tu.BatchID=b.ID ')

		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType IN ('Test', 'Stage', 'Measurement')) > 0)
		BEGIN
			DECLARE @ResultArchived INT
			DECLARE @TestRunStartDate NVARCHAR(12)
			DECLARE @TestRunEndDate NVARCHAR(12)

			SELECT @ResultArchived = ID FROM dbo.#temp WHERE TableType='ResultArchived'
			SELECT @TestRunStartDate = SearchTerm FROM dbo.#temp WHERE TableType='TestRunStartDate'
			SELECT @TestRunEndDate = SearchTerm FROM dbo.#temp WHERE TableType='TestRunEndDate'

			IF @ResultArchived IS NULL
				SET @ResultArchived = 0

			INSERT INTO #executeSQL (sqlvar)
			VALUES ('INNER JOIN Relab.Results rs WITH(NOLOCK) ON rs.TestUnitID=tu.ID
				INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) ON m.ResultID=rs.ID
				INNER JOIN dbo.Lookups mn WITH(NOLOCK) ON mn.LookupID = m.MeasurementTypeID 
				LEFT OUTER JOIN dbo.Lookups mut WITH(NOLOCK) ON mut.LookupID = m.MeasurementUnitTypeID 
				INNER JOIN dbo.Tests t WITH(NOLOCK) ON rs.TestID=t.ID
				INNER JOIN dbo.TestStages ts WITH(NOLOCK) ON rs.TestStageID=ts.ID
				LEFT OUTER JOIN Relab.ResultsXML x WITH(NOLOCK) ON x.ID=m.XMLID
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
				VALUES (' AND (x.StartDate >= ''' + CONVERT(NVARCHAR,@TestRunStartDate) + ' 00:00:00.000'' AND x.EndDate <= ''' + CONVERT(NVARCHAR,@TestRunEndDate) + ' 23:59:59'') ')
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

		SET @SQL =  REPLACE(REPLACE(REPLACE(REPLACE((select sqlvar AS [text()] from dbo.#executeSQL for xml path('')), '&#x0D;',''), '&gt;', ' >'), '&lt;', ' <'),'&amp;','&')
		EXEC sp_executesql @SQL

		SET @SQL = ''
		TRUNCATE TABLE dbo.#executeSQL

		IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType IN ('Test', 'Stage', 'Measurement')) > 0)
		BEGIN
			IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType LIKE 'Param:%') > 0)
			BEGIN
				INSERT INTO dbo.#Params (Name, Val)
				SELECT REPLACE(TableType, 'Param:', ''), SearchTerm
				FROM dbo.#temp
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
				FROM dbo.#Params p
				WHERE p.Name IN (SELECT Name
						FROM 
							(
								SELECT Name
								FROM #Params
							) param
						WHERE param.Name NOT IN (SELECT s FROM dbo.Split(',', LTRIM(RTRIM(REPLACE(REPLACE(@ParameterColumnNames, '[', ''), ']', ''))))))
				
				IF ((SELECT COUNT(*) FROM dbo.#Params) > 0)
				BEGIN
					SET @whereStr = ' WHERE '
					SET @whereStr2 = ''
					SET @whereStr3 = ''
					
					SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS params
					INTO #buildparamtable
					FROM #Params
					GROUP BY name
					
					SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS params
					INTO #buildparamtable2
					FROM #Params
					GROUP BY name
					
					SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS params
					INTO #buildparamtable3
					FROM #Params
					GROUP BY name
					
					UPDATE bt
					SET bt.params = REPLACE(REPLACE((
							SELECT ('''' + p.Val + ''',') As Val
							FROM #Params p
							WHERE p.Name = bt.Name AND Val NOT LIKE '*%' AND Val NOT LIKE '-%'
							FOR XML PATH('')), '<Val>', ''), '</Val>','')
					FROM #buildparamtable bt
					WHERE Params = ''
					
					UPDATE bt
					SET bt.params = REPLACE(REPLACE((
							SELECT ('LTRIM(RTRIM([' + Name + '])) LIKE ''' + REPLACE(p.Val, '*','%') + '%'' OR ') As Val
							FROM #Params p
							WHERE p.Name = bt.Name AND Val LIKE '*%' AND Val NOT LIKE '-%'
							FOR XML PATH('')), '<Val>', ''), '</Val>','')
					FROM #buildparamtable2 bt
					WHERE Params = '' OR Params IS NULL
					
					UPDATE bt
					SET bt.params = REPLACE(REPLACE((
							SELECT ('LTRIM(RTRIM([' + Name + '])) NOT LIKE ''' + REPLACE(p.Val, '-','%') + '%'' OR ') As Val
							FROM #Params p
							WHERE p.Name = bt.Name AND Val LIKE '-%'
							FOR XML PATH('')), '<Val>', ''), '</Val>','')
					FROM #buildparamtable3 bt
					WHERE Params = '' OR Params IS NULL
					
					SELECT @whereStr = COALESCE(@whereStr + '' ,'') + 'LTRIM(RTRIM([' + Name + '])) IN (' + SUBSTRING(params, 0, LEN(params)) + ') AND ' 
					FROM dbo.#buildparamtable 
					WHERE Params IS NOT NULL
					
					IF (@whereStr <> ' WHERE ')
						SET @whereStr = SUBSTRING(@whereStr, 0, LEN(@whereStr)-2)

					SELECT @whereStr2 += COALESCE(@whereStr2 + '' ,'') + ' ( ' + SUBSTRING(params, 0, LEN(params)-1) + ' ) '
					FROM dbo.#buildparamtable2 
					WHERE Params IS NOT NULL
					
					IF @whereStr2 IS NOT NULL AND LTRIM(RTRIM(@whereStr2)) <> ''
					BEGIN						
						IF (@whereStr <> ' WHERE ')
							SET @whereStr2 = ' AND ' + @whereStr2
						ELSE
							SET @whereStr2 = @whereStr2
					END
					
					SELECT @whereStr3 += COALESCE(@whereStr3 + '' ,'') + ' ( ' + SUBSTRING(params, 0, LEN(params)-1) + ' ) '
					FROM dbo.#buildparamtable3
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
			SELECT @ResultInfoArchived = ID FROM dbo.#temp WHERE TableType='ResultInfoArchived'

			IF @ResultInfoArchived IS NULL
				SET @ResultInfoArchived = 0
							
			IF ((SELECT COUNT(*) FROM dbo.#temp WHERE TableType LIKE 'Info:%') > 0)
			BEGIN
				INSERT INTO dbo.#Infos (Name, Val)
				SELECT REPLACE(TableType, 'Info:', ''), SearchTerm
				FROM dbo.#temp
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
				FROM dbo.#infos i
				WHERE i.Name IN (SELECT Name
						FROM 
							(
								SELECT Name
								FROM #Infos
							) inf
						WHERE inf.Name NOT IN (SELECT s FROM dbo.Split(',', LTRIM(RTRIM(REPLACE(REPLACE(@InformationColumnNames, '[', ''), ']', ''))))))

				IF ((SELECT COUNT(*) FROM dbo.#Infos) > 0)
				BEGIN
					SET @whereStr = ' WHERE '
					SET @whereStr2 = ''
					SET @whereStr3 = ''
					
					SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS info
					INTO #buildinfotable
					FROM dbo.#infos
					GROUP BY name
					
					SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS info
					INTO #buildinfotable2
					FROM dbo.#infos
					GROUP BY name
					
					SELECT Name, COUNT(*) as counting, convert(nvarchar(max),'') AS info
					INTO #buildinfotable3
					FROM dbo.#infos
					GROUP BY name
					
					UPDATE bt
					SET bt.info = REPLACE(REPLACE((
							SELECT ('''' + i.Val + ''',') As Val
							FROM dbo.#infos i
							WHERE i.Name = bt.Name AND Val NOT LIKE '*%' AND Val NOT LIKE '-%'
							FOR XML PATH('')), '<Val>', ''), '</Val>','')
					FROM #buildinfotable bt
					WHERE info = ''
					
					UPDATE bt
					SET bt.info = REPLACE(REPLACE((
							SELECT ('LTRIM(RTRIM([' + Name + '])) LIKE ''' + REPLACE(i.Val, '*','%') + '%'' OR ') As Val
							FROM dbo.#infos i
							WHERE i.Name = bt.Name AND Val LIKE '*%'
							FOR XML PATH('')), '<Val>', ''), '</Val>','')
					FROM #buildinfotable2 bt
					WHERE info = '' OR info IS NULL
					
					UPDATE bt
					SET bt.info = REPLACE(REPLACE((
							SELECT ('LTRIM(RTRIM([' + Name + '])) NOT LIKE ''' + REPLACE(i.Val, '-','%') + '%'' OR ') As Val
							FROM dbo.#infos i
							WHERE i.Name = bt.Name AND Val LIKE '-%'
							FOR XML PATH('')), '<Val>', ''), '</Val>','')
					FROM #buildinfotable3 bt
					WHERE info = '' OR info IS NULL
										
					SELECT @whereStr = COALESCE(@whereStr + '' ,'') + 'LTRIM(RTRIM([' + Name + '])) IN (' + SUBSTRING(info, 0, LEN(info)) + ') AND ' 
					FROM dbo.#buildinfotable 
					WHERE info IS NOT NULL 
					
					IF (@whereStr <> ' WHERE ')
						SET @whereStr = SUBSTRING(@whereStr, 0, LEN(@whereStr)-2)
										
					SELECT @whereStr2 += COALESCE(@whereStr2 + '' ,'') + ' ( ' + SUBSTRING(info, 0, LEN(info)-1) + ' ) '
					FROM dbo.#buildinfotable2 
					WHERE info IS NOT NULL 
					
					IF @whereStr2 IS NOT NULL AND LTRIM(RTRIM(@whereStr2)) <> ''
					BEGIN						
						IF (@whereStr <> ' WHERE ')
							SET @whereStr2 = ' AND ' + @whereStr2
						ELSE
							SET @whereStr2 = @whereStr2
					END						
					
					SELECT @whereStr3 += COALESCE(@whereStr3 + '' ,'') + ' ( ' + SUBSTRING(info, 0, LEN(info)-1) + ' ) '
					FROM dbo.#buildinfotable3 
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
		END

		SET @whereStr = ''

		IF (@UserID > 0 AND @UserID IS NOT NULL)
		BEGIN
			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + LTRIM(RTRIM(ColumnName)) + ','
			FROM dbo.UserSearchFilter
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
				, 'Params', CASE WHEN (SELECT 1 FROM UserSearchFilter WHERE FilterType=3) = 1 THEN @ParameterColumnNames ELSE '' END)
				, 'Info', CASE WHEN (SELECT 1 FROM UserSearchFilter WHERE FilterType=4) = 1 THEN @InformationColumnNames ELSE '' END)

		IF (ISNULL(@whereStr, '') = '')
		BEGIN
			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + '[' + COLUMN_NAME + '],' 
			FROM tempdb.INFORMATION_SCHEMA.COLUMNS 
			WHERE (TABLE_NAME like '#RR%' OR TABLE_NAME LIKE '#RRParameters%' OR TABLE_NAME LIKE '#RRInformation%')
				AND COLUMN_NAME NOT IN ('RequestID', 'XMLID', 'ID', 'BatchID', 'ResultID', 'RID', 'ResultMeasurementID')
			ORDER BY TABLE_NAME
		END
		
		SET @whereStr = SUBSTRING(@whereStr, 0, LEN(@whereStr))

		SET @SQL = 'SELECT DISTINCT ' + @whereStr + '
			FROM dbo.#RR rr 
				LEFT OUTER JOIN dbo.#RRParameters p ON rr.ID=p.ResultMeasurementID
				LEFT OUTER JOIN dbo.#RRInformation i ON i.RID = rr.ResultID
			WHERE ((' + CONVERT(NVARCHAR, @LimitedByInfo) + ' = 0) OR (' + CONVERT(NVARCHAR, @LimitedByInfo) + ' = 1 AND i.RID IS NOT NULL ))
				AND ((' + CONVERT(NVARCHAR, @LimitedByParam) + ' = 0) OR (' + CONVERT(NVARCHAR, @LimitedByParam) + ' = 1 AND p.ResultMeasurementID IS NOT NULL )) '
		
		IF (@SQL LIKE '%[' + @ProductGroupColumn + ']%' AND @UserID IS NOT NULL)
		BEGIN
			SET @SQL += 'AND (' + CONVERT(NVARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(NVARCHAR, @ByPassProductCheck) + ' = 0 
																	AND [' + @ProductGroupColumn + '] COLLATE SQL_Latin1_General_CP1_CI_AS IN (SELECT p.[values] 
																FROM UsersProducts up 
																	INNER JOIN Lookups p ON p.LookupID=up.ProductID 
																WHERE UserID=' + CONVERT(NVARCHAR, @UserID) + '))) '
		END
		
		IF (@SQL LIKE '%[' + @DepartmentColumn + ']%' AND @UserID IS NOT NULL)
		BEGIN
			SET @SQL += ' AND ([' + @DepartmentColumn + '] COLLATE SQL_Latin1_General_CP1_CI_AS IN (SELECT lt.[Values]
															FROM UserDetails ud
																INNER JOIN Lookups lt ON lt.LookupID=ud.LookupID
															WHERE ud.UserID=' + CONVERT(NVARCHAR, @UserID) + ')) '
		END
		
		print @SQL
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
			FROM dbo.UserSearchFilter
			WHERE UserID=@UserID AND FilterType = 1 AND RequestTypeID=@RequestTypeID 
			ORDER BY SortOrder
		END

		IF (ISNULL(@whereStr, '') = '')
		BEGIN
			SELECT @whereStr = COALESCE(@whereStr + '' ,'') + '[' + COLUMN_NAME + '],' 
			FROM tempdb.INFORMATION_SCHEMA.COLUMNS 
			WHERE (TABLE_NAME like '#Request%') AND COLUMN_NAME NOT IN ('RequestID', 'BatchID')
			ORDER BY TABLE_NAME
		END

		SET @whereStr = SUBSTRING(@whereStr, 0, LEN(@whereStr))

		SET @SQL = 'SELECT DISTINCT ' + CASE WHEN @RecordCount = 0 THEN 'TOP 20' ELSE '' END + @whereStr + ' 
					FROM dbo.#Request r 
					WHERE (1=1)'

		IF (@SQL LIKE '%[' + @ProductGroupColumn + ']%' AND @UserID IS NOT NULL)
		BEGIN
			SET @SQL += 'AND (' + CONVERT(NVARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(NVARCHAR, @ByPassProductCheck) + ' = 0 
															AND [' + @ProductGroupColumn + '] COLLATE SQL_Latin1_General_CP1_CI_AS IN (SELECT p.[values] 
																FROM UsersProducts up 
																	INNER JOIN Lookups p ON p.LookupID=up.ProductID 
																WHERE UserID=' + CONVERT(NVARCHAR, @UserID) + '))) '
		END
		
		IF (@SQL LIKE '%[' + @DepartmentColumn + ']%' AND @UserID IS NOT NULL)
		BEGIN
			SET @SQL += ' AND ([' + @DepartmentColumn + '] COLLATE SQL_Latin1_General_CP1_CI_AS IN (SELECT lt.[Values]
															FROM UserDetails ud
																INNER JOIN Lookups lt ON lt.LookupID=ud.LookupID
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
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
			DECLARE @ConfigXML XML
			SET @ConfigXML = NULL

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
				SET @ConfigXML = NULL

				SELECT T.c.query('Name').value('.', 'nvarchar(max)') AS Name, T.c.query('Value').value('.', 'nvarchar(max)') AS Value
				INTO #information
				FROM @xmlPart.nodes('/Info') T(c)
					
				IF EXISTS (SELECT 1 FROM #information WHERE Name='ProductConfigCommon')
				BEGIN
					SET @ConfigXML = NULL
					SELECT @ProductConfigCommon=Value FROM #information WHERE Name='ProductConfigCommon'

					SELECT @ConfigXML = (SELECT T.c.query('.') FROM c.Definition.nodes('/ArrayOfProductConfig/ProductConfig') T(c) WHERE T.c.value('@Name', 'varchar(MAX)') = @ProductConfigCommon)
					FROM dbo.Configurations c 
						INNER JOIN Lookups lct ON lct.LookupID=c.ConfigTypeID
						INNER JOIN Lookups lm ON lm.LookupID=c.ModeID
					WHERE lct.[Values] = 'ProductConfigCommon' AND c.[Version]=@Version AND lm.[Values] = @Mode
					
					IF (@ConfigXML IS NOT NULL)
					BEGIN
						UPDATE x
						SET x.ProductXML = @ConfigXML
						FROM Relab.ResultsXML x
						WHERE ID=@ID
					END
				END
					
				IF EXISTS (SELECT 1 FROM #information WHERE Name='SequenceConfigCommon')
				BEGIN
					SET @ConfigXML = NULL
					SELECT @SequenceConfigCommon=Value FROM #information WHERE Name='SequenceConfigCommon'
					
					SELECT @ConfigXML = (SELECT T.c.query('.') FROM c.Definition.nodes('/ArrayOfSequenceConfigCommon/SequenceConfigCommon') T(c) WHERE T.c.value('@Name', 'varchar(MAX)') = @SequenceConfigCommon)
					FROM dbo.Configurations c 
						INNER JOIN Lookups lct ON lct.LookupID=c.ConfigTypeID
						INNER JOIN Lookups lm ON lm.LookupID=c.ModeID
					WHERE lct.[Values] = 'SequenceConfigCommon' AND c.[Version]=@Version AND lm.[Values] = @Mode
					
					IF (@ConfigXML IS NOT NULL)
					BEGIN
						UPDATE x
						SET x.SequenceXML = @ConfigXML
						FROM Relab.ResultsXML x
						WHERE ID=@ID
					END
				END
				
				IF EXISTS (SELECT 1 FROM #information WHERE Name='StationConfigCommon')
				BEGIN
					SET @ConfigXML = NULL
					SELECT @StationConfigCommon=Value FROM #information WHERE Name='StationConfigCommon'

					SELECT @ConfigXML = (SELECT T.c.query('.') FROM c.Definition.nodes('/ArrayOfStationConfig/StationConfig') T(c) WHERE T.c.value('@Name', 'varchar(MAX)') = @StationConfigCommon)
					FROM dbo.Configurations c 
						INNER JOIN Lookups lct ON lct.LookupID=c.ConfigTypeID
						INNER JOIN Lookups lm ON lm.LookupID=c.ModeID
					WHERE lct.[Values] = 'StationConfigCommon' AND c.[Version]=@Version AND lm.[Values] = @Mode
					
					IF (@ConfigXML IS NOT NULL)
					BEGIN
						UPDATE x
						SET x.StationXML = @ConfigXML
						FROM Relab.ResultsXML x
						WHERE ID=@ID
					END
				END
				
				IF EXISTS (SELECT 1 FROM #information WHERE Name='TestConfigCommon')
				BEGIN
					SET @ConfigXML = NULL
					SELECT @TestConfigCommon=Value FROM #information WHERE Name='TestConfigCommon'
					
					SELECT @ConfigXML = (SELECT T.c.query('.') FROM c.Definition.nodes('/ArrayOfTestConfig/TestConfig') T(c) WHERE T.c.value('@Name', 'varchar(MAX)') = @TestConfigCommon)
					FROM dbo.Configurations c 
						INNER JOIN Lookups lct ON lct.LookupID=c.ConfigTypeID
						INNER JOIN Lookups lm ON lm.LookupID=c.ModeID
					WHERE lct.[Values] = 'TestConfigCommon' AND c.[Version]=@Version AND lm.[Values] = @Mode
					
					IF (@ConfigXML IS NOT NULL)
					BEGIN
						UPDATE x
						SET x.TestXML = (SELECT x.TestXML, @ConfigXML FOR XML PATH('TestConfigs'))
						FROM Relab.ResultsXML x
						WHERE ID=@ID
					END
				END			
				
				UPDATE ri
				SET IsArchived=1
				FROM Relab.ResultsInformation ri
					INNER JOIN Relab.ResultsXML rxml ON ri.XMLID=rxml.ID
					INNER JOIN #information i ON i.Name = ri.Name
				WHERE rxml.VerNum < @VerNum AND ISNULL(ri.IsArchived,0)=0 AND rxml.ResultID=@ResultID
					
				PRINT 'INSERT Version ' + CONVERT(NVARCHAR, @VerNum) + ' Information'
				INSERT INTO Relab.ResultsInformation(XMLID, Name, Value, IsArchived)
				SELECT @ID AS XMLID, Name, Value, 0
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
					T.c.query('Comments').value('.', 'nvarchar(1000)') AS [Comment],
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
						INNER JOIN #files f ON LOWER(LTRIM(RTRIM(f.[FileName]))) = LOWER(LTRIM(RTRIM(Relab.ResultsMeasurementsFiles.FileName)))
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
							INNER JOIN #files f ON LOWER(LTRIM(RTRIM(f.[FileName]))) = LOWER(LTRIM(RTRIM(Relab.ResultsMeasurementsFiles.FileName)))
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[BatchesJira]'
GO
CREATE TABLE [dbo].[BatchesJira]
(
[JIRAID] [int] NOT NULL IDENTITY(1, 1),
[BatchID] [int] NOT NULL,
[DisplayName] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Link] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Title] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_BatchesJira] on [dbo].[BatchesJira]'
GO
ALTER TABLE [dbo].[BatchesJira] ADD CONSTRAINT [PK_BatchesJira] PRIMARY KEY CLUSTERED  ([JIRAID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispGetBatchJIRAs]'
GO
CREATE PROCEDURE [dbo].[remispGetBatchJIRAs] @BatchID INT
AS
BEGIN
	SELECT 0 AS JIRAID, @BatchID As BatchID, '' AS DisplayName, '' AS Link, '' AS Title
	UNION
	SELECT bj.JIRAID, bj.BatchID, bj.DisplayName, bj.Link, bj.Title
	FROM BatchesJira bj
	WHERE bj.BatchID=@BatchID
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [dbo].[BatchesJira]'
GO
ALTER TABLE [dbo].[BatchesJira] ADD CONSTRAINT [FK_BatchesJira_Batches] FOREIGN KEY ([BatchID]) REFERENCES [dbo].[Batches] ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remispGetBatchJIRAs]'
GO
GRANT EXECUTE ON  [dbo].[remispGetBatchJIRAs] TO [remi]
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
ROLLBACK TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO