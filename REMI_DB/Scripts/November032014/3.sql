/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 10/28/2014 6:24:00 PM

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
PRINT N'Altering [dbo].[remispTrackingLocationsGetSpecificLocationForUsersTestCenter]'
GO
ALTER procedure [dbo].[remispTrackingLocationsGetSpecificLocationForUsersTestCenter] @username nvarchar(255), @locationname nvarchar(500)
AS
declare @selectedID int

select top(1) @selectedID = tl.ID 
from TrackingLocations as tl
	INNER JOIN Lookups l ON tl.TestCenterLocationID=l.LookupID
	INNER JOIN Users as u ON u.TestCentreID = l.lookUpID
	INNER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
where TrackingLocationName = @locationname and u.LDAPLogin = @username

return @selectedid
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[FunctionalMatrixByTestRecord]'
GO
ALTER PROCEDURE [Relab].[FunctionalMatrixByTestRecord] @TRID INT = NULL, @TestStageID INT, @TestID INT, @BatchID INT, @UnitIDs NVARCHAR(MAX) = NULL, @FunctionalType INT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	DECLARE @LookupType NVARCHAR(20)
	DECLARE @LookupTypeID INT
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
		INSERT INTO #units SELECT s FROM dbo.Split(',',@UnitIDs)
	END
	
	IF (@FunctionalType = 1)
		SET @LookupType = 'SFIFunctionalMatrix'
	ELSE IF (@FunctionalType = 2)
		SET @LookupType = 'MFIFunctionalMatrix'
	ELSE IF (@FunctionalType = 3)
		SET @LookupType = 'AccFunctionalMatrix'
	ELSE
		SET @LookupType = 'SFIFunctionalMatrix'
	
	SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name=@LookupType

	SELECT @rows=  ISNULL(STUFF(
		(SELECT DISTINCT '],[' + l.[Values]
		FROM dbo.Lookups l
		WHERE LookupTypeID=@LookupTypeID
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
							LEFT OUTER JOIN Lookups lr ON lr.LookupTypeID=''' + CONVERT(VARCHAR, @LookupTypeID) + ''' AND rm.MeasurementTypeID=lr.LookupID
						WHERE rm.ResultID=r.ID AND lr.[values] = l.[values] AND rm.Archived = 0)
				END As Row
			FROM dbo.Lookups l
			INNER JOIN TestUnits tu ON tu.BatchID = ' + CONVERT(VARCHAR, @BatchID) + ' AND 
				(
					(' + CONVERT(VARCHAR, ISNULL(CONVERT(VARCHAR,@TestUnitID), 'NULL')) + ' IS NULL)
					OR
					(' + CONVERT(VARCHAR, ISNULL(CONVERT(VARCHAR,@TestUnitID), 'NULL')) + ' IS NOT NULL AND tu.ID=' + CONVERT(VARCHAR, ISNULL(CONVERT(VARCHAR,@TestUnitID), 'NULL')) + ')
				)
			INNER JOIN #units ON tu.ID=#units.ID
			LEFT OUTER JOIN Relab.Results r ON r.TestID = ' + CONVERT(VARCHAR, @TestID) + ' AND r.TestStageID = ' + CONVERT(VARCHAR, @TestStageID) + ' 
				AND r.TestUnitID = tu.ID
			WHERE l.LookupTypeID=''' + CONVERT(VARCHAR, @LookupTypeID) + '''
			) te 
			PIVOT (MAX(row) FOR [Values] IN (' + @rows + ')) AS pvt
			ORDER BY BatchUnitNumber'

	PRINT @sql
	EXEC(@sql)
	DROP TABLE #units
	
	SET NOCOUNT OFF
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectChamberBatches]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectChamberBatches]
/*	'===============================================================
	'   NAME:                	remispBatchesSelectDailyList
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retreives the batches in chamber
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/

	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@TestCentreLocation Int =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc',
	@ByPassProductCheck INT = 0,
	@UserID int
	AS
SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
	BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName,
	batchesrows.ProductID,batchesrows.QRANumber,
	BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName, 
	batchesrows.TestStageCompletionStatus,testunitcount,
	(CASE WHEN batchesrows.WILocation IS NULL THEN NULL ELSE batchesrows.WILocation END) AS jobWILocation,
	(testUnitCount -
		(select COUNT(*) 
			  from TestUnits as tu WITH(NOLOCK)
			  INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			  where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
	) as HasUnitsToReturnToRequestor,
	ISNULL(
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
			WHERE ta.BatchID = BatchesRows.ID and ta.Active=1), 
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
			WHERE ta.Active=1 AND ISNULL(ta.taskID,0) = 0 AND ta.BatchID = BatchesRows.ID)
		) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions,
	batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,batchesrows.RQID As ReqID, batchesrows.TestCenterLocationID,
	AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate, IsMQual, JobID, MechanicalTools, BatchesRows.RequestPurposeID,
	BatchesRows.PriorityID, DepartmentID, Department
	FROM     
	(
		SELECT ROW_NUMBER() OVER 
			(ORDER BY 
				case when @sortExpression='qra' and @direction='asc' then qranumber end,
				case when @sortExpression='qra' and @direction='desc' then qranumber end desc,
				case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
				case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
				case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
				case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
				case when @sortExpression='job' and @direction='asc' then jobname end,
				case when @sortExpression='job' and @direction='desc' then jobname end desc,
				case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
				case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
				case when @sortExpression='priority' and @direction='asc' then Priority end asc,
				case when @sortExpression='priority' and @direction='desc' then Priority end desc,
				case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
				case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
				case when @sortExpression is null then Priority end desc
			) AS Row, 
			ID, 
			QRANumber, 
			Comment,
			RequestPurpose, 
			Priority,
			TestStageName, 
			BatchStatus, 
			ProductGroupName, 
			ProductType,
			AccessoryGroupName,
			ProductTypeID,
			AccessoryGroupID,
			ProductID,
			JobName, 
			TestCenterLocationID,
			TestCenterLocation,
			LastUser, 
			ConcurrencyID,
			b.TestStageCompletionStatus,
			(select count(*) from testunits WITH(NOLOCK) where testunits.batchid = b.id) as testUnitCount,
			b.WILocation,b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, JobID, MechanicalTools,
			RequestPurposeID, PriorityID, DepartmentID, Department
		FROM 
		(
			SELECT DISTINCT b.ID, 
				b.QRANumber, 
				b.Comment,
				b.RequestPurpose As RequestPurposeID, 
				b.Priority AS PriorityID,
				b.TestStageName, 
				b.BatchStatus, 
				p.ProductGroupName, 
				b.ProductTypeID,
				b.AccessoryGroupID,
				l.[Values] AS ProductType,
				l2.[Values] As AccessoryGroupName,
				p.ID As ProductID,
				b.JobName, 
				b.LastUser, 
				b.TestCenterLocationID,
				l3.[Values] As TestCenterLocation,
				b.ConcurrencyID,
				b.TestStageCompletionStatus, j.WILocation,b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, 
				b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, MechanicalTools, l4.[Values] As RequestPurpose, l5.[Values] As Priority, b.DepartmentID, l6.[Values] AS Department
			FROM Batches AS b WITH(NOLOCK)
				LEFT OUTER JOIN Jobs as j WITH(NOLOCK) on b.jobname = j.JobName 
				inner join TestStages as ts WITH(NOLOCK) on j.ID = ts.JobID
				inner join Tests as t WITH(NOLOCK) on ts.TestID = t.ID
				inner join DeviceTrackingLog AS dtl WITH(NOLOCK) 
				INNER JOIN TrackingLocations AS tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.ID
				INNER JOIN TrackingLocationTypes as tlt WITH(NOLOCK) on tl.TrackingLocationTypeID = tlt.id 
				inner join TestUnits AS tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID on tu.CurrentTestName = t.TestName and b.id = tu.batchid  --batches where there's a tracking log
				INNER JOIN Products p WITH(NOLOCK) ON b.ProductID=p.id
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON b.TestCenterLocationID=l3.LookupID  
				LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON b.RequestPurpose=l4.LookupID   
				LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON b.Priority=l5.LookupID
				LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON b.DepartmentID=l6.LookupID
			WHERE (b.TestCenterLocationID = @TestCentreLocation or @TestCentreLocation is null) and j.TechnicalOperationsTest = 1 and j.MechanicalTest=0 and  tlt.TrackingLocationFunction= 4  and t.ResultBasedOntime = 1 AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL
			AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
		)as b
	) as batchesrows
 	WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex = -1 OR @maximumRows = -1) 
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispResultsSearch]'
GO
ALTER PROCEDURE Relab.remispResultsSearch @MeasurementTypeID INT, @TestID INT, @ParameterName NVARCHAR(255)=NULL, @ParameterValue NVARCHAR(250)=NULL, @ProductIDs NVARCHAR(MAX) = NULL, @JobNameIDs NVARCHAR(MAX) = NULL, @TestStageIDs NVARCHAR(MAX) = NULL, @TestCenterID INT = 0, @ShowFailureOnly INT = 0
AS
BEGIN		
	DECLARE @LoopValue NVARCHAR(500)
	DECLARE @ID INT
	DECLARE @query VARCHAR(MAX)
	DECLARE @query2 VARCHAR(MAX)
	DECLARE @FalseBit BIT
	SET @FalseBit = CONVERT(BIT, 0)
	SET @query = ''	
	SET @query2 = ''
	
	CREATE TABLE #products (ID INT)
	CREATE TABLE #jobs (ID INT)
	CREATE TABLE #stageIDs (ID INT)
	INSERT INTO #stageIDs SELECT s FROM dbo.Split(',', @TestStageIDs)
	INSERT INTO #jobs SELECT s FROM dbo.Split(',',  @JobNameIDs)
	INSERT INTO #products SELECT s FROM dbo.Split(',', @ProductIDs)
	
	SET @query = 'SELECT b.QRANumber, tu.BatchUnitNumber, ts.TestStageName AS TestStageName, rm.MeasurementValue AS MeasurementValue, rm.LowerLimit, rm.UpperLimit, 
		r.ID AS ResultID, b.ID AS BatchID, pd.ProductGroupName, pd.ID AS ProductID, j.JobName, l.[values] AS TestCenter, CASE WHEN rm.PassFail=1 THEN ''Pass'' ELSE ''Fail'' END AS PassFail,
		Relab.ResultsParametersComma(rm.ID) As Params, lm.[Values] AS MeasurementName, ISNULL(CONVERT(NVARCHAR, rm.DegradationVal), ''N/A'') AS DegradationVal 
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestUnits tu WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
		INNER JOIN Relab.ResultsMeasurements rm WITH(NOLOCK) ON r.ID=rm.ResultID
		INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
		INNER JOIN Products pd WITH(NOLOCK) ON pd.ID = b.ProductID
		INNER JOIN Jobs j WITH(NOLOCK) ON j.ID=ts.JobID
		INNER JOIN Lookups l WITH(NOLOCK) ON l.LookupID=b.TestCenterLocationID
		INNER JOIN #products products WITH(NOLOCK) ON products.ID = pd.ID
		INNER JOIN Lookups lm ON lm.LookupID = rm.MeasurementTypeID
		INNER JOIN #jobs job WITH(NOLOCK) ON job.id=j.ID
		INNER JOIN #stageIDs stage WITH(NOLOCK) ON stage.id=ts.ID
	WHERE r.TestID='+CONVERT(VARCHAR,@TestID)+' AND MeasurementValue IS NOT NULL 
		AND
		(
			(' + CONVERT(VARCHAR,@MeasurementTypeID) + ' > 0 AND rm.MeasurementTypeID=' + CONVERT(VARCHAR,@MeasurementTypeID) + ')
			OR
			(' + CONVERT(VARCHAR,@MeasurementTypeID) + ' = 0)
		)		
		AND
		(
			(' + CONVERT(VARCHAR,@TestCenterID) + ' > 0 AND b.TestCenterLocationID=' + CONVERT(VARCHAR,@TestCenterID) + ')
			OR
			(' + CONVERT(VARCHAR,@TestCenterID) + ' = 0)
		) '

	IF (@ParameterName IS NOT NULL)
		SET @query2 = ' AND (Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterName,'')+''' <> '''' THEN ''N'' ELSE ''V'' END)='''+ ISNULL(@ParameterName,'')+''') '
	IF (@ParameterValue IS NOT NULL)
		SET @query2 = ' AND (Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END)='''+ ISNULL(@ParameterValue,'')+''') '


	SET @query2 += ' AND ISNULL(rm.Archived,0)=' + CONVERT(VARCHAR, @FalseBit) + '
		AND
		(
			(' + CONVERT(VARCHAR, @ShowFailureOnly) + ' = 1 AND rm.PassFail=0)
			OR
			(' + CONVERT(VARCHAR, @ShowFailureOnly) + ' = 0)
		)
	ORDER BY QRANumber, BatchUnitNumber, TestStageName'
	
	print @query
	print @query2

	EXEC(@query + @query2)
	
	DROP TABLE #stageIDs
	DROP TABLE #jobs
	DROP TABLE #products
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispUsersSelectSingleItemByBadgeNumber]'
GO
ALTER PROCEDURE [dbo].[remispUsersSelectSingleItemByBadgeNumber] @BadgeNumber int
AS
	SELECT u.BadgeNumber,u.ConcurrencyID,u.ID,u.LastUser,u.LDAPLogin, u.TestCentreID, ISNULL(u.IsActive,1) As IsActive, u.DefaultPage, Lookups.[values] As TestCentre,
		u.ByPassProduct, u.DepartmentID, ld.[Values] AS Department
	FROM Users as u
		LEFT OUTER JOIN Lookups ON LookupID=TestCentreID
		LEFT OUTER JOIN Lookups ld ON ld.LookupID=DepartmentID
	WHERE BadgeNumber = @BadgeNumber
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestExceptionsGetBatchExceptions]'
GO
ALTER procedure [dbo].[remispTestExceptionsGetBatchExceptions] @qraNumber nvarchar(11) = null
AS
--get any for the product
select distinct pvt.id, null as batchunitnumber, pvt.ReasonForRequest AS ReasonForRequestID,p.ProductGroupName,b.JobName, ts.teststagename
, t.TestName, (SELECT TOP 1 LastUser FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS ConcurrencyID,
pvt.TestStageID, pvt.TestUnitID, pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID,
l2.[Values] As AccessoryGroupName, l.[Values] As ProductType, pvt.IsMQual, l3.[Values] As TestCenter, l3.[LookupID] As TestCenterID,
l4.[Values] AS ReasonForRequest
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
	LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.LookupID=pvt.TestCenterID
	LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON l4.LookupID=pvt.ReasonForRequest
	, Batches as b, teststages ts WITH(NOLOCK), Jobs j WITH(NOLOCK)
where b.QRANumber = @qranumber 
	and (ts.JobID = j.ID or j.ID is null)
	and (b.JobName = j.JobName or j.JobName is null)
	and pvt.TestUnitID is null
	and (ts.id = pvt.teststageid or pvt.TestStageID is null)
	and 
	(
		(pvt.ProductID = b.ProductID and pvt.ReasonForRequest is null) 
		or 
		(pvt.ProductID = b.ProductID and pvt.ReasonForRequest = b.RequestPurpose)
		or
		(pvt.ProductID is null and pvt.ReasonForRequest = b.RequestPurpose)
		or
		(pvt.ProductID is null and pvt.ReasonForRequest is null)
	)
	AND
	(
		(pvt.AccessoryGroupID IS NULL)
		OR
		(pvt.AccessoryGroupID IS NOT NULL AND pvt.AccessoryGroupID = b.AccessoryGroupID)
	)
	AND
	(
		(pvt.ProductTypeID IS NULL)
		OR
		(pvt.ProductTypeID IS NOT NULL AND pvt.ProductTypeID = b.ProductTypeID)
	)
	AND
	(
		(pvt.TestCenterID IS NULL)
		OR
		(pvt.TestCenterID IS NOT NULL AND pvt.TestCenterID = b.TestCenterLocationID)
	)
	AND
	(
		(pvt.IsMQual IS NULL)
		OR
		(pvt.IsMQual IS NOT NULL AND pvt.IsMQual = b.IsMQual)
	)

union all

--then get any for the test units.
select distinct pvt.id, tu.BatchUnitNumber, pvt.ReasonForRequest AS ReasonForRequestID,p.ProductGroupName,b.JobName, 
(select teststagename from teststages WITH(NOLOCK) where teststages.id =pvt.TestStageid) as teststagename, t.testname,
(SELECT TOP 1 LastUser FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS ConcurrencyID
, pvt.TestStageID, pvt.TestUnitID, pvt.ProductTypeID, pvt.AccessoryGroupID,pvt.ProductID,
l2.[Values] As AccessoryGroupName, l.[Values] As ProductType, pvt.IsMQual, l3.[Values] As TestCenter, l3.[LookupID] As TestCenterID,
l4.[Values] AS ReasonForRequest
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
	LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.LookupID=pvt.TestCenterID
	LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON l4.LookupID=pvt.ReasonForRequest
	INNER JOIN testunits tu WITH(NOLOCK) ON tu.ID=pvt.TestUnitID
	INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
WHERE b.QRANumber = @qranumber and tu.batchid = b.id and pvt.TestUnitID = tu.id
order by pvt.TestUnitID desc,TestName
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispProductConfigurationUpload]'
GO
ALTER PROCEDURE [dbo].remispProductConfigurationUpload AS
BEGIN
	CREATE TABLE #temp2 (ID INT, ParentID INT NULL, NodeType INT, LocalName NVARCHAR(100), Text NVARCHAR(2000), ID_temp INT IDENTITY(1,1), ID_NEW INT NULL, ParentID_NEW INT NULL)
	CREATE TABLE #temp3 (LookupID INT, Type NVARCHAR(150), LocalName NVARCHAR(150), ID INT IDENTITY(1,1))
	DECLARE @MaxID INT
	DECLARE @MaxLookupID INT
	DECLARE @LookupTypeID INT
	DECLARE @idoc INT
	DECLARE @ID INT
	DECLARE @xml XML
	DECLARE @LastUser NVARCHAR(255)

	IF ((SELECT COUNT(*) FROM ProductConfigurationUpload WHERE ISNULL(IsProcessed,0)=0 AND ProductID IN (SELECT ID FROM Products))=0)
		RETURN
	
	SELECT @LookupTypeID=LookupTypeID FROM LookupType WHERE Name='Configuration'

	WHILE ((SELECT COUNT(*) FROM ProductConfigurationUpload WHERE ISNULL(IsProcessed,0)=0)>0)
	BEGIN
		SELECT TOP 1 @ID=pcu.ID, @xml =pcv.PCXML, @LastUser=pcu.LastUser
		FROM ProductConfigurationUpload pcu
			INNER JOIN ProductConfigurationVersion pcv ON pcu.ID=pcv.UploadID AND pcv.VersionNum=1
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

		INSERT INTO ProductConfiguration (ID, ParentId, ViewOrder, NodeName, LastUser, UploadID)
		SELECT ID_NEW, CASE WHEN ParentID_NEW = 0 THEN NULL ELSE ParentID_NEW END, ROW_NUMBER() OVER (ORDER BY id) AS ViewOrder, LocalName, @LastUser, @ID
		FROM #temp2
		ORDER BY ID, parentid

		SET IDENTITY_INSERT ProductConfiguration OFF
			
		INSERT INTO #temp3
		SELECT DISTINCT 0 AS LookupID, @LookupTypeID AS LookupTypeID, LTRIM(RTRIM(LocalName)) AS LocalName
		FROM #temp 
		WHERE NodeType=2 AND LocalName NOT IN (SELECT Lookups.[Values] FROM Lookups WHERE LookupTypeID=@LookupTypeID)
			
		INSERT INTO #temp3
		SELECT DISTINCT 0 AS LookupID, @LookupTypeID AS LookupTypeID, LTRIM(RTRIM(LocalName)) AS LocalName
		FROM #temp 
		WHERE NodeType=1 AND LocalName NOT IN (SELECT Lookups.[Values] FROM Lookups WHERE LookupTypeID=@LookupTypeID)
			AND ID IN (SELECT ParentID FROM #temp WHERE NodeType=3)
		
		UPDATE #temp3 SET LookupID=ID+@MaxLookupID

		insert into Lookups (LookupID, Type, [Values])
		select LookupID, Type, localname as [Values] from #temp3
			
		INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
		SELECT ISNULL((SELECT t2.Text FROM #temp t2 WHERE t2.NodeType=3 AND t2.ParentID=#temp.ID),'') AS Value, 
			CASE WHEN #temp.NodeType=2 THEN (SELECT LookupID FROM Lookups WHERE LookupTypeID=@LookupTypeID AND [values]=#temp.LocalName) ELSE NULL END As LookupID, 
			(SELECT ID_NEW FROM #temp2 WHERE #temp.ParentID=#temp2.ID) AS ProductConfigID, @LastUser As LastUser, 1 AS IsAttribute
		FROM #temp
		WHERE #temp.NodeType=2 		

		INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
		SELECT ISNULL(#temp.Text,'') AS Value, (SELECT Lookups.LookupID FROM #temp t INNER JOIN Lookups ON LookupTypeID=@LookupTypeID AND LOWER(LTRIM(RTRIM([Values])))=LOWER(LTRIM(RTRIM(t.LocalName))) WHERE t.NodeType=1 AND t.id=#temp.parentid) AS LookupID,
			(SELECT #temp2.ID_NEW 
			FROM #temp2 	
				INNER JOIN #temp t1 ON t1.NodeType=1 AND #temp2.ID=t1.parentid
			WHERE #temp.ParentID=t1.ID) AS ProductConfigID, 
			@LastUser As LastUser, 0 AS IsAttribute
		FROM #temp
		WHERE NodeType=3 AND ParentID NOT IN (Select ID FROM #temp WHERE #temp.NodeType=2)
			
		INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
		SELECT ISNULL(#temp.Text,'') AS Value, (SELECT Lookups.LookupID FROM #temp t INNER JOIN Lookups ON LookupTypeID=@LookupTypeID AND LOWER(LTRIM(RTRIM([Values])))=LOWER(LTRIM(RTRIM(t.LocalName))) WHERE t.NodeType=1 AND t.id=#temp.id) AS LookupID,
			(SELECT #temp2.ID_NEW 
			FROM #temp2 	
				INNER JOIN #temp t1 ON t1.NodeType=1 AND #temp2.ID=t1.parentid
			WHERE #temp.ID=t1.ID) AS ProductConfigID, 
			@LastUser As LastUser, 0 AS IsAttribute
		FROM #temp
		WHERE NodeType=1 AND ID NOT IN (Select ParentID FROM #temp t WHERE t.NodeType =3)
			AND ID NOT IN (Select ID FROM #temp2)	
		
		UPDATE ProductConfigurationUpload SET IsProcessed=1 WHERE ID=@ID
		
		DELETE FROM #temp2
		DELETE FROM #temp3
		DROP TABLE #temp
	END
		
	DROP TABLE #temp2
	DROP TABLE #temp3	
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispSaveProductConfigurationDetails]'
GO
ALTER PROCEDURE [dbo].[remispSaveProductConfigurationDetails] @PCID INT, @configID INT, @lookupID INT, @lookupValue NVARCHAR(2000), @LastUser NVARCHAR(255), @IsAttribute BIT = 0, @LookupAlt NVARCHAR(255)
AS
BEGIN
	DECLARE @LookupTypeID INT
	SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Configuration'

	IF (@lookupID = 0 AND LEN(LTRIM(RTRIM(@LookupAlt))) > 0)
	BEGIN
		SELECT @lookupID = LookupID FROM Lookups WHERE [values]=@LookupAlt AND LookupTypeID =@LookupTypeID
		
		IF (@lookupID IS NULL OR @lookupID = 0)
		BEGIN
			SELECT @lookupID = MAX(LookupID)+1 FROM Lookups
			
			INSERT INTO Lookups (LookupID, LookupTypeID,[Values], IsActive) VALUES (@lookupID, @LookupTypeID, LTRIM(RTRIM(@LookupAlt)), 1)
		END
	END

	If ((@configID IS NULL OR @configID = 0 OR NOT EXISTS (SELECT 1 FROM ProductConfigValues WHERE ID=@configID)) AND @lookupValue IS NOT NULL AND LTRIM(RTRIM(@lookupValue)) <> '' AND @LookupID IS NOT NULL AND @LookupID > 0 AND EXISTS(SELECT 1 FROM ProductConfiguration WHERE ID=@PCID))
	BEGIN
		INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
		VALUES (@lookupValue, @LookupID, @PCID, @LastUser, ISNULL(@IsAttribute,0))
	END
	ELSE IF (@configID > 0)
	BEGIN
		UPDATE ProductConfigValues
		SET Value=@lookupValue, LookupID=@LookupID, LastUser=@LastUser, ProductConfigID=@PCID, IsAttribute=ISNULL(@IsAttribute,0)
		WHERE ID=@configID
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispGetLookups]'
GO
ALTER PROCEDURE [dbo].[remispGetLookups] @Type NVARCHAR(150), @ProductID INT = NULL, @ParentID INT = NULL
AS
BEGIN
	DECLARE @LookupTypeID INT
	SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name=@Type

	SELECT l.LookupID, @Type AS [Type], l.[Values] As LookupType, CASE WHEN pl.ID IS NOT NULL THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END As HasAccess, 
		l.Description, ISNULL(l.ParentID, 0) AS ParentID, p.[Values] AS Parent
	INTO #type
	FROM Lookups l
		LEFT OUTER JOIN ProductLookups pl ON pl.ProductID=@ProductID AND l.LookupID=pl.LookupID
		LEFT OUTER JOIN Lookups p ON p.LookupID=l.ParentID
	WHERE l.LookupTypeID=@LookupTypeID AND l.IsActive=1 AND 
		(
			(@ParentID IS NOT NULL AND ISNULL(@ParentID, 0) <> 0 AND ISNULL(l.ParentID, 0) = ISNULL(@ParentID, 0))
			OR
			(@ParentID IS NULL OR ISNULL(@ParentID, 0) = 0)
		)
		
	; WITH cte AS
	(
		SELECT LookupID, [Type], LookupType, HasAccess, Description, ISNULL(ParentID, 0) AS ParentID, Parent,
			cast(row_number()over(partition by ParentID order by LookupType) as varchar(max)) as [path],
			0 as level,
			row_number()over(partition by ParentID order by LookupType) / power(10.0,0) as x
		FROM #type
		WHERE ISNULL(ParentID, 0) = 0
		UNION ALL
		SELECT t.LookupID, t.[Type], t.LookupType, t.HasAccess, t.Description, t.ParentID, t.Parent,
		[path] +'-'+ cast(row_number() over(partition by t.ParentID order by t.LookupType) as varchar(max)),
		level+1,
		x + row_number()over(partition by t.ParentID order by t.LookupType) / power(10.0,level+1)
		FROM cte
			INNER JOIN #type t on cte.LookupID = t.ParentID
	)
	select LookupID, [Type], LookupType, HasAccess, Description, ParentID, (CONVERT(NVARCHAR, ParentID) + '-' + Parent) AS Parent, x, (CONVERT(NVARCHAR, LookupID) + '-' + LookupType) AS DisplayText
	FROM cte
	UNION ALL
	SELECT 0 AS LookupID, @Type AS [Type], '' As LookupType, CONVERT(BIT, 0) As HasAccess, NULL AS Description, 0 AS ParentID, NULL AS Parent, NULL AS x, '' AS DisplayText
	ORDER BY x		
		
	DROP TABLE #type
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectListAtTrackingLocation]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectListAtTrackingLocation]
	@TrackingLocationID int,
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc'
AS
IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (select  COUNT(*) from (select DISTINCT b.id	FROM  Batches AS b WITH(NOLOCK) INNER JOIN
                      DeviceTrackingLog AS dtl WITH(NOLOCK) INNER JOIN
                      TrackingLocations AS tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.ID INNER JOIN
                      TestUnits AS tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID ON b.id = tu.BatchID --batches where there's a tracking log
				WHERE  tl.id = @TrackingLocationID AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL)as records)  --and the tracking log has not been 'scanned' out
		RETURN
	END

SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
				 BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,
				 BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName,batchesrows.ProductType, batchesrows.AccessoryGroupName,Batchesrows.ProductID,
				 batchesrows.TestStageCompletionStatus,testunitcount,
				 (testunitcount -
			   (select COUNT(*) 
			  from TestUnits as tu WITH(NOLOCK)
			  INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			  where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
			  ) as HasUnitsToReturnToRequestor,
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,BatchesRows.TestCenterLocationID,
	ISNULL(
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
			WHERE ta.BatchID = BatchesRows.ID and ta.Active=1), 
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
			WHERE ta.Active=1 AND ISNULL(ta.taskID,0) = 0 AND ta.BatchID = BatchesRows.ID)
		) as ActiveTaskAssignee,
	CONVERT(BIT,0) AS HasBatchSpecificExceptions,
	batchesrows.AccessoryGroupID,batchesrows.ProductTypeID,BatchesRows.RQID As ReqID, AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, 
	ReportApprovedDate, IsMQual, JobID, ExecutiveSummary, MechanicalTools, batchesrows.RequestPurposeID, batchesrows.PriorityID, DepartmentID, Department
	FROM     
		(SELECT ROW_NUMBER() OVER (ORDER BY 
case when @sortExpression='qra' and @direction='asc' then qranumber end,
case when @sortExpression='qra' and @direction='desc' then qranumber end desc,
case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
case when @sortExpression='job' and @direction='asc' then jobname end,
case when @sortExpression='job' and @direction='desc' then jobname end desc,
case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
case when @sortExpression='priority' and @direction='asc' then Priority end asc,
case when @sortExpression='priority' and @direction='desc' then Priority end desc,
case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
case when @sortExpression is null then Priority end desc
		) AS Row, 
		           ID, 
                      QRANumber, 
                      Comment,
                      RequestPurpose, 
                      Priority,
                      TestStageName, 
                      BatchStatus, 
                      ProductGroupName, 
					  ProductType,
					  AccessoryGroupName,
					  ProductTypeID,
					  AccessoryGroupID,
					  ProductID,
                      JobName, 
					  TestCenterLocationID,
                      TestCenterLocation,
                      LastUser, 
                      ConcurrencyID,
                      b.TestStageCompletionStatus,
					 (select count(*) from testunits WITH(NOLOCK) where testunits.batchid = b.id) as testUnitCount,
					 b.WILocation, b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, JobID,
					 ExecutiveSummary, MechanicalTools, RequestPurposeID, PriorityID, DepartmentID, Department
                      from
				(SELECT DISTINCT 
                      b.ID, 
                      b.QRANumber, 
                      b.Comment,
                      b.RequestPurpose As RequestPurposeID, 
                      b.Priority AS PriorityID,
                      b.TestStageName, 
                      b.BatchStatus, 
                      p.ProductGroupName, 
					  b.ProductTypeID,
					  b.AccessoryGroupID,
					  l.[Values] As ProductType,
					  l2.[Values] As AccessoryGroupName,
					  l3.[Values] As TestCenterLocation,
					  p.ID As ProductID,
                      b.JobName, 
                      b.LastUser, 
                      b.TestCenterLocationID,
                      b.ConcurrencyID,
                      b.TestStageCompletionStatus,
                      j.WILocation,
					  b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, j.ID As JobID,
					  ExecutiveSummary, MechanicalTools, l4.[Values] AS RequestPurpose, l5.[Values] AS Priority, b.DepartmentID, l6.[Values] AS Department
				FROM Batches AS b 
					INNER JOIN DeviceTrackingLog AS dtl WITH(NOLOCK) 
					INNER JOIN TrackingLocations AS tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.ID 
					INNER JOIN TestUnits AS tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID ON b.id = tu.batchid --batches where there's a tracking log
					inner join Products p WITH(NOLOCK) on p.ID=b.ProductID
					LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName
					LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID=l.LookupID  
					LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON b.AccessoryGroupID=l2.LookupID 
					LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON b.TestCenterLocationID=l3.LookupID 
					LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON b.RequestPurpose=l4.LookupID   
					LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON b.Priority=l5.LookupID
					LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON b.DepartmentID=l6.LookupID
WHERE     tl.id = @TrackingLocationId AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL)as b) as batchesrows
	WHERE
	 ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1) 
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispEnvironmentalReport]'
GO
ALTER procedure [dbo].[remispEnvironmentalReport]
	@startDate datetime,
	@enddate datetime,
	@reportBasedOn int = 1,
	@testLocationID INT,
	@ByPassProductCheck INT,
	@UserID INT, @NewWay BIT = 0
AS
SET NOCOUNT ON
DECLARE @TrueBit BIT
SET @TrueBit = CONVERT(BIT, 1)

If (@NewWay <> 0)
BEGIN
	IF @testLocationID IS NULL
	BEGIN
		SET @testLocationID = 0
	END

	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	DECLARE @sql2 VARCHAR(8000)
	DECLARE @sql3 VARCHAR(8000)

	SELECT @rows=  ISNULL(STUFF((
		SELECT DISTINCT '],[' + p.ProductGroupName
		FROM Batches b WITH(NOLOCK)
			INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
			INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID and ba.inserttime between @startdate and @enddate
		WHERE (b.TestCenterLocationID = @testLocationID or @testLocationID = 0) 
			AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
		ORDER BY '],[' +  p.ProductGroupName
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

	SET @sql = 'SELECT '' '' AS '' '', *, SUM(ISNULL(' + REPLACE(@rows, ',',', 0) + ISNULL(') + ',0)) As Total 
	FROM (
		SELECT ''# Completed Testing'' As Item, (CASE WHEN ' + CONVERT(VARCHAR, @reportBasedOn) + '=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS num, p.ProductGroupName 
		FROM Batches b WITH(NOLOCK)
			INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
			INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus = 8 and ba.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			INNER JOIN BatchesAudit ba2 WITH(NOLOCK) ON b.ID = ba2.BatchID AND ba2.BatchStatus <> 8 and ba2.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		WHERE (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY p.productgroupname
		UNION
		SELECT ''# in Chamber'' As Item, (CASE WHEN ' + CONVERT(VARCHAR, @reportBasedOn) + '=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS num, p.productgroupname 
		FROM DeviceTrackingLog dtl WITH(NOLOCK)
			INNER JOIN TestUnits tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID
			INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
			INNER JOIN TrackingLocations tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.id
			INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tl.TrackingLocationTypeID = tlt.ID AND tlt.TrackingLocationFunction = 4 --4 means chamber type device (environmentstressing)
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		WHERE dtl.InTime BETWEEN ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			AND (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY p.productgroupname
		UNION
		SELECT ''# Units in FA'' As Item, COUNT(tr.ID) as num, p.productgroupname 
		FROM (
				SELECT tra.TestRecordId 
				FROM TestRecordsaudit tra WITH(NOLOCK)
				WHERE tra.Action IN (''I'',''U'') AND tra.Status IN (3, 4) and tra.InsertTime BETWEEN ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''--FQRaised and FARequired
				GROUP BY TestRecordId
			) as xer
			INNER JOIN TestRecords tr WITH(NOLOCK) ON tr.ID= xer.TestRecordId
			INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
			INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		WHERE (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY ProductGroupName
		UNION
		SELECT ''# Worked On Parametric'' As Item, (CASE WHEN ' + CONVERT(VARCHAR, @reportBasedOn) + '=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS num, p.productgroupname
		FROM Batches b WITH(NOLOCK)
			INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
			INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
			INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
			INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = ' + CONVERT(VARCHAR, @TrueBit) + '
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		WHERE ba.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + ''' 
			and (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY p.productgroupname
		UNION
		SELECT ''# Completed Parametric'' As Item, (CASE WHEN ' + CONVERT(VARCHAR, @reportBasedOn) + '=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS num, p.productgroupname
		FROM Batches b WITH(NOLOCK)
			INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
			INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
			INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
			INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = ' + CONVERT(VARCHAR, @TrueBit) + '
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		WHERE ba.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + ''' 
			AND (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY p.productgroupname
		UNION'
		SET @sql2 = ' SELECT ''# Worked On Drop'' As Item, (CASE WHEN ' + CONVERT(VARCHAR, @reportBasedOn) + '=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS num, p.productgroupname
		FROM Batches b WITH(NOLOCK)
			INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
			INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
			INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = ' + CONVERT(VARCHAR, @TrueBit) + ' AND j.JobName LIKE ''%Drop%''
			INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
			INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		WHERE ba.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			and (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY p.productgroupname
		UNION
		SELECT ''# Worked On Tumble'' As Item, (CASE WHEN ' + CONVERT(VARCHAR, @reportBasedOn) + '=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS num, p.productgroupname
		FROM Batches b WITH(NOLOCK)
			INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
			INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
			INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = ' + CONVERT(VARCHAR, @TrueBit) + ' AND j.JobName LIKE ''%Tumble%''
			INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
			INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		WHERE ba.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			and (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY p.productgroupname
		UNION
		SELECT ''# Completed Drop'' As Item, (CASE WHEN ' + CONVERT(VARCHAR, @reportBasedOn) + '=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS num, p.productgroupname
		FROM Batches b WITH(NOLOCK)
			INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
			INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
			INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = ' + CONVERT(VARCHAR, @TrueBit) + ' AND j.JobName LIKE ''%Drop%''
			INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
			INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		WHERE ba.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			and (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY p.productgroupname
		UNION
		SELECT ''# Completed Tumble'' As Item, (CASE WHEN ' + CONVERT(VARCHAR, @reportBasedOn) + '=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS num, p.productgroupname
		FROM Batches b WITH(NOLOCK)
			INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
			INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
			INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = ' + CONVERT(VARCHAR, @TrueBit) + ' AND j.JobName LIKE ''%Tumble%''
			INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
			INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		WHERE ba.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			and (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY p.productgroupname
		UNION
		SELECT ''# Worked On Accessories'' As Item, (CASE WHEN ' + CONVERT(VARCHAR, @reportBasedOn) + '=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS num, p.productgroupname
		FROM Batches b WITH(NOLOCK)
			INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
			INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
			INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
			INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
			INNER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID = l.LookupID 
		WHERE ba.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + ''' AND l.[Values] = ''Accessory''
			and (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY p.productgroupname
		UNION'
		SET @sql3 = ' SELECT ''# Worked On Component'' As Item, (CASE WHEN ' + CONVERT(VARCHAR, @reportBasedOn) + '=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS num, p.productgroupname
		FROM Batches b WITH(NOLOCK)
			INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
			INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
			INNER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID = l.LookupID 
		WHERE ba.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + ''' AND l.[Values] = ''Component''
			and (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY p.productgroupname
		UNION
		SELECT ''# Worked On Handheld'' As Item, (CASE WHEN ' + CONVERT(VARCHAR, @reportBasedOn) + '=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS num, p.productgroupname
		FROM Batches b WITH(NOLOCK)
			INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
			INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
			INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
			INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
			INNER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID = l.LookupID 
		WHERE ba.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + ''' AND l.[Values] = ''Handheld''
			and (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY p.productgroupname
	) p PIVOT (MAX(num) FOR ProductGroupName IN (' + @rows + ')) AS pvt GROUP BY Item, ' + @rows + ' ORDER BY Item '

	EXEC (@sql + @sql2 + @sql3)
END
ELSE
BEGIN
	IF @testLocationID = 0
	BEGIN
		SET @testLocationID = NULL
	END

	SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Completed Testing], p.ProductGroupName 
	FROM Batches b WITH(NOLOCK)
		INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus = 8 and ba.inserttime between @startdate and @enddate
		INNER JOIN BatchesAudit ba2 WITH(NOLOCK) ON b.ID = ba2.BatchID AND ba2.BatchStatus <> 8 and ba2.inserttime between @startdate and @enddate
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
	WHERE (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY p.productgroupname
	ORDER BY p.productgroupname

	SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# in Chamber], p.productgroupname 
	FROM DeviceTrackingLog dtl WITH(NOLOCK)
		INNER JOIN TestUnits tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
		INNER JOIN TrackingLocations tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.id
		INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tl.TrackingLocationTypeID = tlt.ID AND tlt.TrackingLocationFunction = 4 --4 means chamber type device (environmentstressing)
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
	WHERE dtl.InTime BETWEEN @startdate AND @enddate
		and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY p.productgroupname
	ORDER BY p.productgroupname

	SELECT count(tr.ID) as [# Units in FA], p.productgroupname 
	FROM (
			SELECT tra.TestRecordId 
			FROM TestRecordsaudit tra WITH(NOLOCK)
			WHERE tra.Action IN ('I','U') AND tra.Status IN (3, 4) and tra.InsertTime BETWEEN @startdate AND @enddate--FQRaised and FARequired
			GROUP BY TestRecordId
		) as xer
		INNER JOIN TestRecords tr WITH(NOLOCK) ON tr.ID= xer.TestRecordId
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
	WHERE (b.TestCenterLocationID = @testLocationID or @testLocationID is null)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID))) 
	GROUP BY ProductGroupName
	ORDER BY p.productgroupname

	SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Parametric], p.productgroupname
	FROM Batches b WITH(NOLOCK)
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
		INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
		INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = @TrueBit
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
	WHERE ba.inserttime between @startdate and @enddate and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY p.productgroupname
	ORDER BY p.productgroupname

	SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Completed Parametric], p.productgroupname
	FROM Batches b WITH(NOLOCK)
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
		INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
		INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = @TrueBit
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
	WHERE ba.inserttime between @startdate and @enddate and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY p.productgroupname
	ORDER BY p.productgroupname

	SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Drop], p.productgroupname
	FROM Batches b WITH(NOLOCK)
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
		INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
		INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit AND j.JobName LIKE '%Drop%'
		INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
	WHERE ba.inserttime between @startdate and @enddate
		and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY p.productgroupname
	ORDER BY p.productgroupname

	SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Tumble], p.productgroupname
	FROM Batches b WITH(NOLOCK)
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
		INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
		INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit AND j.JobName LIKE '%Tumble%'
		INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
	WHERE ba.inserttime between @startdate and @enddate
		and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY p.productgroupname
	ORDER BY p.productgroupname

	SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Completed Drop], p.productgroupname
	FROM Batches b WITH(NOLOCK)
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
		INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
		INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit AND j.JobName LIKE '%Drop%'
		INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
	WHERE ba.inserttime between @startdate and @enddate
		and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY p.productgroupname
	ORDER BY p.productgroupname
	
	SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Completed Tumble], p.productgroupname
	FROM Batches b WITH(NOLOCK)
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
		INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
		INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit AND j.JobName LIKE '%Tumble%'
		INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
	WHERE ba.inserttime between @startdate and @enddate
		and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY p.productgroupname
	ORDER BY p.productgroupname

	SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Accessories], p.productgroupname
	FROM Batches b WITH(NOLOCK)
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
		INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		INNER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID = l.LookupID 
	WHERE ba.inserttime between @startdate and @enddate AND l.[Values] = 'Accessory'
		and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY p.productgroupname
	ORDER BY p.productgroupname

	SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Component], p.productgroupname
	FROM Batches b WITH(NOLOCK)
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
		INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		INNER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID = l.LookupID 
	WHERE ba.inserttime between @startdate and @enddate AND l.[Values] = 'Component'
		and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY p.productgroupname
	ORDER BY p.productgroupname

	SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Handheld], p.productgroupname
	FROM Batches b WITH(NOLOCK)
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
		INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		INNER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID = l.LookupID 
	WHERE ba.inserttime between @startdate and @enddate	AND l.[Values] = 'Handheld'
		and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY p.productgroupname
	ORDER BY p.productgroupname
END

SET NOCOUNT OFF
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispUsersSelectSingleItemByUserName]'
GO
ALTER PROCEDURE [dbo].[remispUsersSelectSingleItemByUserName] @LDAPLogin nvarchar(255) = '', @UserID INT = 0
AS
	SELECT Users.BadgeNumber,Users.ConcurrencyID,Users.ID,Users.LastUser,Users.LDAPLogin, Users.TestCentreID, ISNULL(Users.IsActive, 1) AS IsActive, 
		Users.DefaultPage, Lookups.[Values] As TestCentre, Users.ByPassProduct, Users.DepartmentID, ld.[Values] AS Department
	FROM Users
		LEFT OUTER JOIN Lookups ON LookupID=TestCentreID
		LEFT OUTER JOIN Lookups ld ON ld.LookupID=DepartmentID
	WHERE (@UserID = 0 AND LDAPLogin = @LDAPLogin) OR (@UserID > 0 AND Users.ID=@UserID)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispUsersSelectList]'
GO
ALTER PROCEDURE [dbo].[remispUsersSelectList]
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@determineDelete INT = 1,
	@RecordCount int = NULL OUTPUT
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Users)
		RETURN
	END

	SELECT UsersRows.BadgeNumber,UsersRows.ConcurrencyID,UsersRows.ID,usersrows.TestCentre, UsersRows.LastUser,UsersRows.LDAPLogin,UsersRows.Row, UsersRows.IsActive, 
		CASE WHEN @determineDelete = 1 THEN dbo.remifnUserCanDelete(UsersRows.LDAPLogin) ELSE 0 END AS CanDelete, UsersRows.DefaultPage, UsersRows.TestCentreID,
		ByPassProduct, UsersRows.DepartmentID, UsersRows.Department
	FROM     
		(SELECT ROW_NUMBER() OVER (ORDER BY ID) AS Row, Users.BadgeNumber,Users.ConcurrencyID,Users.ID,Users.LastUser,Users.LDAPLogin, 
			Lookups.[Values] AS TestCentre, ISNULL(Users.IsActive,1) AS IsActive, Users.DefaultPage, Users.TestCentreID, Users.ByPassProduct,
			Users.DepartmentID, ld.[Values] AS Department
		FROM Users
			LEFT OUTER JOIN Lookups ON LookupID=TestCentreID
			LEFT OUTER JOIN Lookups ld ON ld.LookupID=DepartmentID
		) AS UsersRows
	WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1) 
	ORDER BY IsActive desc, LDAPLogin
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispUsersSelectListByTestCentre]'
GO
ALTER PROCEDURE [dbo].[remispUsersSelectListByTestCentre] @TestLocation INT, @IncludeInActive INT = 1, @determineDelete INT = 1, @RecordCount int = NULL OUTPUT
AS
	DECLARE @ConCurID timestamp

	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) 
							FROM Users 
							WHERE TestCentreID=TestCentreID
								AND 
								(
									(@IncludeInActive = 0 AND IsActive=1)
									OR
									@IncludeInActive = 1
								)
							)
		RETURN
	END

	SELECT Users.BadgeNumber, Users.ConcurrencyID, Users.ID, Users.LastUser, Users.LDAPLogin, 
		Lookups.[Values] AS TestCentre, ISNULL(Users.IsActive,1) AS IsActive, Users.DefaultPage, Users.TestCentreID, Users.ByPassProduct, 
		CASE WHEN @determineDelete = 1 THEN dbo.remifnUserCanDelete(Users.LDAPLogin) ELSE 0 END AS CanDelete,
		Users.DepartmentID, ld.[Values] AS Department
	FROM Users
		LEFT OUTER JOIN Lookups ON LookupID=TestCentreID
		LEFT OUTER JOIN Lookups ld ON ld.LookupID=DepartmentID
	WHERE (TestCentreID=@TestLocation OR @TestLocation = 0)
		AND 
		(
			(@IncludeInActive = 0 AND ISNULL(Users.IsActive, 1)=1)
			OR
			@IncludeInActive = 1
		)
	ORDER BY IsActive DESC, LDAPLogin
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispSaveLookup]'
GO
ALTER PROCEDURE [dbo].[remispSaveLookup] @LookupType NVARCHAR(150), @Value NVARCHAR(150), @IsActive INT = 1, @Description NVARCHAR(200) = NULL, @ParentID INT = NULL
AS
BEGIN
	DECLARE @LookupID INT
	DECLARE @LookupTypeID INT
	SELECT @LookupID = MAX(LookupID) + 1 FROM Lookups
	SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name=@LookupType

	IF (@ParentID = 0)
	BEGIN
		SET @ParentID = NULL
	END
	
	IF LTRIM(RTRIM(@Value)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups WHERE LookupTypeID=@LookupTypeID AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@Value)))
	BEGIN
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values], IsActive, Description, ParentID) 
		VALUES (@LookupID, @LookupTypeID, LTRIM(RTRIM(@Value)), @IsActive, @Description, @ParentID)
	END
	ELSE
	BEGIN
		UPDATE Lookups
		SET IsActive=@IsActive, Description=@Description, ParentID=@ParentID
		WHERE LookupTypeID=@LookupTypeID AND [values]=LTRIM(RTRIM(@Value))
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesInsertUpdateSingleItem]'
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
	@relabJobID int = null,
	@reportApprovedDate datetime = null,
	@reportRequiredBy datetime = null,
	@rqID int = null,
	@partName nvarchar(500) = null,
	@assemblyNumber nvarchar(500) = null,
	@assemblyRevision nvarchar(500) = null,
	@trsStatus nvarchar(500) = null,
	@cprNumber nvarchar(500) = null,
	@hwRevision nvarchar(500) = null,
	@pmNotes nvarchar(500) = null,
	@IsMQual bit = 0,
	@MechanicalTools NVARCHAR(10),
	@RequestPurposeID int = 0,
	@PriorityID INT = 0,
	@DepartmentID INT = 0,
	@Department NVARCHAR(150) = NULL
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
	
	IF @RequestPurposeID = 0
	BEGIN
		SELECT @RequestPurposeID = LookupID FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='RequestPurpose' AND [Values] = @RequestPurpose
	END

	IF @PriorityID = 0
	BEGIN
		SELECT @PriorityID = LookupID FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='Priority' AND [Values] = @Priority
	END

	IF LTRIM(RTRIM(@Department)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='Department' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@Department)))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Department'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@Department)))
	END

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
		relabJobID,
		reportApprovedDate,
		reportRequiredBy,
		rqID,
		partName,
		assemblyNumber,
		assemblyRevision,
		trsStatus,
		cprNumber,
		hwRevision,
		pmNotes,
		ProductID, IsMQual, MechanicalTools, DepartmentID ) 
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
		@relabJobID,
		@reportApprovedDate,
		@reportRequiredBy,
		@rqID,
		@partName,
		@assemblyNumber,
		@assemblyRevision,
		@trsStatus,
		@cprNumber,
		@hwRevision,
		@pmNotes,
		@ProductID, @IsMQual, @MechanicalTools, @DepartmentID)

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
		relabJobID=@relabJobID,
		reportApprovedDate=@reportApprovedDate,
		reportRequiredBy=@reportRequiredBy,
		rqID=@rqID,
		partName=@partName,
		assemblyNumber=@assemblyNumber,
		assemblyRevision=@assemblyRevision,
		trsStatus=@trsStatus,
		cprNumber=@cprNumber,
		hwRevision=@hwRevision,
		pmNotes=@pmNotes ,
		ProductID=@ProductID,
		IsMQual = @IsMQual,
		MechanicalTools = @MechanicalTools, DepartmentID = @DepartmentID
		WHERE (ID = @ID) AND (ConcurrencyID = @ConcurrencyID)

		SELECT @ReturnValue = @ID
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSearch]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSearch]
	@ByPassProductCheck INT = 0,
	@ExecutingUserID int,
	@Status int = null,
	@Priority int = null,
	@UserID int = null,
	@TrackingLocationID int = null,
	@TestStageID int = null,
	@TestID int = null,
	@ProductTypeID int = null,
	@ProductID int = null,
	@AccessoryGroupID int = null,
	@GeoLocationID INT = null,
	@JobName nvarchar(400) = null,
	@RequestReason int = null,
	@StartRowIndex int = null,
	@MaximumRows int = null,
	@BatchStart DateTime = NULL,
	@BatchEnd DateTime = NULL,
	@TestStage NVARCHAR(400) = NULL,
	@TestStageType INT = NULL,
	@excludedTestStageType INT = NULL,
	@ExcludedStatus INT = NULL,
    @TrackingLocationFunction INT = NULL,
	@NotInTrackingLocationFunction INT  = NULL,
	@Revision NVARCHAR(10) = NULL,
	@DepartmentID INT = NULL
AS
	DECLARE @TestName NVARCHAR(400)
	DECLARE @TestStageName NVARCHAR(400)
	DECLARE @HasBatchSpecificExceptions BIT
	SET @HasBatchSpecificExceptions = CONVERT(BIT, 0)
	
	SELECT @TestName = TestName FROM Tests WITH(NOLOCK) WHERE ID=@TestID 
	SELECT @TestStageName = TestStageName FROM TestStages WITH(NOLOCK) WHERE ID=@TestStageID
	CREATE TABLE #ExTestStageType (ID INT)
	CREATE TABLE #ExBatchStatus (ID INT)
	
	IF (@TestStageName IS NOT NULL)
		SET @TestStage = NULL
	
	IF convert(VARCHAR,(@excludedTestStageType & 1) / 1) = 1
	BEGIN
		INSERT INTO #ExTestStageType VALUES (1)
	END
	IF convert(VARCHAR,(@excludedTestStageType & 2) / 2) = 1
	BEGIN
		INSERT INTO #ExTestStageType VALUES (2)
	END
	IF convert(VARCHAR,(@excludedTestStageType & 4) / 4) = 1
	BEGIN
		INSERT INTO #ExTestStageType VALUES (3)
	END
	IF convert(VARCHAR,(@excludedTestStageType & 8) / 8) = 1
	BEGIN
		INSERT INTO #ExTestStageType VALUES (4)
	END
	IF convert(VARCHAR,(@excludedTestStageType & 16) / 16) = 1
	BEGIN
		INSERT INTO #ExTestStageType VALUES (5)
	END
		
	IF convert(VARCHAR,(@ExcludedStatus & 1) / 1) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (1)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 2) / 2) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (2)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 4) / 4) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (3)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 8) / 8) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (4)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 16) / 16) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (5)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 32) / 32) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (6)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 64) / 64) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (7)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 128) / 128) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (8)
	END
		
	SELECT TOP 100 BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroup As ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName,batchesrows.ProductID, 
		BatchesRows.QRANumber,BatchesRows.RequestPurposeID, BatchesRows.TestCenterLocationID,BatchesRows.TestStageName, BatchesRows.TestStageCompletionStatus, testUnitCount, 
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation, batchesrows.RQID AS ReqID,
		(testunitcount -
			(select COUNT(*) 
			from TestUnits as tu WITH(NOLOCK)
			INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
		) as HasUnitsToReturnToRequestor,
		ISNULL(
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
			WHERE ta.BatchID = BatchesRows.ID and ta.Active=1), 
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
			WHERE ta.Active=1 AND ISNULL(ta.taskID,0) = 0 AND ta.BatchID = BatchesRows.ID)
		) as ActiveTaskAssignee,
		@HasBatchSpecificExceptions AS HasBatchSpecificExceptions, batchesrows.ProductTypeID,batchesrows.AccessoryGroupID, BatchesRows.CPRNumber, BatchesRows.RelabJobID, 
		BatchesRows.TestCenterLocation, AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate, IsMQual, JobID, DateCreated, ContinueOnFailures,
		MechanicalTools, BatchesRows.RequestPurpose, BatchesRows.PriorityID, DepartmentID, Department
	FROM     
		(
			SELECT DISTINCT b.BatchStatus,b.Comment, b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority AS PriorityID,b.ProductTypeID,
				b.AccessoryGroupID,p.ID As ProductID,p.ProductGroupName As ProductGroup,b.QRANumber,b.RequestPurpose As RequestPurposeID,b.TestCenterLocationID,b.TestStageName,
				j.WILocation,(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, l3.[Values] As TestCenterLocation,
				b.CPRNumber,b.RelabJobID, b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, 
				b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, b.DateCreated, j.ContinueOnFailures, MechanicalTools, l4.[Values] As RequestPurpose, l5.[Values] As Priority, 
				ISNULL(b.[Order], 100) As PriorityOrder, b.DepartmentID, l6.[Values] AS Department
			FROM Batches as b WITH(NOLOCK)
				inner join Products p WITH(NOLOCK) on b.ProductID=p.id 
				LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON b.TestCenterLocationID=l3.LookupID
				INNER JOIN TestStages ts WITH(NOLOCK) ON ts.TestStageName=b.TestStageName
				LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON b.RequestPurpose=l4.LookupID
				LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON b.Priority=l5.LookupID
				LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON b.DepartmentID=l6.LookupID
			WHERE ((BatchStatus NOT IN (SELECT ID FROM #ExBatchStatus) OR @ExcludedStatus IS NULL) AND (BatchStatus = @Status OR @Status IS NULL))
				AND (p.ID = @ProductID OR @ProductID IS NULL)
				AND (b.Priority = @Priority OR @Priority IS NULL)
				AND (b.ProductTypeID = @ProductTypeID OR @ProductTypeID IS NULL)
				AND (b.AccessoryGroupID = @AccessoryGroupID OR @AccessoryGroupID IS NULL)
				AND (b.TestCenterLocationID = @GeoLocationID OR @GeoLocationID IS NULL)
				AND (b.DepartmentID = @DepartmentID OR @DepartmentID IS NULL)
				AND (b.JobName = @JobName OR @JobName IS NULL)
				AND (b.RequestPurpose = @RequestReason OR @RequestReason IS NULL)
				AND (b.MechanicalTools = @Revision OR @Revision IS NULL)
				AND 
				(
					(@TestStage IS NULL AND (b.TestStageName = @TestStageName OR @TestStageName IS NULL))
					OR
					(b.TestStageName = @TestStage AND @TestStageName IS NULL)
				)
				AND ((ts.TestStageType NOT IN (SELECT ID FROM #ExTestStageType) OR @excludedTestStageType IS NULL) AND (ts.TestStageType = @TestStageType OR @TestStageType IS NULL))
				AND
				(
					(
						SELECT top(1) tu.CurrentTestName as CurrentTestName 
						FROM TestUnits AS tu WITH(NOLOCK), DeviceTrackingLog AS dtl WITH(NOLOCK)
						where tu.ID = dtl.TestUnitID 
						and tu.CurrentTestName is not null
						and (dtl.OutUser IS NULL) AND tu.BatchID=b.ID
					) = @TestName 
					OR 
					@TestName IS NULL
				)
				AND
				(
					(
						SELECT top 1 u.id 
						FROM TestUnits as tu WITH(NOLOCK), devicetrackinglog as dtl WITH(NOLOCK), TrackingLocations as tl WITH(NOLOCK), Users u WITH(NOLOCK)
						WHERE tl.ID = dtl.TrackingLocationID and tu.id  = dtl.testunitid and tu.batchid = b.id and  inuser = u.LDAPLogin and outuser is null
					) = @UserID
					OR
					@UserID IS NULL
				)
				AND
				(
					@TrackingLocationID IS NULL
					OR
					(
						b.ID IN (SELECT DISTINCT tu.BatchID
						FROM TrackingLocations tl WITH(NOLOCK)
							INNER JOIN devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID --AND dtl.OutTime IS NULL
								AND dtl.InTime BETWEEN @BatchStart AND @BatchEnd
						INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=dtl.TestUnitID
						WHERE TrackingLocationTypeID=@TrackingLocationID)
					)
				)
				AND
				(
					@TrackingLocationFunction IS NULL
					OR
					(
						b.ID IN (select DISTINCT tu.BatchID
						from TrackingLocations tl WITH(NOLOCK)
						inner join devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID AND dtl.OutTime IS NULL
						inner join TestUnits tu WITH(NOLOCK) on tu.ID=dtl.TestUnitID
						INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tlt.ID = tl.TrackingLocationTypeID
						where tlt.TrackingLocationFunction=@TrackingLocationFunction)
					)
				)
				AND
				(
					@NotInTrackingLocationFunction IS NULL
					OR
					(
						b.ID IN (select DISTINCT tu.BatchID
						from TrackingLocations tl WITH(NOLOCK)
						inner join devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID AND dtl.OutTime IS NULL
						inner join TestUnits tu WITH(NOLOCK) on tu.ID=dtl.TestUnitID
						INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tlt.ID = tl.TrackingLocationTypeID
						where tlt.TrackingLocationFunction NOT IN (@NotInTrackingLocationFunction))
					)
				)
				AND 
				(
					(@BatchStart IS NULL AND @BatchEnd IS NULL)
					OR
					(@BatchStart IS NOT NULL AND @BatchEnd IS NOT NULL AND b.ID IN (Select distinct batchid FROM BatchesAudit WITH(NOLOCK) WHERE InsertTime BETWEEN @BatchStart AND @BatchEnd))
				)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@ExecutingUserID)))
		)AS BatchesRows		
	ORDER BY BatchesRows.PriorityOrder ASC, BatchesRows.QRANumber DESC
	
	DROP TABLE #ExTestStageType
	DROP TABLE #ExBatchStatus
	RETURN
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispGetJobOrientations]'
GO
ALTER PROCEDURE [dbo].[remispGetJobOrientations] @JobID INT = 0, @JobName NVARCHAR(400) = NULL
AS
BEGIN
	SELECT jo.ID, jo.Name, jo.ProductTypeID, l.[Values] AS ProductType, jo.NumUnits, jo.NumDrops,
		jo.Description, jo.CreatedDate, jo.IsActive, jo.Definition
	FROM JobOrientation jo
		INNER JOIN Lookups l ON l.LookupID=jo.ProductTypeID
		INNER JOIN Jobs j ON j.ID=jo.JobID
	WHERE ( 
			(jo.JobID=@JobID AND @JobID > 0)
			OR
			(j.JobName = @JobName AND @JobName IS NOT NULL)
		  )
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispGetOrientation]'
GO
ALTER PROCEDURE [dbo].[remispGetOrientation] @ID INT
AS
BEGIN
	SELECT jo.ID, jo.Name, jo.ProductTypeID, l.[Values] AS ProductType, jo.NumUnits, jo.NumDrops,
		jo.Description, jo.CreatedDate, jo.IsActive, jo.Definition, jo.JobID
	FROM JobOrientation jo
		INNER JOIN Lookups l ON l.LookupID=jo.ProductTypeID 
	WHERE jo.ID = @ID
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispStationConfigurationUpload]'
GO
ALTER PROCEDURE [dbo].remispStationConfigurationUpload AS
BEGIN
	CREATE TABLE #temp2 (ID INT, ParentID INT, NodeType INT, LocalName NVARCHAR(100), Text NVARCHAR(100), ID_temp INT IDENTITY(1,1), ID_NEW INT, ParentID_NEW INT)
	CREATE TABLE #temp3 (LookupID INT, Type NVARCHAR(150), LocalName NVARCHAR(150), ID INT IDENTITY(1,1))
	DECLARE @TrackingLocationHostID INT
	DECLARE @MaxID INT
	DECLARE @MaxLookupID INT
	DECLARE @idoc INT
	DECLARE @PluginID INT
	DECLARE @LookupTypeID INT
	DECLARE @ID INT
	DECLARE @xml XML
	DECLARE @LastUser NVARCHAR(255)

	IF ((SELECT COUNT(*) FROM StationConfigurationUpload WHERE ISNULL(IsProcessed,0)=0)=0)
		RETURN

	SELECT @LookupTypeID=LookupTypeID FROM LookupType WHERE Name='Configuration'

	WHILE ((SELECT COUNT(*) FROM StationConfigurationUpload WHERE ISNULL(IsProcessed,0)=0)>0)
	BEGIN
		SELECT TOP 1 @ID=ID, @xml =StationConfigXML, @TrackingLocationHostID=TrackingLocationHostID, @LastUser=LastUser, @PluginID = TrackingLocationPluginID
		FROM StationConfigurationUpload 
		WHERE ISNULL(IsProcessed,0)=0
				
		IF (@PluginID = 0)
			SET @PluginID = NULL

		exec sp_xml_preparedocument @idoc OUTPUT, @xml
	
		SELECT @MaxID = ISNULL(MAX(ID),0)+1 FROM TrackingLocationsHostsConfiguration
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
		WHERE NodeType=1 AND (SELECT COUNT(ISNULL(ParentID,0)) FROM #temp t WHERE t.ParentID=#temp.ID AND t.ParentID IS NOT NULL AND t.NodeType <> 3)=1
	
		UPDATE #temp2
		SET ID_NEW = ID_temp + @MaxID

		UPDATE #temp2
		SET ParentID_NEW = (SELECT t.ID_NEW FROM #temp2 t WHERE #temp2.ParentID=t.ID)
		WHERE #temp2.ParentID IS NOT NULL

		SET IDENTITY_INSERT TrackingLocationsHostsConfiguration ON

		INSERT INTO TrackingLocationsHostsConfiguration (ID, ParentId, ViewOrder, NodeName, LastUser, TrackingLocationHostID, TrackingLocationProfileID)
		SELECT ID_NEW, CASE WHEN ParentID_NEW = 0 THEN NULL ELSE ParentID_NEW END, ROW_NUMBER() OVER (ORDER BY id) AS ViewOrder, LocalName, @LastUser, @TrackingLocationHostID, @PluginID
		FROM #temp2
		ORDER BY ID, parentid

		SET IDENTITY_INSERT TrackingLocationsHostsConfiguration OFF
	
		INSERT INTO #temp3
		SELECT DISTINCT 0 AS LookupID, @LookupTypeID AS LookupTypeID, LTRIM(RTRIM(LocalName)) AS LocalName
		FROM #temp 
		WHERE NodeType=2 AND LocalName NOT IN (SELECT Lookups.[Values] FROM Lookups WHERE LookupTypeID=@LookupTypeID)

		INSERT INTO #temp3
		SELECT DISTINCT 0 AS LookupID, @LookupTypeID AS LookupTypeID, LTRIM(RTRIM(LocalName)) AS LocalName
		FROM #temp 
		WHERE NodeType=1 AND LocalName NOT IN (SELECT Lookups.[Values] FROM Lookups WHERE LookupTypeID=@LookupTypeID)
			AND ID IN (SELECT ParentID FROM #temp WHERE NodeType=3)

		UPDATE #temp3 SET LookupID=ID+@MaxLookupID

		insert into Lookups (LookupID, Type, [Values])
		select LookupID, Type, localname as [Values] from #temp3
	
		INSERT INTO TrackingLocationsHostsConfigValues (Value, LookupID, TrackingConfigID, LastUser, IsAttribute)
		SELECT ISNULL((SELECT t2.Text FROM #temp t2 WHERE t2.NodeType=3 AND t2.ParentID=#temp.ID), '') AS Value, 
			CASE WHEN #temp.NodeType=2 THEN (SELECT LookupID FROM Lookups WHERE LookupTypeID=@LookupTypeID AND [values]=#temp.LocalName) ELSE NULL END As LookupID, 
			(SELECT ID_NEW FROM #temp2 WHERE #temp.ParentID=#temp2.ID) AS TrackingConfigID, @LastUser As LastUser, 1 AS IsAttribute
		FROM #temp
		WHERE #temp.NodeType=2

		INSERT INTO TrackingLocationsHostsConfigValues (Value, LookupID, TrackingConfigID, LastUser, IsAttribute)
		SELECT ISNULL(#temp.Text,'') AS Value, (SELECT Lookups.LookupID FROM #temp t INNER JOIN Lookups ON LookupTypeID=@LookupTypeID AND LOWER(LTRIM(RTRIM([Values])))=LOWER(LTRIM(RTRIM(t.LocalName))) WHERE t.NodeType=1 AND t.id=#temp.parentid) AS LookupID,
			(SELECT #temp2.ID_NEW 
			FROM #temp2 	
				INNER JOIN #temp t1 ON t1.NodeType=1 AND #temp2.ID=t1.parentid
			WHERE #temp.ParentID=t1.ID) AS TrackingConfigID, 
			@LastUser As LastUser, 0 AS IsAttribute
		FROM #temp
		WHERE NodeType=3 AND ParentID NOT IN (Select ID FROM #temp WHERE #temp.NodeType=2)

		INSERT INTO TrackingLocationsHostsConfigValues (Value, LookupID, TrackingConfigID, LastUser, IsAttribute)
		SELECT ISNULL(#temp.Text,'') AS Value, (SELECT Lookups.LookupID FROM #temp t INNER JOIN Lookups ON LookupTypeID=@LookupTypeID AND LOWER(LTRIM(RTRIM([Values])))=LOWER(LTRIM(RTRIM(t.LocalName))) WHERE t.NodeType=1 AND t.id=#temp.id) AS LookupID,
			(SELECT #temp2.ID_NEW 
			FROM #temp2 	
				INNER JOIN #temp t1 ON t1.NodeType=1 AND #temp2.ID=t1.parentid
			WHERE #temp.ID=t1.ID) AS TrackingConfigID, 
			@LastUser As LastUser, 0 AS IsAttribute
		FROM #temp
		WHERE NodeType=1 AND ID NOT IN (Select ParentID FROM #temp t WHERE t.NodeType =3)
			AND ID NOT IN (Select ID FROM #temp2)	

		DELETE FROM #temp2
		DELETE FROM #temp3
		DROP TABLE #temp
		
		UPDATE StationConfigurationUpload SET IsProcessed=1 WHERE ID=@ID
	END

	DROP TABLE #temp2
	DROP TABLE #temp3
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesGetActiveBatches]'
GO
ALTER PROCEDURE [dbo].[remispBatchesGetActiveBatches]
/*	'===============================================================
	'   NAME:                	remispBatchesGetActiveBatches
	'   DATE CREATED:       	10 Jun 2010
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves active batches from table: Batches 
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION:	remove hardcode string comparison and moved to ID
	'===============================================================*/
	@StartRowIndex int = null,
	@MaximumRows int = null,
	@RecordCount int = null OUTPUT
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Batches WITH(NOLOCK) WHERE BatchStatus NOT IN(5,7))	
		RETURN
	END
	
	SELECT BatchesRows.row,BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,BatchesRows.RequestPurpose,batchesrows.ProductType, batchesrows.AccessoryGroupName,
		batchesrows.ProductID,BatchesRows.TestCenterLocationID,
		BatchesRows.TestCenterLocation,BatchesRows.TestStageName, BatchesRows.TestStageCompletionStatus, 
		batchesrows.testUnitCount,BatchesRows.RQID As ReqID,
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,
		(
			testunitcount -
			(select COUNT(*) 
			from TestUnits as tu WITH(NOLOCK)
				INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
		) as HasUnitsToReturnToRequestor,
		ISNULL(
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
			WHERE ta.BatchID = BatchesRows.ID and ta.Active=1), 
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
			WHERE ta.Active=1 AND ISNULL(ta.taskID,0) = 0 AND ta.BatchID = BatchesRows.ID)
		) as ActiveTaskAssignee,
		CONVERT(BIT, 0) AS HasBatchSpecificExceptions, batchesrows.ProductTypeID, batchesrows.AccessoryGroupID, AssemblyNumber, AssemblyRevision, HWRevision, PartName, 
		ReportRequiredBy, ReportApprovedDate, IsMQual, JobID, ExecutiveSummary, MechanicalTools, BatchesRows.RequestPurposeID, BatchesRows.PriorityID, DepartmentID, Department
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
			b.BatchStatus,b.Comment, b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority As PriorityID,p.ProductGroupName,b.ProductTypeID,b.AccessoryGroupID,p.ID as ProductID,
			b.QRANumber, b.RequestPurpose As RequestPurposeID,b.TestCenterLocationID,b.TestStageName, j.WILocation,
			(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
			l2.[Values] As AccessoryGroupName, l.[Values] As ProductType,b.RQID,l3.[Values] As TestCenterLocation,
			b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, ExecutiveSummary, 
			MechanicalTools, l4.[Values] As RequestPurpose, l5.[Values] As Priority, b.DepartmentID, l6.[Values] AS Department
			FROM Batches as b WITH(NOLOCK)
				inner join Products p WITH(NOLOCK) on p.ID=b.ProductID
				LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID=l.LookupID 
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON b.AccessoryGroupID=l2.LookupID 
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON b.TestCenterLocationID=l3.LookupID
				LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON b.RequestPurpose=l4.LookupID
				LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON b.Priority=l5.LookupID
				LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON b.DepartmentID=l6.LookupID
			WHERE BatchStatus NOT IN(5,7)
		) AS BatchesRows
	WHERE (Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex is null OR @maximumRows is null
	ORDER BY BatchesRows.QRANumber
	RETURN
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectByQRANumber]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectByQRANumber]
	@QRANumber nvarchar(11) = null,
	@RecordCount int = null OUTPUT
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Batches WITH(NOLOCK) WHERE QRANumber = @QRANumber)
		RETURN
	END

	declare @batchid int
	DECLARE @TestStageID INT
	DECLARE @JobID INT
	declare @jobname nvarchar(400)
	declare @teststagename nvarchar(400)
	select @batchid = id, @teststagename=TestStageName, @jobname = JobName from Batches WITH(NOLOCK) where QRANumber = @QRANumber
	declare @testunitcount int = (select count(*) from testunits as tu WITH(NOLOCK) where tu.batchid = @batchid)
	SELECT @JobID = ID FROM Jobs WHERE JobName=@jobname
	SELECT @TestStageID = ID FROM TestStages ts WHERE JobID=@JobID AND TestStageName = @teststagename

	DECLARE @TSTimeLeft REAL
	DECLARE @JobTimeLeft REAL
	EXEC remispGetEstimatedTSTime @batchid,@teststagename,@jobname, @TSTimeLeft OUTPUT, @JobTimeLeft OUTPUT, @TestStageID, @JobID
	
	SELECT BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
	BatchesRows.LastUser,BatchesRows.Priority AS PriorityID,p.ProductGroupName,BatchesRows.QRANumber,BatchesRows.RequestPurpose As RequestPurposeID,batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,
	batchesrows.ProductID,BatchesRows.TestCenterLocationID,
	l3.[Values] AS TestCenterLocation,BatchesRows.TestStageName,
	BatchesRows.TestStageCompletionStatus, @testunitcount as testUnitCount,
	(CASE WHEN j.WILocation IS NULL THEN NULL ELSE j.WILocation END) AS jobWILocation,@TSTimeLeft AS EstTSCompletionTime,@JobTimeLeft AS EstJobCompletionTime, 
	(@testunitcount -
			  -- TrackingLocations was only used because we were testing based on string comparison and this isn't needed anymore because we are basing on ID which DeviceTrackingLog can be used.
              (select COUNT(*) 
			  from TestUnits as tu WITH(NOLOCK)
			  INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			  where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
	) as HasUnitsToReturnToRequestor,
	ISNULL(
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName AND ts.JobID = j.ID
			WHERE ta.BatchID = BatchesRows.ID and ta.Active=1), 
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
			WHERE ta.Active=1 AND ISNULL(ta.taskID,0) = 0 AND ta.BatchID = BatchesRows.ID)
		) as ActiveTaskAssignee,
	BatchesRows.CPRNumber, l.[Values] AS ProductType, l2.[Values] As AccessoryGroupName,
	(
		SELECT TOP 1 CONVERT(BIT, 1) FROM TestExceptions WITH(NOLOCK) WHERE LookupID=3 AND Value IN (SELECT ID FROM TestUnits WITH(NOLOCK) WHERE BatchID=BatchesRows.ID)
    ) AS HasBatchSpecificExceptions,BatchesRows.RQID As ReqID, AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate,
	IsMQual, j.ID AS JobID, ExecutiveSummary, MechanicalTools, l4.[Values] AS RequestPurpose, l5.[Values] AS Priority, BatchesRows.OrientationID,
	BatchesRows.DepartmentID, l6.[Values] AS Department
	from Batches as BatchesRows WITH(NOLOCK)
		LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = BatchesRows.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
		INNER JOIN Products p WITH(NOLOCK) ON BatchesRows.productID=p.ID
		LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON BatchesRows.ProductTypeID=l.LookupID  
		LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON BatchesRows.AccessoryGroupID=l2.LookupID  
		LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON BatchesRows.TestCenterLocationID=l3.LookupID  
		LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON BatchesRows.RequestPurpose=l4.LookupID  
		LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON BatchesRows.Priority=l5.LookupID
		LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON BatchesRows.DepartmentID=l6.LookupID
	WHERE QRANumber = @QRANumber

