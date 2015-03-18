/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 1/21/2015 9:40:50 AM

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
PRINT N'Altering [Req].[RequestFieldSetup]'
GO
ALTER PROCEDURE [Req].[RequestFieldSetup] @RequestTypeID INT, @IncludeArchived BIT = 0, @RequestNumber NVARCHAR(12) = NULL
AS
BEGIN
	DECLARE @RequestID INT
	DECLARE @TrueBit BIT
	DECLARE @FalseBit BIT
	DECLARE @RequestType NVARCHAR(150)
	SET @RequestID = 0
	SET @TrueBit = CONVERT(BIT, 1)
	SET @FalseBit = CONVERT(BIT, 0)

	SELECT @RequestType=lrt.[values] FROM Req.RequestType rt INNER JOIN Lookups lrt ON lrt.LookupID=rt.TypeID WHERE rt.RequestTypeID=@RequestTypeID

	IF (@RequestNumber IS NOT NULL)
		BEGIN
			SELECT @RequestID = RequestID FROM Req.Request WHERE RequestNumber=@RequestNumber
		END
	ELSE
		BEGIN
			SELECT @RequestNumber = REPLACE(RequestNumber, @RequestType + '-' + Right(Year(getDate()),2) + '-', '') + 1 
			FROM Req.Request 
			WHERE RequestNumber LIKE @RequestType + '-' + Right(Year(getDate()),2) + '-%'
			
			IF (LEN(@RequestNumber) < 4)
			BEGIN
				SET @RequestNumber = REPLICATE('0', 4-LEN(@RequestNumber)) + @RequestNumber
			END
		
			IF (@RequestNumber IS NULL)
				SET @RequestNumber = '0001'
		
			SET @RequestNumber = @RequestType + '-' + Right(Year(getDate()),2) + '-' + @RequestNumber
		END

	SELECT rfs.ReqFieldSetupID, @RequestType AS RequestType, rfs.Name, lft.[Values] AS FieldType, rfs.FieldTypeID, 
			lvt.[Values] AS ValidationType, rfs.FieldValidationID, ISNULL(rfs.IsRequired, 0) AS IsRequired, rfs.DisplayOrder, 
			rfs.ColumnOrder, ISNULL(rfs.Archived, 0) AS Archived, rfs.Description, rfs.OptionsTypeID, @RequestTypeID AS RequestTypeID,
			@RequestNumber AS RequestNumber, @RequestID AS RequestID, 
			CASE WHEN rfm.IntField = 'RequestLink' AND Value IS NULL THEN 'http://go/requests/' + @RequestNumber ELSE rfd.Value END AS Value, 
			rfm.IntField, rfm.ExtField,
			CASE WHEN rfm.ID IS NOT NULL THEN 1 ELSE 0 END AS InternalField,
			CASE WHEN @RequestID = 0 THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END AS NewRequest, Req.RequestType.IsExternal AS IsFromExternalSystem, rfs.Category,
			rfs.ParentReqFieldSetupID, Req.RequestType.HasIntegration, rfsp.Name As ParentFieldSetupName
	FROM Req.RequestType
		INNER JOIN Lookups lrt ON lrt.LookupID=Req.RequestType.TypeID
		INNER JOIN Req.ReqFieldSetup rfs ON rfs.RequestTypeID=Req.RequestType.RequestTypeID                  
		INNER JOIN Lookups lft ON lft.LookupID=rfs.FieldTypeID
		LEFT OUTER JOIN Lookups lvt ON lvt.LookupID=rfs.FieldValidationID
		LEFT OUTER JOIN Req.ReqFieldSetupRole ON Req.ReqFieldSetupRole.ReqFieldSetupID=rfs.ReqFieldSetupID
		LEFT OUTER JOIN Req.Request ON RequestNumber=@RequestNumber
		LEFT OUTER JOIN Req.ReqFieldData rfd ON rfd.ReqFieldSetupID=rfs.ReqFieldSetupID AND rfd.RequestID=Req.Request.RequestID
		LEFT OUTER JOIN Req.ReqFieldMapping rfm ON rfm.RequestTypeID=Req.RequestType.RequestTypeID AND rfm.ExtField=rfs.Name AND ISNULL(rfm.IsActive, 0) = 1
		LEFT OUTER JOIN Req.ReqFieldSetup rfsp ON rfsp.ReqFieldSetupID=rfs.ParentReqFieldSetupID
	WHERE (lrt.[Values] = @RequestType) AND
		(
			(@IncludeArchived = @TrueBit)
			OR
			(@IncludeArchived = @FalseBit AND ISNULL(rfs.Archived, @FalseBit) = @FalseBit)
			OR
			(@IncludeArchived = @FalseBit AND rfd.Value IS NOT NULL AND ISNULL(rfs.Archived, @FalseBit) = @TrueBit)
		)
	ORDER BY Category, ISNULL(rfs.DisplayOrder, 0) ASC
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
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
	CREATE TABLE dbo.#ReqNum (RequestNumber NVARCHAR(11))

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

	SET @SQL =  REPLACE((select sqlvar AS [text()] from dbo.#executeSQL for xml path('')), '&#x0D;','')
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
			ALTER TABLE dbo.#RR ADD TestName NVARCHAR(400), TestStageName NVARCHAR(400), 
				TestRunStartDate DATETIME, TestRunEndDate DATETIME, 
				MeasurementName NVARCHAR(150), MeasurementValue NVARCHAR(500), 
				UpperLimit NVARCHAR(255), LowerLimit NVARCHAR(255), Archived BIT, Comment NVARCHAR(400), 
				DegradationVal DECIMAL(10,3), Description NVARCHAR(800), PassFail BIT, ReTestNum INT,
				MeasurementUnitType NVARCHAR(150)
		END

		SET @rows = REPLACE(@rows, '[', 'r.[')

		INSERT INTO #executeSQL (sqlvar)
		VALUES ('INSERT INTO dbo.#RR 
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

		SET @SQL =  REPLACE(REPLACE(REPLACE((select sqlvar AS [text()] from dbo.#executeSQL for xml path('')), '&#x0D;',''), '&gt;', ' >'), '&lt;', ' <')
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
					SELECT @whereStr = COALESCE(@whereStr + '' ,'') + '[' + Name + '] = ''' + Val + '''' + ' AND ' FROM dbo.#Params
					SET @whereStr = ' WHERE ' +  SUBSTRING(@whereStr, 0, LEN(@whereStr)-2)
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
					SELECT @whereStr = COALESCE(@whereStr + '' ,'') + '[' + Name + '] = ''' + Val + '''' + ' AND ' FROM dbo.#Infos
					SET @whereStr = ' WHERE ' +  SUBSTRING(@whereStr, 0, LEN(@whereStr)-2)
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

		SET @SQL = 'SELECT DISTINCT ' + SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ' FROM dbo.#RR rr 
			LEFT OUTER JOIN dbo.#RRParameters p ON rr.ID=p.ResultMeasurementID
			LEFT OUTER JOIN dbo.#RRInformation i ON i.RID = rr.ResultID 
			WHERE ((' + CONVERT(NVARCHAR, @LimitedByInfo) + ' = 0) OR (' + CONVERT(NVARCHAR, @LimitedByInfo) + ' = 1 AND i.RID IS NOT NULL ))
				AND ((' + CONVERT(NVARCHAR, @LimitedByParam) + ' = 0) OR (' + CONVERT(NVARCHAR, @LimitedByParam) + ' = 1 AND p.ResultMeasurementID IS NOT NULL ))'
		
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

		SET @SQL = 'SELECT DISTINCT ' +  SUBSTRING(@whereStr, 0, LEN(@whereStr)) + ' FROM dbo.#Request r '

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