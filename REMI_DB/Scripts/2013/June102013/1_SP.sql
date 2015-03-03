/*
Run this script on:

        sqlqa10ykf\haqa1.RemiQA    -  This database will be modified

to synchronize it with:

        CI0000001593275\SQLDEVELOPER.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.3.8 from Red Gate Software Ltd at 6/5/2013 7:16:32 PM

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
alter table Products add QAPLocation NVARCHAR(255) NULL
GO
PRINT N'Creating [dbo].[remispAddRemovePermissiontoRole]'
GO
CREATE PROCEDURE [dbo].[remispAddRemovePermissiontoRole] @Permission NVARCHAR(256), @Role NVARCHAR(256)
AS
BEGIN
DECLARE @RoleID UNIQUEIDENTIFIER
DECLARE @PermissionID UNIQUEIDENTIFIER

SELECT @PermissionID = PermissionID FROM aspnet_Permissions WHERE Permission=@Permission
SELECT @RoleID = RoleID FROM aspnet_Roles WHERE RoleName=@Role


	IF EXISTS (SELECT 1 FROM aspnet_PermissionsInRoles WHERE PermissionID=@PermissionID AND RoleID=@RoleID)
		BEGIN
			DELETE FROM aspnet_PermissionsInRoles WHERE PermissionID=@PermissionID AND RoleID=@RoleID
		END
	ELSE
		BEGIN
			INSERT INTO aspnet_PermissionsInRoles (PermissionID, RoleID) VALUES (@PermissionID, @RoleID)
		END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispRolePermissions]'
GO
CREATE PROCEDURE [dbo].[remispRolePermissions]
AS
BEGIN
	DECLARE @rows VARCHAR(8000)
	DECLARE @query VARCHAR(4000)
	SELECT @rows=  ISNULL(STUFF(
	( 
	SELECT DISTINCT '],[' + r.RoleName
	FROM  dbo.aspnet_Roles r
	ORDER BY '],[' +  r.RoleName
	FOR XML PATH('')), 1, 2, '') + ']','[na]')


	SET @query = '
		SELECT *
		FROM
		(
			SELECT CASE WHEN pr.PermissionID IS NOT NULL THEN 1 ELSE NULL END As Row, p.Permission, r.RoleName
			FROM dbo.aspnet_Roles r
				LEFT OUTER JOIN dbo.aspnet_PermissionsInRoles pr on r.RoleId=pr.RoleID
				INNER JOIN dbo.aspnet_Permissions p on pr.PermissionID=p.PermissionID
			WHERE p.Permission IS NOT NULL
		)r
		PIVOT 
		(
			MAX(row) 
			FOR RoleName 
				IN ('+@rows+')
		) AS pvt'
	EXECUTE (@query)
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remispAddRemovePermissiontoRole]'
GO
GRANT EXECUTE ON  [dbo].[remispAddRemovePermissiontoRole] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispRolePermissions]'
GO
GRANT EXECUTE ON  [dbo].[remispRolePermissions] TO [remi]
GO

insert into aspnet_Roles (ApplicationId,RoleId,RoleName,LoweredRoleName, Description,hasProductCheck) 
values ('892170D7-F95A-4AE1-A7E7-C1994D392790','E56DA858-572E-4F34-A3D9-89411321953C','TestCenterAdmin','testcenteradmin',null,null)
GO

ALTER PROCEDURE [dbo].[remispYourBatchesGetActiveBatches] @UserID int, @ByPassProductCheck INT = 0, @Year INT = 0
AS	
	SELECT BatchesRows.ID, BatchesRows.ProductGroupName,BatchesRows.QRANumber, (BatchesRows.QRANumber + ' ' + BatchesRows.ProductGroupName) AS Name
	FROM     
		(
			SELECT p.ProductGroupName,b.QRANumber, b.ID
				FROM Batches as b
				inner join Products p on p.ID=b.ProductID
			WHERE ( 
					(@Year = 0 AND BatchStatus NOT IN(5,7))
					OR
					(@Year > 0 AND b.QRANumber LIKE 'QRA-' + RIGHT(CONVERT(NVARCHAR, @Year), 2) + '%')
				  )
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
		) AS BatchesRows
	ORDER BY BatchesRows.QRANumber
	RETURN
GO
GRANT EXECUTE ON remispYourBatchesGetActiveBatches TO Remi
GO
ALTER PROCEDURE [dbo].remispGetBatchDocuments @QRANumber nvarchar(11)
AS
BEGIN
	DECLARE @JobName NVARCHAR(400)
	DECLARE @ProductID INT	
	SELECT @JobName = JobName, @ProductID = ProductID FROM Batches WHERE QRANumber=@QRANumber

	SELECT (j.JobName + ' WI') AS WIType, j.WILocation AS Location
	FROM Jobs j
	WHERE j.JobName=@JobName AND LTRIM(RTRIM(ISNULL(j.WILocation, ''))) <> ''
	UNION
	SELECT DISTINCT tname AS WIType, TestWI AS Location
	FROM [dbo].[vw_GetTaskInfo]
	WHERE QRANumber=@QRANumber and processorder > 0 AND testtype IN (1,2) AND LTRIM(RTRIM(ISNULL(TestWI,''))) <> ''
	UNION
	SELECT (j.JobName + ' Procedure') AS WIType, j.ProcedureLocation AS Location
	FROM Jobs j
	WHERE j.JobName=@JobName AND LTRIM(RTRIM(ISNULL(j.ProcedureLocation, ''))) <> ''
	UNION
	SELECT 'Specification' AS WIType, 'https://hwqaweb.rim.net/pls/trs/data_entry.main?req=QRA-ENG-SP-11-0001' AS Location
	UNION
	SELECT 'QAP' As WIType, p.QAPLocation AS Location
	FROM Products p
	WHERE p.ID=@ProductID AND QAPLocation IS NOT NULL
END
GO
GRANT EXECUTE ON remispGetBatchDocuments TO REMI
GO
alter table ProductConfigValues alter column Value NVARCHAR(2000) NOT NULL
GO
alter table ProductConfigValuesAudit alter column Value NVARCHAR(2000) NOT NULL
GO
ALTER PROCEDURE [dbo].remispProductConfigurationUpload AS
BEGIN
	CREATE TABLE #temp2 (ID INT, ParentID INT NULL, NodeType INT, LocalName NVARCHAR(100), Text NVARCHAR(2000), ID_temp INT IDENTITY(1,1), ID_NEW INT NULL, ParentID_NEW INT NULL)
	CREATE TABLE #temp3 (LookupID INT, Type NVARCHAR(150), LocalName NVARCHAR(150), ID INT IDENTITY(1,1))
	DECLARE @ProductID INT
	DECLARE @TestID INT
	DECLARE @MaxID INT
	DECLARE @MaxLookupID INT
	DECLARE @idoc INT
	DECLARE @ID INT
	DECLARE @xml XML
	DECLARE @LastUser NVARCHAR(255)

	IF ((SELECT COUNT(*) FROM ProductConfigurationUpload WHERE ISNULL(IsProcessed,0)=0 AND ProductID IN (SELECT ID FROM Products))=0)
		RETURN

	SELECT TOP 1 @ID=ID, @xml =ProductConfigXML, @ProductID=ProductID, @TestID=TestID, @LastUser=LastUser
	FROM ProductConfigurationUpload 
	WHERE ISNULL(IsProcessed,0)=0 AND ProductID IN (SELECT ID FROM Products)
	
	exec sp_xml_preparedocument @idoc OUTPUT, @xml
	
	SELECT @MaxID = ISNULL(MAX(ID),0)+1 FROM ProductConfiguration
	SELECT @MaxLookupID = ISNULL(MAX(LookupID),0)+1 FROM Lookups

	SELECT * 
	INTO #temp
	FROM OPENXML(@idoc, '/')

	INSERT INTO #temp2 (ID, ParentID, NodeType, LocalName, Text, ParentID_NEW)
	SELECT ID, ParentID, NodeType, LocalName, '' AS Text, 0 AS ParentID_NEW
	FROM #temp 
	WHERE NodeType=1 AND (SELECT COUNT(ISNULL(ParentID,0)) FROM #temp t WHERE t.ParentID=#temp.ID AND t.ParentID IS NOT NULL)>1
	UNION
	SELECT ID, ParentID, NodeType, LocalName, '' AS Text, 0 AS ParentID_NEW
	FROM #temp 
	WHERE NodeType=1 AND (SELECT COUNT(*) FROM #temp t1 WHERE t1.NodeType=1 AND t1.ParentID=#temp.ID AND t1.ParentID IS NOT NULL GROUP BY t1.ParentID )=1
	UNION
	SELECT ID, ParentID, NodeType, LocalName, '' AS Text, 0 AS ParentID_NEW
	FROM #temp 
	WHERE NodeType=1 AND (SELECT COUNT(ISNULL(ParentID,0)) FROM #temp t WHERE t.NodeType IN (1,2) AND t.ParentID=#temp.ID AND t.ParentID IS NOT NULL AND t.NodeType <> 3)=1
	
	UPDATE #temp2
	SET ID_NEW = ID_temp + @MaxID

	UPDATE #temp2
	SET ParentID_NEW = (SELECT t.ID_NEW FROM #temp2 t WHERE #temp2.ParentID=t.ID)
	WHERE #temp2.ParentID IS NOT NULL

	SET IDENTITY_INSERT ProductConfiguration ON

	INSERT INTO ProductConfiguration (ID, ParentId, ViewOrder, NodeName, TestID, LastUser, ProductID)
	SELECT ID_NEW, CASE WHEN ParentID_NEW = 0 THEN NULL ELSE ParentID_NEW END, ROW_NUMBER() OVER (ORDER BY id) AS ViewOrder, LocalName, @TestID, @LastUser, @ProductID
	FROM #temp2
	ORDER BY ID, parentid

	SET IDENTITY_INSERT ProductConfiguration OFF
		
	INSERT INTO #temp3
	SELECT DISTINCT 0 AS LookupID, 'Configuration' AS Type, LTRIM(RTRIM(LocalName)) AS LocalName
	FROM #temp 
	WHERE NodeType=2 AND LocalName NOT IN (SELECT Lookups.[Values] FROM Lookups WHERE Type='Configuration')
		
	INSERT INTO #temp3
	SELECT DISTINCT 0 AS LookupID, 'Configuration' AS Type, LTRIM(RTRIM(LocalName)) AS LocalName
	FROM #temp 
	WHERE NodeType=1 AND LocalName NOT IN (SELECT Lookups.[Values] FROM Lookups WHERE Type='Configuration')
		AND ID IN (SELECT ParentID FROM #temp WHERE NodeType=3)
	
	UPDATE #temp3 SET LookupID=ID+@MaxLookupID

	insert into Lookups (LookupID, Type, [Values])
	select LookupID, Type, localname as [Values] from #temp3
		
	INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
	SELECT ISNULL((SELECT t2.Text FROM #temp t2 WHERE t2.NodeType=3 AND t2.ParentID=#temp.ID),'') AS Value, 
		CASE WHEN #temp.NodeType=2 THEN (SELECT LookupID FROM Lookups WHERE Type='Configuration' AND [values]=#temp.LocalName) ELSE NULL END As LookupID, 
		(SELECT ID_NEW FROM #temp2 WHERE #temp.ParentID=#temp2.ID) AS ProductConfigID, @LastUser As LastUser, 1 AS IsAttribute
	FROM #temp
	WHERE #temp.NodeType=2 		

	INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
	SELECT ISNULL(#temp.Text,'') AS Value, (SELECT Lookups.LookupID FROM #temp t INNER JOIN Lookups ON Type='Configuration' AND LOWER(LTRIM(RTRIM([Values])))=LOWER(LTRIM(RTRIM(t.LocalName))) WHERE t.NodeType=1 AND t.id=#temp.parentid) AS LookupID,
		(SELECT #temp2.ID_NEW 
		FROM #temp2 	
			INNER JOIN #temp t1 ON t1.NodeType=1 AND #temp2.ID=t1.parentid
		WHERE #temp.ParentID=t1.ID) AS ProductConfigID, 
		@LastUser As LastUser, 0 AS IsAttribute
	FROM #temp
	WHERE NodeType=3 AND ParentID NOT IN (Select ID FROM #temp WHERE #temp.NodeType=2)
		
	INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
	SELECT ISNULL(#temp.Text,'') AS Value, (SELECT Lookups.LookupID FROM #temp t INNER JOIN Lookups ON Type='Configuration' AND LOWER(LTRIM(RTRIM([Values])))=LOWER(LTRIM(RTRIM(t.LocalName))) WHERE t.NodeType=1 AND t.id=#temp.id) AS LookupID,
		(SELECT #temp2.ID_NEW 
		FROM #temp2 	
			INNER JOIN #temp t1 ON t1.NodeType=1 AND #temp2.ID=t1.parentid
		WHERE #temp.ID=t1.ID) AS ProductConfigID, 
		@LastUser As LastUser, 0 AS IsAttribute
	FROM #temp
	WHERE NodeType=1 AND ID NOT IN (Select ParentID FROM #temp t WHERE t.NodeType =3)
		AND ID NOT IN (Select ID FROM #temp2)	

	DROP TABLE #temp2
	DROP TABLE #temp
	DROP TABLE #temp3
	
	UPDATE ProductConfigurationUpload SET IsProcessed=1 WHERE ID=@ID
END
GO
GRANT EXECUTE ON remispProductConfigurationUpload TO Remi
GO
ALTER PROCEDURE [Relab].[remispResultsSummary] @BatchID INT
AS
BEGIN
	SELECT r.ID, r.VerNum, ts.TestStageName, t.TestName, tu.BatchUnitNumber, CASE WHEN PassFail=1 THEN 'Pass' ELSE 'Fail' END AS PassFail, 
		CONVERT(varchar, EndDate, 106) AS EndDate, r.ResultsXML
	FROM Relab.Results r
		INNER JOIN TestStages ts ON r.TestStageID=ts.ID
		INNER JOIN Tests t ON r.TestID=t.ID
		INNER JOIN TestUnits tu ON tu.ID=r.TestUnitID
	WHERE tu.BatchID=@BatchID
	ORDER BY tu.BatchUnitNumber, r.VerNum, ts.TestStageName, t.TestName
END
GO
GRANT EXECUTE ON [Relab].[remispResultsSummary] TO Remi
GO


ALTER PROCEDURE Relab.remispResultsFileProcessing
AS
BEGIN
	BEGIN TRANSACTION

	BEGIN TRY
		DECLARE @ID INT
		DECLARE @idoc INT
		DECLARE @RowID INT
		DECLARE @xml XML
		DECLARE @xmlPart XML
		DECLARE @FinalResult BIT
		DECLARE @EndDate NVARCHAR(MAX)
		DECLARE @Duration NVARCHAR(MAX)

		IF ((SELECT COUNT(*) FROM Relab.Results WHERE ISNULL(IsProcessed,0)=0)=0)
			RETURN

		SELECT TOP 1 @ID=ID, @xml = ResultsXML
		FROM Relab.Results
		WHERE ISNULL(IsProcessed,0)=0

		SELECT @xmlPart = T.c.query('.') 
		FROM @xml.nodes('/TestResults/Header') T(c)

		exec sp_xml_preparedocument @idoc OUTPUT, @xmlPart

		SELECT * 
		INTO #temp
		FROM OPENXML(@idoc, '/')

		--Insert Header values
		INSERT INTO Relab.ResultsHeader (ResultID, Name, Value)
		SELECT @ID As ResultID, LocalName AS Name,(SELECT t2.text FROM #temp t2 WHERE t2.ParentID=t.ID) AS Value
		FROM #temp t
		WHERE t.NodeType=1 AND t.ParentID IS NOT NULL AND t.LocalName NOT IN ('FinalResult','DateCompleted')
			AND LTRIM(RTRIM(CONVERT(NVARCHAR(1500), (SELECT t2.text FROM #temp t2 WHERE t2.ParentID=t.ID)))) <> ''

		select @FinalResult = (CASE WHEN T.c.query('FinalResult').value('.', 'nvarchar(max)') = 'Pass' THEN 1 ELSE 0 END),
			@EndDate = T.c.query('DateCompleted').value('.', 'nvarchar(max)'),
			@Duration = T.c.query('Duration').value('.', 'nvarchar(max)')
		FROM @xmlPart.nodes('/Header') T(c)

		SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ' ')
		SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ':')
		SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ':')

		SELECT  ROW_NUMBER() OVER (ORDER BY T.c) AS RowID, T.c.query('.') AS value 
		INTO #temp2
		FROM   @xml.nodes('/TestResults/Measurements/Measurement') T(c)

		SELECT @RowID = MIN(RowID) FROM #temp2

		WHILE (@RowID IS NOT NULL)
		BEGIN
			SELECT @xmlPart  = value FROM #temp2 WHERE RowID=@RowID	

			select T.c.query('MeasurementName').value('.', 'nvarchar(max)') AS MeasurementType,
				T.c.query('LowerLimit').value('.', 'nvarchar(max)') AS LowerLimit,
				T.c.query('UpperLimit').value('.', 'nvarchar(max)') AS UpperLimit,
				T.c.query('MeasuredValue').value('.', 'nvarchar(max)') AS MeasurementValue,
				(CASE WHEN T.c.query('PassFail').value('.', 'nvarchar(max)') = 'Pass' THEN 1 ELSE 0 END) AS PassFail,
				T.c.query('Units').value('.', 'nvarchar(max)') AS UnitType,
				T.c.query('FileName').value('.', 'nvarchar(max)') AS [FileName]
			INTO #measurement
			FROM @xmlPart.nodes('/Measurement') T(c)
		
			INSERT INTO Lookups (LookupID, Type,[Values], IsActive)
			SELECT DISTINCT (SELECT MAX(LookupID)+1 FROM Lookups) AS LookupID, 'UnitType' AS Type, LTRIM(RTRIM(UnitType)) AS [values], 1
			FROM #measurement 
			WHERE LTRIM(RTRIM(UnitType)) NOT IN (SELECT [Values] FROM Lookups WHERE Type='UnitType') AND UnitType IS NOT NULL AND UnitType NOT IN ('N/A')
		
			INSERT INTO Lookups (LookupID, Type,[Values], IsActive)
			SELECT DISTINCT (SELECT MAX(LookupID)+1 FROM Lookups) AS LookupID, 'MeasurementType' AS Type, LTRIM(RTRIM(MeasurementType)) AS [values], 1
			FROM #measurement 
			WHERE LTRIM(RTRIM(MeasurementType)) NOT IN (SELECT [Values] FROM Lookups WHERE Type='MeasurementType') AND MeasurementType IS NOT NULL AND MeasurementType NOT IN ('N/A')
		
			INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, [File], PassFail)
			SELECT @ID As ResultID, l2.LookupID AS MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, l.[LookupID] AS MeasurementUnitTypeID, FileName AS [File], CONVERT(BIT, PassFail)
			FROM #measurement
				LEFT OUTER JOIN Lookups l ON l.Type='UnitType' AND l.[Values]=LTRIM(RTRIM(#measurement.UnitType))
				LEFT OUTER JOIN Lookups l2 ON l2.Type='MeasurementType' AND l2.[Values]=LTRIM(RTRIM(#measurement.MeasurementType))
		
			DECLARE @ResultMeasurementID INT
			SELECT @ResultMeasurementID = MAX(ID)
			FROM Relab.ResultsMeasurements
			WHERE ResultID=@ID 
			
			INSERT INTO Relab.ResultsParameters (ResultMeasurementID, ParameterName, Value)
			SELECT @ResultMeasurementID AS ResultMeasurementID, T.c.value('@ParameterName','nvarchar(max)') AS ParameterName, T.c.query('.').value('.', 'nvarchar(max)') AS Value
			FROM @xmlPart.nodes('/Measurement/Parameters/Parameter') T(c)
		
			DROP TABLE #measurement
		
			SELECT @RowID = MIN(RowID) FROM #temp2 WHERE RowID > @RowID
		END
		
		If (CHARINDEX('.', @Duration) > 0)
			SET @Duration = SUBSTRING(@Duration, 1, CHARINDEX('.', @Duration)-1)

		UPDATE Relab.Results 
		SET PassFail=@FinalResult, EndDate=CONVERT(DATETIME, @EndDate), 
			StartDate =dateadd(s,datediff(s,0,convert(DATETIME,@Duration)), CONVERT(DATETIME, @EndDate)),  
			IsProcessed=1 
		WHERE ID=@ID
	
		DROP TABLE #temp
		DROP TABLE #temp2

		PRINT 'COMMIT TRANSACTION'
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		  SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_SEVERITY() AS ErrorSeverity, ERROR_STATE() as ErrorState, ERROR_PROCEDURE() as ErrorProcedure, ERROR_LINE() as ErrorLine, ERROR_MESSAGE() as ErrorMessage

		  PRINT 'ROLLBACK TRANSACTION'
		  ROLLBACK TRANSACTION
	END CATCH
END
GO
GRANT EXECUTE ON Relab.remispResultsFileProcessing TO REMI
GO
ALTER PROCEDURE [Relab].[remispResultMeasurements] @ResultID INT, @OnlyFails INT = 0
AS
BEGIN
	SET NOCOUNT ON
	SELECT rm.ID, lt.[Values] As MeasurementType, LowerLimit, UpperLimit, MeasurementValue, lu.[Values] As UnitType, 
		CASE WHEN PassFail=1 THEN 'Pass' ELSE 'Fail' END AS PassFail,
		Relab.ResultsParametersComma(rm.ID) AS [Parameters]
	FROM Relab.ResultsMeasurements rm
		INNER JOIN Lookups lu ON lu.Type='UnitType' AND lu.LookupID=rm.MeasurementUnitTypeID
		INNER JOIN Lookups lt ON lt.Type='MeasurementType' AND lt.LookupID=rm.MeasurementTypeID
	WHERE ResultID=@ResultID AND ((@OnlyFails = 1 AND PassFail=0) OR (@OnlyFails = 0))
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispResultMeasurements] TO Remi
GO
CREATE NONCLUSTERED INDEX [IX_ParameterNameVal] ON [Relab].[ResultsParameters] 
(
	[ResultMeasurementID] ASC
)
INCLUDE ( [Value],
[ParameterName]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
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