select bc.DateAdded, bc.ID, bc.[Text], bc.LastUser from BatchComments as bc WITH(NOLOCK) where BatchID = @batchid and Active = 1 order by DateAdded desc;
	RETURN
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispGetUserTraining]'
GO
ALTER PROCEDURE [dbo].[remispGetUserTraining] @UserID INT, @ShowTrainedOnly INT
AS
BEGIN
	DECLARE @LookupTypeID INT
	SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Training'

	SELECT UserTraining.ID, UserID, DateAdded, Lookups.LookupID, Lookups.[Values] AS TrainingOption, 
		CASE WHEN ID IS NOT NULL THEN CONVERT(BIT,1) ELSE CONVERT(BIT, 0) END AS IsTrained,
		ll.[Values] As Level, ISNULL(UserTraining.LevelLookupID,0) AS LevelLookupID,
		ConfirmDate, CASE WHEN ConfirmDate IS NOT NULL THEN 1 ELSE 0 END AS IsConfirmed, ll.[Values] As Level,
		UserAssigned As UserAssigned
	FROM Lookups
		LEFT OUTER JOIN UserTraining ON UserTraining.LookupID=Lookups.LookupID AND UserTraining.UserID=@UserID
		LEFT OUTER JOIN Lookups ll ON ll.LookupID=UserTraining.LevelLookupID 
	WHERE Lookups.LookupTypeID=@LookupTypeID
		AND 
		(
			(@ShowTrainedOnly = 1 AND CASE WHEN ID IS NOT NULL THEN CONVERT(BIT,1) ELSE CONVERT(BIT, 0) END = CONVERT(BIT,1))
			OR
			(@ShowTrainedOnly = 0)
		)
	ORDER BY Lookups.[Values]
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispMeasurementsByReq_Test]'
GO
ALTER PROCEDURE [Relab].[remispMeasurementsByReq_Test] @RequestNumber NVARCHAR(11), @TestIDs NVARCHAR(MAX), @TestStageName NVARCHAR(400) = NULL, @UnitNumber INT = 0
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @tests TABLE(ID INT)
	INSERT INTO @tests SELECT s FROM dbo.Split(',',@TestIDs)
	DECLARE @FalseBit BIT
	DECLARE @TrueBit BIT
	CREATE TABLE #parameters (ResultMeasurementID INT)
	SET @FalseBit = CONVERT(BIT, 0)
	SET @TrueBit = CONVERT(BIT, 1)
	
	IF (@UnitNumber IS NULL)
		SET @UnitNumber = 0

	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + rp.ParameterName
		FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
			INNER JOIN Relab.Results r ON r.ID=rm.ResultID
			INNER JOIN TestUnits tu ON tu.ID = r.TestUnitID
			INNER JOIN Batches b ON b.ID=tu.BatchID
			INNER JOIN Tests t ON t.ID=r.TestID
			INNER JOIN @tests tst ON t.ID=tst.ID
			LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rm.ID=rp.ResultMeasurementID
		WHERE b.QRANumber=@RequestNumber AND rm.Archived=@FalseBit AND rp.ParameterName <> 'Command'
		ORDER BY '],[' +  rp.ParameterName
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

	SET @sql = 'ALTER TABLE #parameters ADD ' + convert(varchar(8000), replace(@rows, ']', '] NVARCHAR(250)'))
	EXEC (@sql)

	IF (@rows != '[na]')
	BEGIN
		EXEC ('INSERT INTO #parameters SELECT *
		FROM (
			SELECT rp.ResultMeasurementID, rp.ParameterName, rp.Value
			FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
				INNER JOIN Relab.Results r ON r.ID=rm.ResultID
				INNER JOIN TestUnits tu ON tu.ID = r.TestUnitID
				INNER JOIN Batches b ON b.ID=tu.BatchID
				INNER JOIN Tests t ON t.ID=r.TestID
				INNER JOIN @tests tst ON t.ID=tst.ID
				LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rm.ID=rp.ResultMeasurementID
			WHERE b.QRANumber=''' + @RequestNumber + ''' AND rm.Archived=' + @FalseBit + ' AND rp.ParameterName <> ''Command'' 
			) te PIVOT (MAX(Value) FOR ParameterName IN (' + @rows + ')) AS pvt')
	END
	ELSE
	BEGIN
		EXEC ('ALTER TABLE #parameters DROP COLUMN na')
	END

	SELECT t.TestName, ts.TestStageName, tu.BatchUnitNumber, ISNULL(ISNULL(ISNULL(lt.[Values], ltsf.[Values]), ltmf.[Values]), ltacc.[Values]) As Measurement, 
		LowerLimit AS [Lower Limit], UpperLimit AS [Upper Limit], MeasurementValue AS Result, lu.[Values] As Unit, 
		CASE WHEN rm.PassFail=1 THEN 'Pass' ELSE 'Fail' END AS [Pass/Fail], rm.ReTestNum AS [Test Num],
		ISNULL(rmf.[File], 0) AS [Image], ISNULL(UPPER(SUBSTRING(rmf.ContentType,2,LEN(rmf.ContentType))), 'PNG') AS ContentType, 
		rm.ID As measurementID, rm.Comment, p.*
	FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
		INNER JOIN Relab.Results r ON r.ID=rm.ResultID
		INNER JOIN TestUnits tu ON tu.ID = r.TestUnitID
		INNER JOIN Batches b ON b.ID=tu.BatchID
		INNER JOIN Tests t ON t.ID=r.TestID
		INNER JOIN @tests tst ON t.ID=tst.ID
		INNER JOIN TestStages ts ON ts.ID=r.TestStageID
		LEFT OUTER JOIN Lookups lu WITH(NOLOCK) ON lu.LookupID=rm.MeasurementUnitTypeID
		LEFT OUTER JOIN Lookups lt WITH(NOLOCK) ON lt.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltsf WITH(NOLOCK) ON ltsf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltmf WITH(NOLOCK) ON ltmf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltacc WITH(NOLOCK) ON ltacc.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Relab.ResultsMeasurementsFiles rmf WITH(NOLOCK) ON rmf.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN #parameters p WITH(NOLOCK) ON p.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN Relab.ResultsXML x ON x.ID = rm.XMLID
	WHERE b.QRANumber=@RequestNumber AND rm.Archived=@FalseBit
		AND (ISNULL(ISNULL(ISNULL(lt.[Values], ltsf.[Values]), ltmf.[Values]), ltacc.[Values]) NOT IN ('start', 'Start utc', 'end'))
		AND
		(
			(@TestStageName IS NULL)
			OR
			(@TestStageName IS NOT NULL AND ts.TestStageName = @TestStageName)
		)
		AND
		(
			(@UnitNumber = 0)
			OR
			(@UnitNumber > 0 AND tu.BatchUnitNumber = @UnitNumber)
		)
	ORDER BY tu.BatchUnitNumber, ts.ProcessOrder, rm.ReTestNum

	DROP TABLE #parameters
	SET NOCOUNT OFF
END
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
	DECLARE @StartDate DATETIME
	DECLARE @EndDate NVARCHAR(MAX)
	DECLARE @Duration NVARCHAR(MAX)
	DECLARE @LookupTypeName NVARCHAR(100)
	DECLARE @LookupTypeNameID INT
	DECLARE @TrackingLocationTypeName NVARCHAR(200)
	DECLARE @TestStageName NVARCHAR(400)
	DECLARE @StationName NVARCHAR(400)
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
					
			select @EndDate = T.c.query('DateCompleted').value('.', 'nvarchar(max)'),
				@Duration = T.c.query('Duration').value('.', 'nvarchar(max)'),
				@StationName = T.c.query('StationName').value('.', 'nvarchar(400)'),
				@FunctionalType = T.c.query('FunctionalType').value('.', 'nvarchar(400)')
			FROM @xmlPart.nodes('/Header') T(c)

			SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ' ')
			SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ':')
			SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ':')
					
			If (CHARINDEX('.', @Duration) > 0)
				SET @Duration = SUBSTRING(@Duration, 1, CHARINDEX('.', @Duration)-1)
			
			SET @StartDate=dateadd(s,-datediff(s,0,convert(DATETIME,@Duration)), CONVERT(DATETIME, @EndDate))

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
			
			WHILE (@InfoRowID IS NOT NULL)
			BEGIN
				SELECT @xmlPart  = value FROM #temp3 WHERE RowID=@InfoRowID	
				
				SELECT T.c.query('Name').value('.', 'nvarchar(max)') AS Name, T.c.query('Value').value('.', 'nvarchar(max)') AS Value
				INTO #information
				FROM @xmlPart.nodes('/Info') T(c)
				
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
				'start','start utc','end','end utc', 'os','osversion','os version', 'cameraid','hwserialnumber','hardware id',
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
					T.c.query('Comments').value('.', 'nvarchar(400)') AS [Comment],
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
						INNER JOIN #files f ON f.[FileName] = LOWER(LTRIM(RTRIM(Relab.ResultsMeasurementsFiles.FileName)))
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
							INNER JOIN #files f ON f.[FileName] = LOWER(LTRIM(RTRIM(Relab.ResultsMeasurementsFiles.FileName)))
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
			
			PRINT 'Update Result'
			UPDATE Relab.ResultsXML 
			SET EndDate=CONVERT(DATETIME, @EndDate), StartDate =@StartDate, IsProcessed=1, StationName=@StationName
			WHERE ID=@ID
			
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
GRANT EXECUTE ON Relab.remispResultsFileProcessing TO REMI
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispGetLookup]'
GO
ALTER PROCEDURE [dbo].[remispGetLookup] @Type NVARCHAR(150), @Lookup NVARCHAR(150), @ParentID INT = NULL
AS
BEGIN
	DECLARE @LookupTypeID INT
	SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name=@Type

	SELECT LookupID, IsActive FROM Lookups 
	WHERE LookupTypeID=@LookupTypeID AND [Values]=@Lookup AND 
		(
			(ISNULL(@ParentID, 0) > 0 AND ParentID=@ParentID)
			OR
			(ISNULL(@ParentID, 0) = 0)
		)
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispExceptionSearch]'
GO
ALTER procedure [dbo].[remispExceptionSearch] @ProductID INT = 0, @AccessoryGroupID INT = 0, @ProductTypeID INT = 0, @TestID INT = 0, @TestStageID INT = 0, @JobName NVARCHAR(400) = NULL, 
	@IncludeBatches INT = 0, @RequestReason INT = 0, @TestCenterID INT = 0, @IsMQual INT = 0, @QRANumber NVARCHAR(11) = NULL
AS
BEGIN
	DECLARE @JobID INT
	SELECT @JobID = ID FROM Jobs WITH(NOLOCK) WHERE JobName=@JobName

	select *
	from 
	(
		select ROW_NUMBER() over (order by p.ProductGroupName desc)as row, pvt.ID, b.QRANumber, ISNULL(tu.Batchunitnumber, 0) as batchunitnumber, pvt.[ReasonForRequest] As ReasonForRequestID, p.ProductGroupName,
		(select jobname from jobs,TestStages where teststages.id =pvt.TestStageid and Jobs.ID = TestStages.jobid) as jobname, 
		(select teststagename from teststages WITH(NOLOCK) where teststages.id =pvt.TestStageid) as teststagename, 
		t.TestName,pvt.TestStageID, pvt.TestUnitID,
		(select top 1 LastUser from TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
		(select top 1 ConcurrencyID from TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS ConcurrencyID,
		pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, pvt.IsMQual, 
		l3.[Values] As TestCenter, l3.[LookupID] AS TestCenterID, l4.[Values] As ReasonForRequest
		FROM vw_ExceptionsPivoted as pvt WITH(NOLOCK)
			LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
			LEFT OUTER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = pvt.TestUnitID
			LEFT OUTER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
			LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.LookupID=pvt.ProductTypeID
			LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.LookupID=pvt.AccessoryGroupID
			LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
			LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.LookupID=pvt.TestCenterID
			LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON l4.LookupID=pvt.ReasonForRequest
		WHERE (
				(pvt.[ProductID]=@ProductID) 
				OR
				(@ProductID = 0)
			)
			AND
			(
				(pvt.ReasonForRequest = @RequestReason)
				OR
				(@RequestReason = 0)
			)
			AND
			(
				(pvt.IsMQual = @IsMQual) 
				OR
				(@IsMQual = 0)
			)
			AND
			(
				(pvt.TestCenterID = @TestCenterID) 
				OR
				(@TestCenterID = 0)
			)
			AND
			(
				(pvt.AccessoryGroupID = @AccessoryGroupID) 
				OR
				(@AccessoryGroupID = 0)
			)
			AND
			(
				(pvt.ProductTypeID = @ProductTypeID) 
				OR
				(@ProductTypeID = 0)
			)
			AND
			(
				(pvt.Test = @TestID) 
				OR
				(@TestID = 0)
			)
			AND
			(
				(pvt.TestStageID = @TestStageID) 
				OR
				(@TestStageID = 0 And @JobID IS NULL OR @JobID = 0)
				OR
				(@JobID > 0 And @TestStageID = 0 AND pvt.TestStageID IN (SELECT ID FROM TestStages WHERE JobID=@JobID))
			)
			AND
			(
				(@IncludeBatches = 1)
				OR
				(@IncludeBatches = 0 AND pvt.TestUnitID IS NULL)
			)
			AND
			(
				(@QRANumber IS NULL)
				OR
				(@QRANumber IS NOT NULL AND b.QRANumber=@QRANumber)
			)
	) as exceptionResults
	ORDER BY QRANumber, Batchunitnumber, TestName
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispResultMeasurements]'
GO
ALTER PROCEDURE [Relab].[remispResultMeasurements] @ResultID INT, @OnlyFails INT = 0, @IncludeArchived INT = 0
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @FalseBit BIT
	DECLARE @ReTestNum INT
	CREATE TABLE #parameters (ResultMeasurementID INT)
	SELECT @ReTestNum= MAX(Relab.ResultsMeasurements.ReTestNum) FROM Relab.ResultsMeasurements WITH(NOLOCK) WHERE Relab.ResultsMeasurements.ResultID=@ResultID
	SET @FalseBit = CONVERT(BIT, 0)

	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + rp.ParameterName
		FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
			LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rm.ID=rp.ResultMeasurementID
		WHERE ResultID=@ResultID AND ((@IncludeArchived = 0 AND rm.Archived=@FalseBit) OR (@IncludeArchived=1)) AND ((@OnlyFails = 1 AND PassFail=@FalseBit) OR (@OnlyFails = 0))
			AND rp.ParameterName <> 'Command'
		ORDER BY '],[' +  rp.ParameterName
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

	SET @sql = 'ALTER TABLE #parameters ADD ' + convert(varchar(8000), replace(@rows, ']', '] NVARCHAR(250)'))
	EXEC (@sql)

	IF (@rows != '[na]')
	BEGIN
		EXEC ('INSERT INTO #parameters SELECT *
		FROM (
			SELECT rp.ResultMeasurementID, rp.ParameterName, rp.Value
			FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
				LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rm.ID=rp.ResultMeasurementID
			WHERE ResultID=' + @ResultID + ' AND ((' + @IncludeArchived + ' = 0 AND rm.Archived=' + @FalseBit + ') OR (' + @IncludeArchived + '=1)) 
				AND ((' + @OnlyFails + ' = 1 AND PassFail=' + @FalseBit + ') OR (' + @OnlyFails + ' = 0)) AND rp.ParameterName <> ''Command'' 
			) te PIVOT (MAX(Value) FOR ParameterName IN (' + @rows + ')) AS pvt')
	END
	ELSE
	BEGIN
		EXEC ('ALTER TABLE #parameters DROP COLUMN na')
	END

	SELECT CASE WHEN rm.Archived = 1 THEN 
	(SELECT MIN(ID) FROM relab.ResultsMeasurements rm2 WHERE rm2.ResultID=rm.ResultID AND rm2.MeasurementTypeID=rm.MeasurementTypeID 
		and isnull(Relab.ResultsParametersComma(rm.ID),'') = isnull(Relab.ResultsParametersComma(rm2.ID),'') and rm2.Archived=0)
	ELSE rm.ID END AS ID, ISNULL(ISNULL(ISNULL(lt.[Values], ltsf.[Values]), ltmf.[Values]), ltacc.[Values]) As Measurement, LowerLimit AS [Lower Limit], UpperLimit AS [Upper Limit], MeasurementValue AS Result, lu.[Values] As Unit, 
		CASE WHEN PassFail=1 THEN 'Pass' ELSE 'Fail' END AS [Pass/Fail],
		rm.MeasurementTypeID, rm.ReTestNum AS [Test Num], rm.Archived, rm.XMLID, 
		@ReTestNum AS MaxVersion, rm.Comment, ISNULL(rmf.[File], 0) AS [Image], 
		ISNULL(UPPER(SUBSTRING(rmf.ContentType,2,LEN(rmf.ContentType))), 'PNG') AS ContentType, rm.Description, 
		ISNULL((SELECT TOP 1 1 FROM Relab.ResultsMeasurementsAudit rma WHERE rma.ResultMeasurementID=rm.ID AND rma.PassFail <> rm.PassFail ORDER BY DateEntered DESC), 0) As WasChanged,
		 ISNULL(CONVERT(NVARCHAR, rm.DegradationVal), 'N/A') AS [Degradation], x.VerNum, p.*
	FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
		LEFT OUTER JOIN Lookups lu WITH(NOLOCK) ON lu.LookupID=rm.MeasurementUnitTypeID
		LEFT OUTER JOIN Lookups lt WITH(NOLOCK) ON lt.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltsf WITH(NOLOCK) ON ltsf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltmf WITH(NOLOCK) ON ltmf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltacc WITH(NOLOCK) ON ltacc.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Relab.ResultsMeasurementsFiles rmf WITH(NOLOCK) ON rmf.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN #parameters p WITH(NOLOCK) ON p.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN Relab.ResultsXML x ON x.ID = rm.XMLID
	WHERE rm.ResultID=@ResultID AND ((@IncludeArchived = 0 AND rm.Archived=@FalseBit) OR (@IncludeArchived=1)) AND ((@OnlyFails = 1 AND PassFail=@FalseBit) OR (@OnlyFails = 0))
	ORDER BY CASE WHEN rm.Archived = 1 THEN 
	(SELECT MIN(ID) FROM relab.ResultsMeasurements rm2 WHERE rm2.ResultID=rm.ResultID AND rm2.MeasurementTypeID=rm.MeasurementTypeID 
		and isnull(Relab.ResultsParametersComma(rm.ID),'') = isnull(Relab.ResultsParametersComma(rm2.ID),'') and rm2.Archived=0)
	ELSE rm.ID END, rm.ReTestNum

	DROP TABLE #parameters
	SET NOCOUNT OFF
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTrackingLocationsSearchFor]'
GO
ALTER PROCEDURE [dbo].[remispTrackingLocationsSearchFor]
	@RecordCount int = NULL OUTPUT,
	@ID int = null,
	@TrackingLocationName nvarchar(400)= null, 
	@GeoLocationID INT= null, 
	@Status int = null,
	@TrackingLocationTypeID int= null,
	@TrackingLocationTypeName nvarchar(400)=null,
	@TrackingLocationFunction int = null,
	@HostName nvarchar(255) = null,
	@OnlyActive INT = 0,
	@RemoveHosts INT = 0,
	@ShowHostsNamedAll INT = 0
AS
DECLARE @TrueBit BIT
DECLARE @FalseBit BIT
SET @TrueBit = CONVERT(BIT, 1)
SET @FalseBit = CONVERT(BIT, 0)

IF (@RecordCount IS NOT NULL)
BEGIN
	SET @RecordCount = (SELECT distinct COUNT(*) 
	FROM TrackingLocations as tl 
		INNER JOIN TrackingLocationTypes as tlt ON tl.TrackingLocationTypeID = tlt.ID
		LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
	WHERE (tl.ID = @ID or @ID is null) 
	and (tlh.status = @Status or @Status is null)
	and (tl.TrackingLocationName = @TrackingLocationName or @TrackingLocationName is null)
	and (TestCenterLocationID = @GeoLocationID or @GeoLocationID is null)
	and (tlh.HostName = @HostName or tlh.HostName='all' or @HostName is null)
	and (tl.TrackingLocationTypeID = @TrackingLocationTypeID or @TrackingLocationTypeID is null)
	and ((tl.TrackingLocationTypeID= tlt.id and tlt.TrackingLocationTypeName = @TrackingLocationTypeName) or @TrackingLocationTypeName is null)
	 and ((tl.TrackingLocationTypeID= tlt.id and tlt.TrackingLocationFunction = @TrackingLocationFunction )or @TrackingLocationFunction is null)
	 AND (
				(@OnlyActive = 1 AND ISNULL(tl.Decommissioned, 0) = 0)
				OR
				(@OnlyActive = 0)
			)
	)
	RETURN
END

SELECT DISTINCT tl.ID, tl.TrackingLocationName, tl.TestCenterLocationID, 
	CASE WHEN @RemoveHosts = 1 THEN 1 ELSE CASE WHEN tlh.Status IS NULL THEN 3 ELSE tlh.Status END END AS Status, 
	tl.LastUser, 
	CASE WHEN @RemoveHosts = 1 THEN '' ELSE tlh.HostName END AS HostName,
	tl.ConcurrencyID, tl.comment,l3.[Values] AS GeoLocationName, 
	CASE WHEN @RemoveHosts = 1 THEN 0 ELSE ISNULL(tlh.ID,0) END AS TrackingLocationHostID,
	(
		SELECT COUNT(*) as CurrentCount 
		FROM TestUnits AS tu
			INNER JOIN DeviceTrackingLog AS dtl ON dtl.TestUnitID = tu.ID
		WHERE dtl.TrackingLocationID = tl.ID and (dtl.OutUser IS NULL)
	) AS CurrentCount,
	tlt.wilocation as TLTWILocation, tlt.UnitCapacity as TLTUnitCapacity, tlt.Comment as TLTComment, tlt.ConcurrencyID as TLTConcurrencyID, tlt.LastUser as TLTLastUser,
	tlt.ID as TLTID, tlt.TrackingLocationTypeName as TLTName, tlt.TrackingLocationFunction as TLTFunction,
	(
		SELECT TOP(1) tu.CurrentTestName as CurrentTestName
		FROM TestUnits AS tu
			INNER JOIN DeviceTrackingLog AS dtl ON dtl.TestUnitID = tu.ID
		WHERE tu.CurrentTestName is not null and dtl.TrackingLocationID = tl.ID and (dtl.OutUser IS NULL)
	) AS CurrentTestName,
	(CASE WHEN EXISTS (SELECT TOP 1 1 FROM DeviceTrackingLog dl WHERE dl.TrackingLocationID=tl.ID) THEN @FalseBit ELSE @TrueBit END) As CanDelete,
	CASE WHEN ISNULL(l3.IsActive, 1) = 0 THEN CONVERT(BIT, 1) ELSE ISNULL(tl.Decommissioned, 0) END AS Decommissioned, ISNULL(tl.IsMultiDeviceZone, 0) AS IsMultiDeviceZone, tl.Status AS LocationStatus
	FROM TrackingLocations as tl
		INNER JOIN TrackingLocationTypes as tlt ON tl.TrackingLocationTypeID = tlt.ID
		LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
		LEFT OUTER JOIN Lookups l3 ON l3.lookupID=tl.TestCenterLocationID
	WHERE (tl.ID = @ID or @ID is null) and (tlh.status = @Status or @Status is null)
		and (tl.TrackingLocationName = @TrackingLocationName or @TrackingLocationName is null)
		and (TestCenterLocationID = @GeoLocationID or @GeoLocationID is null)
		and 
		(
			tlh.HostName = @HostName 
			or 
			(
				(@ShowHostsNamedAll = 1 AND tlh.HostName='all')
			)
			or
			@HostName is null 
			or 
			(
				@HostName is not null 
				and exists 
					(
						SELECT tlt1.TrackingLocationTypeName 
						FROM TrackingLocations as tl1
							INNER JOIN trackinglocationtypes as tlt1 ON tlt1.ID = tl1.TrackingLocationTypeID
							INNER JOIN TrackingLocationsHosts tlh1 ON tl1.ID = tlh1.TrackingLocationID
						WHERE tlh1.HostName = @HostName and tlt1.TrackingLocationTypeName = 'Storage'
					)
			)
		)
		and (tl.TrackingLocationTypeID= tlt.id and tlt.id = @TrackingLocationTypeID or @TrackingLocationTypeID is null)
		and (tl.TrackingLocationTypeID= tlt.id and tlt.TrackingLocationTypeName = @TrackingLocationTypeName or @TrackingLocationTypeName is null)
		and (tl.TrackingLocationTypeID= tlt.id and tlt.TrackingLocationFunction = @TrackingLocationFunction or @TrackingLocationFunction is null)
		AND (
				(@OnlyActive = 1 AND ISNULL(tl.Decommissioned, 0) = 0)
				OR
				(@OnlyActive = 0)
			)
	ORDER BY CASE WHEN ISNULL(l3.IsActive,1) = 0 THEN CONVERT(BIT, 1) ELSE ISNULL(tl.Decommissioned, 0) END, tl.TrackingLocationName
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesGetActiveBatchesByRequestor]'
GO
ALTER PROCEDURE [dbo].[remispBatchesGetActiveBatchesByRequestor]
/*	'===============================================================
	'   NAME:                	remispBatchesGetActiveBatchesByRequestor
	'   DATE CREATED:       	28 Feb 2011
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves active batches by requestor
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
	@StartRowIndex int = null,
	@MaximumRows int = null,
	@RecordCount int = null OUTPUT,
	@Requestor nvarchar(500) = null
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Batches WITH(NOLOCK) WHERE BatchStatus NOT IN(5,7) and Requestor = @Requestor	)	
		RETURN
	END

	SELECT BatchesRows.row,BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName, batchesrows.ProductID,
		BatchesRows.QRANumber,BatchesRows.RequestPurpose, BatchesRows.TestCenterLocation,BatchesRows.TestStageName, BatchesRows.TestStageCompletionStatus, 
		batchesrows.testUnitCount,BatchesRows.RQID As ReqID,batchesrows.TestCenterLocationID,
		(CASE WHEN batchesrows.WILocation IS NULL THEN NULL ELSE batchesrows.WILocation END) AS jobWILocation,
		(
			testunitcount -
			(select COUNT(*) 
			from TestUnits as tu WITH(NOLOCK)
				INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
		) as HasUnitsToReturnToRequestor,
		ISNULL(
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
			WHERE ta.BatchID = BatchesRows.ID and ta.Active=1), 
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
			WHERE ta.Active=1 AND ISNULL(ta.taskID,0) = 0 AND ta.BatchID = BatchesRows.ID)
		) as ActiveTaskAssignee,
		CONVERT(BIT,0) AS HasBatchSpecificExceptions, BatchesRows.AccessoryGroupID,BatchesRows.ProductTypeID,
		AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate, IsMQual, JobID, ExecutiveSummary, MechanicalTools,
		BatchesRows.RequestPurposeID, BatchesRows.PriorityID, DepartmentID, Department
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
				b.BatchStatus,b.Comment,
				b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority AS PriorityID,p.ProductGroupName,b.ProductTypeID, b.AccessoryGroupID,p.ID As ProductID,b.QRANumber,
				b.RequestPurpose AS RequestPurposeID,b.TestCenterLocationID,b.TestStageName, j.WILocation,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, b.RQID, l3.[Values] As TestCenterLocation,
				b.AssemblyNumber, b.AssemblyRevision, b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, 
				ExecutiveSummary, MechanicalTools, l4.[Values] As RequestPurpose, l5.[Values] As Priority, b.DepartmentID, l6.[Values] AS Department
			FROM Batches as b
				inner join Products p WITH(NOLOCK) on p.ID=b.ProductID
				LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON b.AccessoryGroupID=l2.LookupID
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON b.TestCenterLocationID=l3.LookupID    
				LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON b.RequestPurpose=l4.LookupID 
				LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON b.Priority=l5.LookupID
				LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON b.DepartmentID=l6.LookupID
			WHERE BatchStatus NOT IN(5,7) and Requestor = @Requestor
		) AS BatchesRows
WHERE (Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex is null OR @maximumRows is null
order by BatchesRows.QRANumber
RETURN
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[RemispGetTestCountByType]'
GO
ALTER PROCEDURE [dbo].[RemispGetTestCountByType] @StartDate DateTime = NULL, @EndDate DateTime = NULL, @ReportBasedOn INT = NULL, @GeoLocationID INT, @ByPassProductCheck INT, @UserID INT
AS
BEGIN
	If (@StartDate IS NULL)
	BEGIN
		SET @StartDate = GETDATE()
	END
	
	IF (@ReportBasedOn IS NULL)
	BEGIN
		SET @ReportBasedOn = 1
	END

	DECLARE @TrueBit BIT
	SET @TrueBit = CONVERT(BIT, 1)

	SELECT '# Completed Testing' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM TrackingLocations tl WITH(NOLOCK)
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus = 8 and ba.inserttime between @startdate and @enddate
		INNER JOIN BatchesAudit ba2 WITH(NOLOCK) ON b.ID = ba2.BatchID AND ba2.BatchStatus <> 8 and ba2.inserttime between @startdate and @enddate
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName
	ORDER BY tl.TrackingLocationName, tr.TestName

	SELECT '# in Chamber' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM TrackingLocations tl WITH(NOLOCK)
		INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tl.TrackingLocationTypeID = tlt.ID AND tlt.TrackingLocationFunction = 4
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName

	SELECT '# Units in FA' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM (
			SELECT tra.TestRecordId 
			FROM TestRecordsaudit tra WITH(NOLOCK)
			WHERE tra.Action IN ('I','U') AND tra.Status IN (3, 4) and tra.InsertTime BETWEEN @startdate AND @enddate--FQRaised and FARequired
			GROUP BY TestRecordId
			) as xer 
		INNER JOIN TestRecords tr WITH(NOLOCK) ON xer.TestRecordID = tr.ID  
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON dtl.ID = trtl.TrackingLogID
		INNER JOIN TrackingLocations tl WITH(NOLOCK) ON tl.ID = dtl.TrackingLocationID
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
		INNER JOIN Batches b ON tu.BatchID = b.ID
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName

	SELECT '# Worked On Parametric' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM TrackingLocations tl WITH(NOLOCK)
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
		INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = @TrueBit
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName

	SELECT '# Completed Parametric' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM TrackingLocations tl WITH(NOLOCK)
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
		INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = @TrueBit
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName

	SELECT '# Worked On Drop' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM TrackingLocations tl WITH(NOLOCK)
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
		INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit AND j.JobName LIKE '%Drop%'
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName

	SELECT '# Worked On Tumble' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM TrackingLocations tl WITH(NOLOCK)
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
		INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit AND j.JobName LIKE '%Tumble%'
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName

	SELECT '# Completed Drop' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM TrackingLocations tl WITH(NOLOCK)
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
		INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit AND j.JobName LIKE '%Drop%'
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName

	SELECT '# Completed Tumble' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM TrackingLocations tl WITH(NOLOCK)
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
		INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit AND j.JobName LIKE '%Tumble%'
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName

	SELECT '# Worked On Accessories' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM TrackingLocations tl WITH(NOLOCK)
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
		INNER JOIN Lookups l ON l.LookupID=b.ProductTypeID
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate AND l.[Values] = 'Accessory'
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName

	SELECT '# Worked On Component' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM TrackingLocations tl WITH(NOLOCK)
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
		INNER JOIN Lookups l WITH(NOLOCK) ON l.LookupID=b.ProductTypeID
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate AND l.[Values] = 'Component'
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName

	SELECT '# Worked On Handheld' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM Batches b
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
		INNER JOIN Lookups l WITH(NOLOCK) ON l.LookupID=b.ProductTypeID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID=tu.BatchID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON tr.TestUnitID=tu.ID
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TestRecordID=tr.ID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
		INNER JOIN TrackingLocations tl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate AND l.[Values] = 'Handheld'
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispUsersSearch]'
GO
ALTER procedure [dbo].[remispUsersSearch] @ProductID INT = 0, @TestCenterID INT = 0, @TrainingID INT = 0, @TrainingLevelID INT = 0, @ByPass INT = 0, @showAllGrid BIT = 0, @UserID INT = 0, @DepartmentID INT = 0
AS
BEGIN
	IF (@showAllGrid = 0)
	BEGIN
		SELECT DISTINCT u.ID, u.LDAPLogin
		FROM Users u
			LEFT OUTER JOIN UserTraining ut ON ut.UserID = u.ID
			LEFT OUTER JOIN UsersProducts up ON up.UserID = u.ID
		WHERE u.IsActive=1 AND (
				(u.TestCentreID=@TestCenterID) 
				OR
				(@TestCenterID = 0)
			  )
			  AND
			  (
				(ut.LookupID=@TrainingID) 
				OR
				(@TrainingID = 0)
			  )
			  AND
			  (
				(ut.LevelLookupID=@TrainingLevelID) 
				OR
				(@TrainingLevelID = 0)
			  )
			  AND
			  (
				(u.ByPassProduct=@ByPass) 
				OR
				(@ByPass = 0)
			  )
			  AND
			  (
				(up.ProductID=@ProductID) 
				OR
				(@ProductID = 0)
			  )
			  AND 
			  (
				(u.DepartmentID=@DepartmentID) 
				OR
				(@DepartmentID = 0)
			  )
		ORDER BY u.LDAPLogin
	END
	ELSE
	BEGIN
		DECLARE @rows VARCHAR(8000)
		DECLARE @query VARCHAR(4000)
		SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + l.[Values]
		FROM Lookups l
			INNER JOIN LookupType lt ON lt.LookupTypeID=l.LookupTypeID
		WHERE lt.Name='Training' And l.IsActive=1
		AND (
				(l.LookupID=@TrainingID) 
				OR
				(@TrainingID = 0)
			  )
		ORDER BY '],[' + l.[Values]
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

		SET @query = '
			SELECT *
			FROM
			(
				SELECT CASE WHEN ut.lookupID IS NOT NULL THEN (CASE WHEN ut.LevelLookupID IS NULL THEN ''*'' ELSE (SELECT SUBSTRING([values], 1, 1) FROM Lookups WHERE LookupID=LevelLookupID) END) ELSE NULL END As Row, u.LDAPLogin, l.[values] As Training
				FROM Users u WITH(NOLOCK)
					LEFT OUTER JOIN UserTraining ut ON ut.UserID = u.ID
					LEFT OUTER JOIN Lookups l on l.lookupid=ut.lookupid
				WHERE u.IsActive = 1 AND (
				(u.TestCentreID=' + CONVERT(VARCHAR, @TestCenterID) + ') 
				OR
				(' + CONVERT(VARCHAR, @TestCenterID) + ' = 0)
			  )
			  AND
			  (
				(ut.LookupID=' + CONVERT(VARCHAR, @TrainingID) + ') 
				OR
				(' + CONVERT(VARCHAR, @TrainingID) + ' = 0)
			  )
			  AND
			  (
				(u.ID=' + CONVERT(VARCHAR, @UserID) + ')
				OR
				(' + CONVERT(VARCHAR, @UserID) + ' = 0)
			  )
			)r
			PIVOT 
			(
				MAX(row) 
				FOR Training 
					IN ('+@rows+')
			) AS pvt'
		EXECUTE (@query)	
	END
END
GO
INSERT INTO LookupType (Name) VALUES ('FieldTypes')
INSERT INTO LookupType (Name) VALUES ('ValidationTypes')
GO

DECLARE @LookupTypeID INT
DECLARE @LookupID INT
SELECT @LookupTypeID=LookupTypeID FROM LookupType WHERE Name='FieldTypes'

SELECT @LookupID = MAX(LookupID)+1 FROM Lookups
INSERT INTO Lookups (LookupID,LookupTypeID, IsActive, [Values]) VALUES (@LookupID, @LookupTypeID, 1, 'DropDown')
SET @LookupID = @LookupID +1
INSERT INTO Lookups (LookupID,LookupTypeID, IsActive, [Values]) VALUES (@LookupID, @LookupTypeID, 1, 'CheckBox')
SET @LookupID = @LookupID +1
INSERT INTO Lookups (LookupID,LookupTypeID, IsActive, [Values]) VALUES (@LookupID, @LookupTypeID, 1, 'RadioButton')
SET @LookupID = @LookupID +1
INSERT INTO Lookups (LookupID,LookupTypeID, IsActive, [Values]) VALUES (@LookupID, @LookupTypeID, 1, 'TextBox')
SET @LookupID = @LookupID +1
INSERT INTO Lookups (LookupID,LookupTypeID, IsActive, [Values]) VALUES (@LookupID, @LookupTypeID, 1, 'TextArea')

SELECT @LookupTypeID=LookupTypeID FROM LookupType WHERE Name='ValidationTypes'
SET @LookupID = @LookupID +1
INSERT INTO Lookups (LookupID,LookupTypeID, IsActive, [Values]) VALUES (@LookupID, @LookupTypeID, 1, 'Double')
SET @LookupID = @LookupID +1
INSERT INTO Lookups (LookupID,LookupTypeID, IsActive, [Values]) VALUES (@LookupID, @LookupTypeID, 1, 'Int')
SET @LookupID = @LookupID +1
INSERT INTO Lookups (LookupID,LookupTypeID, IsActive, [Values]) VALUES (@LookupID, @LookupTypeID, 1, 'String')
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
rollback TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO