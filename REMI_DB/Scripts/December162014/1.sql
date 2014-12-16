/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 12/12/2014 10:51:16 AM

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
PRINT N'Creating types'
GO
CREATE TYPE [dbo].[SearchFields] AS TABLE
(
[TableType] [nvarchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ID] [int] NOT NULL,
[SearchTerm] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ColumnName] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Req].[Request]'
GO
ALTER TABLE [Req].[Request] ADD
[BatchID] [int] NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[vw_GetBatchRequestResult]'
GO
create VIEW [dbo].[vw_GetBatchRequestResult]
AS
SELECT b.QRANumber, b.BatchStatus, b.DateCreated, b.ExecutiveSummary, b.ExpectedSampleSize, b.IsMQual, b.UnitsToBeReturnedToRequestor,
	tu.BatchUnitNumber, tu.BSN, tu.IMEI, p.ProductGroupName, PT.[Values] As ProductType, ag.[Values] As AccessoryGroup,
	tc.[Values] As TestCenter, reqpur.[Values] As RequestPurpose, pty.[Values] As Priority, dpmt.[Values] As Department,
	rtn.[Values] As RequestName, rfs.Name, rfd.Value, ts.TestStageName, t.TestName, mn.[Values] As MeasurementName, 
	m.MeasurementValue, m.UpperLimit, m.LowerLimit, m.Archived, m.Comment, m.DegradationVal, m.Description, m.PassFail, m.ReTestNum,
	mut.[Values] As MeasurementUnitType, ri.Name As InformationName, ri.Value As InformationValue, ri.IsArchived As InformationArchived,
	rp.ParameterName, rp.Value As ParameterValue, rx.VerNum AS XMLVerNum, rx.StationName, rx.StartDate, rx.EndDate
FROM Batches b
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN Req.Request rq WITH(NOLOCK) ON rq.RequestNumber=b.QRANumber
	INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
	INNER JOIN Req.ReqFieldData rfd WITH(NOLOCK) ON rfd.RequestID=rq.RequestID
	INNER JOIN Req.ReqFieldSetup rfs WITH(NOLOCK) ON rfs.ReqFieldSetupID=rfd.ReqFieldSetupID
	INNER JOIN Req.RequestType rt ON rt.RequestTypeID=rfs.RequestTypeID
	INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
	INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID=r.TestStageID
	INNER JOIN Tests t WITH(NOLOCK) ON t.ID=r.TestID
	INNER JOIN Jobs j WITH(NOLOCK) ON j.ID=ts.JobID
	INNER JOIN Relab.ResultsXML rx WITH(NOLOCK) ON rx.ResultID=r.ID
	INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) ON m.ResultID=r.ID
	INNER JOIN Relab.ResultsInformation ri WITH(NOLOCK) ON ri.XMLID=rx.ID
	LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rp.ResultMeasurementID=m.ID
	LEFT OUTER JOIN Lookups PT WITH(NOLOCK) ON b.ProductTypeID=PT.LookupID  
	LEFT OUTER JOIN Lookups ag WITH(NOLOCK) ON b.AccessoryGroupID=ag.LookupID  
	LEFT OUTER JOIN Lookups tc WITH(NOLOCK) ON b.TestCenterLocationID=tc.LookupID
	LEFT OUTER JOIN Lookups reqpur WITH(NOLOCK) ON b.RequestPurpose=reqpur.LookupID
	LEFT OUTER JOIN Lookups pty WITH(NOLOCK) ON b.Priority=pty.LookupID
	LEFT OUTER JOIN Lookups dpmt WITH(NOLOCK) ON b.DepartmentID=dpmt.LookupID
	LEFT OUTER JOIN Lookups rtn WITH(NOLOCK) ON rt.TypeID=rtn.LookupID
	INNER JOIN Lookups mn WITH(NOLOCK) ON mn.LookupID = m.MeasurementTypeID 
	INNER JOIN Lookups mut WITH(NOLOCK) ON mut.LookupID = m.MeasurementUnitTypeID
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispGetLookupTypes]'
GO
CREATE PROCEDURE [dbo].[remispGetLookupTypes]
AS
BEGIN
	SELECT 0 AS LookupTypeID, 'SELECT...' AS Name
	UNION ALL
	SELECT lt.LookupTypeID, lt.Name 
	FROM LookupType lt
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
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
			CASE WHEN rfm.IntField = 'RequestLink' AND Value IS NULL THEN 'http://go/reqapp/' + @RequestNumber ELSE rfd.Value END AS Value, 
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
PRINT N'Creating [dbo].[UserSearchFilter]'
GO
CREATE TABLE [dbo].[UserSearchFilter]
(
[UserID] [int] NOT NULL,
[RequestTypeID] [int] NOT NULL,
[ColumnName] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FilterType] [int] NOT NULL,
[SortOrder] [int] NOT NULL
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_UserSearchFilter] on [dbo].[UserSearchFilter]'
GO
ALTER TABLE [dbo].[UserSearchFilter] ADD CONSTRAINT [PK_UserSearchFilter] PRIMARY KEY CLUSTERED  ([UserID], [RequestTypeID], [ColumnName])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Req].[RequestSearch]'
GO
CREATE PROCEDURE [Req].[RequestSearch] @RequestTypeID INT, @tv dbo.SearchFields READONLY, @UserID INT = NULL
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestStagesSelectList]'
GO
ALTER PROCEDURE [dbo].[remispTestStagesSelectList]
	@JobName nvarchar(400) = null,
	@TestStageType int = null
AS
	BEGIN
		if @JobName is not null
		begin
			SELECT ts.Comment,ts.ConcurrencyID,ts.ID,ts.processorder, ts.JobID,ts.LastUser,ts.TestID,ts.TestStageName,ts.TestStageType, j.jobname, 
				ISNULL(ts.IsArchived, 0) AS IsArchived, dbo.remifnTestStageCanDelete(ts.ID) AS CanDelete
			FROM teststages as ts,jobs as j
			where ((ts.jobid = j.id and j.Jobname = @Jobname) or @jobname is null) AND ISNULL(ts.IsArchived, 0) = 0 AND ISNULL(j.IsActive, 0) = 1
			order by JobName, ProcessOrder
		end
		else
		begin
			SELECT ts.Comment,ts.ConcurrencyID,ts.ID,ts.processorder,ts.JobID,ts.LastUser,ts.TestID,ts.TestStageName,ts.TestStageType,j.jobname, 
				ISNULL(ts.IsArchived, 0) AS IsArchived, dbo.remifnTestStageCanDelete(ts.ID) AS CanDelete
			FROM teststages as ts, Jobs as j
			where (ts.jobid = j.id and (ts.TestStageType = @TestStageType or @TestStageType is null)) AND ISNULL(ts.IsArchived, 0) = 0 AND ISNULL(j.IsActive, 0) = 1
			order by JobName, ProcessOrder
		end
	END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Req].[remispGetRequestTypes]'
GO
ALTER PROCEDURE Req.remispGetRequestTypes @UserName NVARCHAR(255)
AS
BEGIN
	SELECT lt.[Values] AS RequestType, l.[Values] AS Department, rta.IsActive, rt.HasIntegration, rt.RequestTypeID
	FROM Req.RequestTypeAccess rta
		INNER JOIN Lookups l ON rta.LookupID=l.LookupID
		INNER JOIN Req.RequestType rt ON rt.RequestTypeID=rta.RequestTypeID
		INNER JOIN Lookups lt ON rt.TypeID=lt.LookupID
		INNER JOIN UserDetails ud ON ud.LookupID = l.LookupID
		INNER JOIN Users u ON u.ID=ud.UserID
	WHERE u.LDAPLogin=@UserName
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Req].[RequestGet]'
GO
ALTER PROCEDURE [Req].[RequestGet] @RequestTypeID INT, @Department NVARCHAR(150)
AS
BEGIN
	DECLARE @Count INT
	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + rfm.IntField
		FROM Req.ReqFieldSetup rfs
			INNER JOIN Req.ReqFieldMapping rfm ON rfm.ExtField = rfs.Name AND rfm.RequestTypeID=@RequestTypeID
		WHERE rfs.RequestTypeID=@RequestTypeID
		ORDER BY '],[' +  rfm.IntField
		FOR XML PATH('')), 1, 2, '') + ']','[na]')
		
	SELECT @Count = COUNT(*)
	FROM Req.Request r
		INNER JOIN Req.ReqFieldData rfd ON rfd.RequestID=r.RequestID
		INNER JOIN Req.ReqFieldSetup rfs ON rfs.ReqFieldSetupID=rfd.ReqFieldSetupID
		INNER JOIN Req.RequestType rt ON rt.RequestTypeID=rfs.RequestTypeID
	WHERE rt.RequestTypeID=@RequestTypeID

	IF (@Count > 0)
	BEGIN
		SET @sql = 'SELECT ''http://go/requests/'' + CONVERT(VARCHAR, RequestNumber) AS RequestID, RequestNumber AS RequestNumber, [RequestStatus] AS STATUS, [ProductGroup] AS PRODUCT, [ProductType] AS PRODUCTTYPE,
			[AccessoryGroup] AS ACCESSORYGROUPNAME, [TestCenterLocation] AS TESTCENTER, [Department] AS DEPARTMENT, [SampleSize] AS SAMPLESIZE,
			[RequestedTest] AS Job, [RequestPurpose] AS PURPOSE, [CPRNumber] AS CPR, CONVERT(DateTime, REPLACE([ReportRequiredBy], ''-'','' '')) AS [Report Required By],
			[Priority] AS PRIORITY, [Requestor] AS REQUESTOR, CONVERT(DateTime, REPLACE([DateCreated], ''-'','' '')) AS CRE_DATE
			FROM 
				(
				SELECT r.RequestID, r.RequestNumber, rfd.Value, rfm.IntField
				FROM Req.Request r
					INNER JOIN Req.ReqFieldData rfd ON rfd.RequestID=r.RequestID
					INNER JOIN Req.ReqFieldSetup rfs ON rfs.ReqFieldSetupID=rfd.ReqFieldSetupID
					INNER JOIN Req.RequestType rt ON rt.RequestTypeID=rfs.RequestTypeID
					INNER JOIN Req.ReqFieldMapping rfm ON rfm.ExtField = rfs.Name
				WHERE rt.RequestTypeID=' + CONVERT(NVARCHAR, @RequestTypeID) + '
				) req PIVOT (MAX(Value) FOR IntField IN (' + @rows + ')) AS pvt
			WHERE [Department] = ''' + @Department + ''' AND
				[RequestStatus] IN (''Submitted'',''PM Review'',''Assigned'') '

		PRINT @sql
		EXEC (@sql)
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [dbo].[UserSearchFilter]'
GO
ALTER TABLE [dbo].[UserSearchFilter] ADD CONSTRAINT [FK_UserSearchFilter_Users] FOREIGN KEY ([UserID]) REFERENCES [dbo].[Users] ([ID])
ALTER TABLE [dbo].[UserSearchFilter] ADD CONSTRAINT [FK_UserSearchFilter_RequestType] FOREIGN KEY ([RequestTypeID]) REFERENCES [Req].[RequestType] ([RequestTypeID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [Req].[Request]'
GO
ALTER TABLE [Req].[Request] ADD CONSTRAINT [FK_Request_Batches] FOREIGN KEY ([BatchID]) REFERENCES [dbo].[Batches] ([ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Batches_Request]') AND parent_object_id = OBJECT_ID(N'[dbo].[Batches]'))
	ALTER TABLE [dbo].[Batches] DROP CONSTRAINT [FK_Batches_Request]
GO
UPDATE r
SET r.BatchID=b.id
FROM Req.Request r 
	inner join Batches b on b.QRANumber=r.RequestNumber
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remispGetLookupTypes]'
GO
GRANT EXECUTE ON  [dbo].[remispGetLookupTypes] TO [remi]
GO
PRINT N'Altering permissions on [Req].[RequestSearch]'
GO
GRANT EXECUTE ON  [Req].[RequestSearch] TO [remi]
GO
GRANT CONTROL ON TYPE:: [dbo].[SearchFields] TO [remi]
GO
ALTER PROCEDURE [dbo].[remispBatchesInsertUpdateSingleItem]
	@ID int OUTPUT,
	@QRANumber nvarchar(11),
	@Priority NVARCHAR(150) = 'NotSet', 
	@BatchStatus int, 
	@JobName nvarchar(400),
	@TestStageName nvarchar(255)=null,
	@ProductGroupName nvarchar(800),
	@ProductType nvarchar(800),
	@AccessoryGroupName nvarchar(800) = null,
	@Comment nvarchar(1000) = null,
	@TestCenterLocation nvarchar(400),
	@RequestPurpose nvarchar(200),
	@LastUser nvarchar(255),
	@ConcurrencyID rowversion OUTPUT,
	@testStageCompletionStatus int = null,
	@requestor nvarchar(500) = null,
	@unitsToBeReturnedToRequestor bit = null,
	@expectedSampleSize int = null,
	@reportApprovedDate datetime = null,
	@reportRequiredBy datetime = null,
	--@partName nvarchar(500) = null,
	--@assemblyNumber nvarchar(500) = null,
	--@assemblyRevision nvarchar(500) = null,
	@reqStatus nvarchar(500) = null,
	@cprNumber nvarchar(500) = null,
	@pmNotes nvarchar(500) = null,
	@MechanicalTools NVARCHAR(10) = null,
	@RequestPurposeID int = 0,
	@PriorityID INT = 0,
	@DepartmentID INT = 0,
	@Department NVARCHAR(150) = NULL,
	@ExecutiveSummary NVARCHAR(4000) = NULL
	AS
	DECLARE @ProductID INT
	DECLARE @ProductTypeID INT
	DECLARE @AccessoryGroupID INT
	DECLARE @TestCenterLocationID INT
	DECLARE @ReturnValue int
	DECLARE @maxid int
	DECLARE @LookupTypeID INT
	
	IF NOT EXISTS (SELECT 1 FROM Products WHERE LTRIM(RTRIM(ProductGroupName))= LTRIM(RTRIM(@ProductGroupName)))
	BEGIn
		INSERT INTO Products (ProductGroupName) Values (LTRIM(RTRIM(@ProductGroupName)))
	END
	
	IF NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='ProductType' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@ProductType)))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='ProductType'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@ProductType)))
	END
	
	IF LTRIM(RTRIM(@AccessoryGroupName)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='AccessoryType' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@AccessoryGroupName)))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='AccessoryType'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@AccessoryGroupName)))
	END
	
	IF LTRIM(RTRIM(@TestCenterLocation)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='TestCenter' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@TestCenterLocation)))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='TestCenter'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@TestCenterLocation)))
	END

	IF LTRIM(RTRIM(@Department)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='Department' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@Department)))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Department'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@Department)))
	END

	IF LTRIM(RTRIM(@RequestPurpose)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='RequestPurpose' AND (LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@RequestPurpose)) OR LTRIM(RTRIM([Description]))=LTRIM(RTRIM(@RequestPurpose))))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='RequestPurpose'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@RequestPurpose)))
	END

	IF LTRIM(RTRIM(@Priority)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='Priority' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@Priority)))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Priority'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@Priority)))
	END

	SELECT @RequestPurposeID = LookupID FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='RequestPurpose' AND ([Values] = @RequestPurpose OR [Description] = @RequestPurpose)
	SELECT @PriorityID = LookupID FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='Priority' AND [Values] = @Priority
	SELECT @ProductID = ID FROM Products WITH(NOLOCK) WHERE LTRIM(RTRIM(ProductGroupName))= LTRIM(RTRIM(@ProductGroupName))
	SELECT @ProductTypeID = LookupID FROM Lookups l WITH(NOLOCK) INNER JOIN LookupType lt WITH(NOLOCK) ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='ProductType' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@ProductType))
	SELECT @AccessoryGroupID = LookupID FROM Lookups l WITH(NOLOCK) INNER JOIN LookupType lt WITH(NOLOCK) ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='AccessoryType' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@AccessoryGroupName))
	SELECT @TestCenterLocationID = LookupID FROM Lookups l WITH(NOLOCK) INNER JOIN LookupType lt WITH(NOLOCK) ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='TestCenter' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@TestCenterLocation))
	SELECT @DepartmentID = LookupID FROM Lookups l WITH(NOLOCK) INNER JOIN LookupType lt WITH(NOLOCK) ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='Department' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@Department))
		
	IF (@ID IS NULL)
	BEGIN
		INSERT INTO Batches(
		QRANumber, 
		Priority, 
		BatchStatus, 
		JobName,
		TestStageName, 
		ProductTypeID,
		AccessoryGroupID,
		TestCenterLocationID,
		RequestPurpose,
		Comment,
		LastUser,
		TestStageCompletionStatus,
		Requestor,
		unitsToBeReturnedToRequestor,
		expectedSampleSize,
		reportApprovedDate,
		reportRequiredBy,
		trsStatus,
		cprNumber,
		pmNotes,
		ProductID, MechanicalTools, DepartmentID, ExecutiveSummary ) 
		VALUES 
		(@QRANumber, 
		@PriorityID, 
		@BatchStatus, 
		@JobName,
		@TestStageName,
		@ProductTypeID,
		@AccessoryGroupID,
		@TestCenterLocationID,
		@RequestPurposeID,
		@Comment,
		@LastUser,
		@testStageCompletionStatus,
		@Requestor,
		@unitsToBeReturnedToRequestor,
		@expectedSampleSize,
		@reportApprovedDate,
		@reportRequiredBy,
		@reqStatus,
		@cprNumber,
		@pmNotes,
		@ProductID, @MechanicalTools, @DepartmentID,@ExecutiveSummary)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE Batches SET 
		QRANumber = @QRANumber, 
		Priority = @PriorityID, 
		Jobname = @Jobname, 
		TestStagename = @TestStagename, 
		BatchStatus = @BatchStatus, 
		ProductTypeID = @ProductTypeID,
		AccessoryGroupID = @AccessoryGroupID,
		TestCenterLocationID=@TestCenterLocationID,
		RequestPurpose=@RequestPurposeID,
		Comment = @Comment, 
		LastUser = @LastUser,
		Requestor = @Requestor,
		TestStageCompletionStatus = @testStageCompletionStatus,
		unitsToBeReturnedToRequestor=@unitsToBeReturnedToRequestor,
		expectedSampleSize=@expectedSampleSize,
		reportApprovedDate=@reportApprovedDate,
		reportRequiredBy=@reportRequiredBy,
		trsStatus=@reqStatus,
		cprNumber=@cprNumber,
		pmNotes=@pmNotes ,
		ProductID=@ProductID,
		MechanicalTools = @MechanicalTools, DepartmentID = @DepartmentID,ExecutiveSummary=@ExecutiveSummary
		WHERE (ID = @ID) AND (ConcurrencyID = @ConcurrencyID)

		SELECT @ReturnValue = @ID
	END
	
	IF EXISTS (SELECT 1 FROM Req.Request WHERE RequestNumber=@QRANumber)
		BEGIN
			UPDATE Req.Request SET BatchID=@ID WHERE RequestNumber=@QRANumber
		END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM Batches WITH(NOLOCK) WHERE ID = @ReturnValue)
	SET @ID = @ReturnValue
	
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN 0
	END
GO
GRANT EXECUTE ON remispBatchesInsertUpdateSingleItem TO Remi
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
commit TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO