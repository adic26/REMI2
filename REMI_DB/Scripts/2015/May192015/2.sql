begin tran
go
ALTER PROCEDURE [dbo].[remispProductSettingsInsertUpdateSingleItem]
	@lookupid INT,
	@KeyName nvarchar(MAX),
	@ValueText nvarchar(MAX) = null,
	@DefaultValue nvarchar(MAX),
	@LastUser nvarchar(255)	
AS
	DECLARE @ReturnValue int
	declare @ID int
	
	set @ID = (select ID from ProductSettings as ps  where ps.KeyName = @KeyName and lookupid=@lookupid)

	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO ProductSettings
		(
			lookupid, 
			KeyName,
			ValueText,
			LastUser,
			DefaultValue
		)
		VALUES
		(
			@lookupid, 
			@KeyName,
			@ValueText,
			@LastUser,
			@DefaultValue
		)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN	
		if (select defaultvalue from ProductSettings where ID = @ID) != @DefaultValue
		begin
			--update the defaultvalues for any entries
			update ProductSettings set ValueText = @DefaultValue where ValueText = DefaultValue and KeyName = @KeyName;
			update ProductSettings set DefaultValue = @DefaultValue where KeyName = @KeyName;
		end
		
		--and update everything else
		UPDATE ProductSettings SET
			lookupid = @lookupid, 
			LastUser = @LastUser,
			KeyName = @KeyName,
			ValueText = ISNULL(@ValueText, '')
		WHERE ID = @ID
		SELECT @ReturnValue = @ID
	END
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
GRANT EXECUTE ON remispProductSettingsInsertUpdateSingleItem TO Remi
go
ALTER PROCEDURE remispProductTestReady @Lookupid INT, @MNum NVARCHAR(3)
AS
BEGIN
	DECLARE @PSID AS INT = (SELECT ID FROM ProductSettings WHERE KeyName=@MNum AND LookupID=@Lookupid)
	
	SELECT t.TestName, @MNum AS M, CASE ptr.IsReady WHEN 1 THEN 'Yes' WHEN 2 THEN 'No' WHEN 3 THEN 'N/A' ELSE '' END AS IsReady, 
		ptr.Comment, t.Owner, t.Trainee, t.ID As TestID, ptr.ID As ReadyID, @PSID As PSID,
		CASE ptr.IsNestReady WHEN 1 THEN 'Yes' WHEN 2 THEN 'No' WHEN 3 THEN 'N/A' ELSE '' END AS IsNestReady, CASE WHEN JIRA = 0 THEN NULL ELSE JIRA END AS JIRA
	FROM Tests t
		LEFT OUTER JOIN ProductTestReady ptr ON ptr.TestID=t.ID AND ptr.PSID=@PSID AND ptr.LookupID = @Lookupid
	WHERE t.TestName IN ('Parametric Radiated Wi-Fi','Acoustic Test', 'HAC Test', 'Sensor Test',
		'Touch Panel Test','Insertion','Top Facing Keys Tactility Test','Peripheral Keys Tactility Test','Charging Test',
		'Camera Front','Bluetooth Test','Accessory Charging','Accessory Acoustic Test','Radiated RF Test','KET Top Facing Keys Cycling Test',
		'Slider Test','Altimeter Test','Mechanical Over Extention')
		AND ISNULL(t.IsArchived, 0) = 0
	ORDER BY t.TestName
END
GO
GRANT EXECUTE ON remispProductTestReady TO REMI
GO
ALTER PROCEDURE [dbo].[remispDeviceTrackingLogSelectListByProductDate] @Lookupid INT, @Date as datetime = '05/22/1983'
AS
	SELECT dtl.ID,
		TestUnitId, 
		TrackingLocationId, 
		InTime, 
		OutTime, 
		InUser, 
		OutUser,
		dtl.ConcurrencyID,
		tu.BatchUnitNumber,
		b.QRANumber, 
		tl.TrackingLocationName
	FROM Batches as b
		INNER JOIN TestUnits tu ON tu.BatchID = b.id
		LEFT OUTER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID
		LEFT OUTER JOIN TrackingLocations as tl ON tl.ID = dtl.TrackingLocationID
		INNER JOIN Products p ON p.ID=b.ProductID
	WHERE p.LookupID = @Lookupid and (dtl.InTime > @Date) 
	order by  dtl.intime desc
GO
GRANT EXECUTE ON remispDeviceTrackingLogSelectListByProductDate TO Remi
GO
ALTER PROCEDURE [dbo].[remispProductSettingsSelectListForProduct] @LookupID INT
AS 
select keyVals.keyname,
	case when keyVals.valueText is not null then keyVals.valueText 
	else keyVals.defaultValue 
	end as valuetext, 
	keyVals.defaultvalue
from
	(
		select distinct ps1.keyName as keyname, ps2.ValueText, ps1.DefaultValue
		FROM ProductSettings as ps1
			left outer join ProductSettings as ps2 on ps1.KeyName = ps2.KeyName and ps2.LookupID = @LookupID
	) as keyVals
order by keyname 
GO
GRANT EXECUTE ON remispProductSettingsSelectListForProduct TO Remi
GO
ALTER PROCEDURE [dbo].[remispProductSettingsSelectSingleValue]
/*	'===============================================================
'   NAME:                	remispProductSettingsSelectSingleValue
'   DATE CREATED:       	4 Nov 2011
'   CREATED BY:          	Darragh O'Riordan
'   FUNCTION:            	Retrieves data from table: ProductSettings 
'   VERSION: 1           
'   COMMENTS:            
'   MODIFIED ON:         
'   MODIFIED BY:         
'   REASON MODIFICATION: 
	'===============================================================*/
	@LookupID INT,
	@keyname as nvarchar(MAX)
AS
declare @valueText nvarchar(MAX);
declare @defaultValue nvarchar(MAX);
	
set @valuetext = (select ValueText FROM ProductSettings as ps where ps.LookupID = @LookupID and KeyName = @keyname)
set @defaultValue =(select top (1) DefaultValue FROM ProductSettings as ps where KeyName = @keyname and DefaultValue is not null)
select case when @valueText is not null then @valueText else @defaultValue end as [ValueText];
GO
GRANT EXECUTE ON remispProductSettingsSelectSingleValue TO Remi
GO
alter PROCEDURE [dbo].[remispProductSettingsDeleteSetting]
	@lookupid INT,
	@keyname as nvarchar(MAX),
	@userName as nvarchar(255)
AS 
	
declare @id int =(select ProductSettings.id from ProductSettings where LookupID = @lookupid and KeyName = @keyname)

if (@id is not null)
begin
	update ProductSettings set LastUser = @userName where ID = @id;
	Delete FROM ProductSettings where ID = @id;
end
GO
GRANT EXECUTE ON remispProductSettingsDeleteSetting TO Remi
GO
ALTER VIEW [dbo].[vw_GetTaskInfoCompleted]
AS
SELECT qranumber, processorder, BatchID,
	   tsname, 
	   tname, 
	   testtype, 
	   teststagetype, 
	   resultbasedontime, 
	   testunitsfortest, 
	   (SELECT CASE WHEN specifictestduration IS NULL THEN generictestduration ELSE specifictestduration END) AS expectedDuration,
	   TestStageID, TestWI, TestID, IsArchived, RecordExists, TestIsArchived, TestRecordExists
FROM   
	(
		SELECT b.qranumber,b.ID AS BatchID,
		ts.processorder, ts.teststagename AS tsname, t.testname AS tname, t.testtype, ts.teststagetype, t.duration AS genericTestDuration, ts.ID AS TestStageID,t.ID AS TestID,
		t.WILocation As TestWI, ISNULL(ts.IsArchived, 0) AS IsArchived, ISNULL(t.IsArchived, 0) AS TestIsArchived, 
			t.resultbasedontime, 
			(
				SELECT bstd.duration 
				FROM   batchspecifictestdurations AS bstd WITH(NOLOCK)
				WHERE  bstd.testid = t.id 
					   AND bstd.batchid = b.id
			) AS specificTestDuration,
			(				
				SELECT Cast(tu.batchunitnumber AS VARCHAR(MAX)) + ', ' 
				FROM testunits AS tu WITH(NOLOCK)
				WHERE tu.batchid = b.id 
				FOR xml path ('')
			) AS TestUnitsForTest,
			(SELECT TOP 1 1
			FROM TestRecords tr WITH(NOLOCK)
				INNER JOIN TestUnits tu ON tr.TestUnitID = tu.ID
			WHERE tr.TestStageID=ts.ID AND tu.BatchID=b.ID) AS RecordExists,
			(SELECT TOP 1 1
			FROM TestRecords tr WITH(NOLOCK)
				INNER JOIN TestUnits tu ON tr.TestUnitID = tu.ID
			WHERE tr.TestID=t.ID AND tu.BatchID=b.ID AND tr.TestStageID = ts.ID) AS TestRecordExists
		FROM TestStages ts WITH(NOLOCK)
		INNER JOIN Jobs j WITH(NOLOCK) ON ts.JobID=j.ID
		INNER JOIN Batches b WITH(NOLOCK) on j.jobname = b.jobname 
		INNER JOIN Tests t WITH(NOLOCK) ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
	) AS unitData
WHERE TestUnitsForTest IS NOT NULL AND ISNULL(TestRecordExists, 0) = 1 AND ISNULL(RecordExists,0) = 1
GO
ALTER VIEW [dbo].[vw_GetBatchRequestResult]
AS
SELECT b.QRANumber, b.BatchStatus, b.DateCreated, b.ExecutiveSummary, b.ExpectedSampleSize, b.IsMQual, b.UnitsToBeReturnedToRequestor,
	tu.BatchUnitNumber, tu.BSN, tu.IMEI, lp.[values] AS ProductGroupName, PT.[Values] As ProductType, ag.[Values] As AccessoryGroup,
	tc.[Values] As TestCenter, reqpur.[Values] As RequestPurpose, pty.[Values] As Priority, dpmt.[Values] As Department,
	rtn.[Values] As RequestName, rfs.Name, rfd.Value, ts.TestStageName, t.TestName, mn.[Values] As MeasurementName, 
	m.MeasurementValue, m.LowerLimit, m.UpperLimit, m.Archived, m.Comment, m.DegradationVal, m.Description, m.PassFail, m.ReTestNum,
	mut.[Values] As MeasurementUnitType, ri.Name As InformationName, ri.Value As InformationValue, ri.IsArchived As InformationArchived,
	rp.ParameterName, rp.Value As ParameterValue, rx.VerNum AS XMLVerNum, rx.StationName, rx.StartDate, rx.EndDate
FROM Batches b
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN Req.Request rq WITH(NOLOCK) ON rq.RequestNumber=b.QRANumber
	INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=b.ProductID
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
ALTER PROCEDURE [dbo].[remispYourBatchesGetActiveBatches] @UserID int, @ByPassProductCheck INT = 0, @Year INT = 0, @OnlyShowQRAWithResults INT = 0
AS	
SELECT b.ID, lp.[Values] AS ProductGroupName,b.QRANumber, (b.QRANumber + ' ' + lp.[Values]) AS Name
	FROM Batches as b WITH(NOLOCK)
	INNER JOIN Lookups p WITH(NOLOCK) ON p.LookupID=b.ProductID
	INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
WHERE ( 
		(@Year = 0 AND BatchStatus NOT IN(5,7))
		OR
		(@Year > 0 AND b.QRANumber LIKE '%-' + RIGHT(CONVERT(NVARCHAR, @Year), 2) + '-%')
	  )
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND lp.LookupID IN (SELECT up.LookupID FROM UserDetails up WITH(NOLOCK) WHERE UserID=@UserID)))
	AND (@OnlyShowQRAWithResults = 0 OR (@OnlyShowQRAWithResults = 1 AND b.ID IN (SELECT tu.BatchID FROM Relab.Results r WITH(NOLOCK) INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID)))
	AND (b.DepartmentID IN (SELECT ud.LookupID 
							FROM UserDetails ud WITH(NOLOCK)
								INNER JOIN Lookups lt WITH(NOLOCK) ON lt.LookupID=ud.LookupID
							WHERE ud.UserID=@UserID))
ORDER BY b.QRANumber DESC
RETURN
GO
GRANT EXECUTE ON remispYourBatchesGetActiveBatches TO Remi
GO
ALTER PROCEDURE dbo.remispGetContacts @LookupID INT
AS
BEGIN
	SELECT ISNULL(us.LDAPLogin, '') AS TSDContact
	INTO #tempTSD
	FROM UserDetails ud WITH(NOLOCK)
		INNER JOIN Lookups p WITH(NOLOCK) ON p.LookupID=ud.LookupID
		INNER JOIN Users us WITH(NOLOCK) ON us.ID=ud.UserID
	WHERE ud.IsTSDContact=1 AND p.LookupID=@LookupID

	SELECT ISNULL(us.LDAPLogin, '') AS ProductManager
	INTO #temp
	FROM UserDetails ud WITH(NOLOCK)
		INNER JOIN Users us WITH(NOLOCK) ON us.ID=ud.UserID
	WHERE ud.IsProductManager=1 AND ud.LookupID=@LookupID
	
	SELECT pm.*, tsd.*
	FROM
	(
		SELECT ProductManager
		FROM #temp
	) pm,
	(
		SELECT TSDContact
		FROM #tempTSD
	) tsd
	
	DROP TABLE #temp
	DROP TABLE #tempTSD
END
GO
GRANT EXECUTE ON [dbo].remispGetContacts TO REMI
GO
ALTER PROCEDURE [dbo].remispGetBatchDocuments @QRANumber nvarchar(11)
AS
BEGIN
	DECLARE @JobName NVARCHAR(400)
	DECLARE @LookupID INT
	DECLARE @ID INT
	SELECT @JobName = JobName, @LookupID = p.LookupID, @ID = b.ID 
	FROM Batches b WITH(NOLOCK)
		INNER JOIN Lookups p WITH(NOLOCK) ON p.LookupID=b.ProductID
	WHERE QRANumber=@QRANumber

	CREATE TABLE #view (QRANumber NVARCHAR(11), expectedDuration REAL, processorder INT, resultbasedontime INT, TestName NVARCHAR(400) COLLATE SQL_Latin1_General_CP1_CI_AS, testtype INT, teststagetype INT, TestStageName NVARCHAR(400), testunitsfortest NVARCHAR(MAX), TestID INT, TestStageID INT, IsArchived BIT, TestIsArchived BIT, TestWI NVARCHAR(400) COLLATE SQL_Latin1_General_CP1_CI_AS, TestCounts NVARCHAR(MAX))

	insert into #view (QRANumber, expectedDuration, processorder, resultbasedontime, TestName, testtype, teststagetype, TestStageName, testunitsfortest, TestID, TestStageID, IsArchived, TestIsArchived, TestWI, TestCounts)
	exec remispBatchGetTaskInfo @BatchID=@ID

	SELECT (j.JobName + ' WI') AS WIType, j.WILocation AS Location
	FROM Jobs j WITH(NOLOCK)
	WHERE j.JobName=@JobName AND LTRIM(RTRIM(ISNULL(j.WILocation, ''))) <> ''
	UNION
	SELECT DISTINCT TestName AS WIType, TestWI AS Location
	FROM #view WITH(NOLOCK)
	WHERE QRANumber=@QRANumber and processorder > 0 AND testtype IN (1,2) AND LTRIM(RTRIM(ISNULL(TestWI,''))) <> ''
	UNION
	SELECT (j.JobName + ' Procedure') AS WIType, j.ProcedureLocation AS Location
	FROM Jobs j WITH(NOLOCK)
	WHERE j.JobName=@JobName AND LTRIM(RTRIM(ISNULL(j.ProcedureLocation, ''))) <> ''
	UNION
	SELECT 'Specification' AS WIType, 'http://hwqaweb.rim.net/pls/trs/data_entry.main?req=QRA-ENG-SP-11-0001' AS Location
	UNION
	SELECT 'QAP' As WIType, l.Description AS Location
	FROM Lookups l WITH(NOLOCK)
	WHERE l.LookupID=@LookupID AND LTRIM(RTRIM(ISNULL(l.Description, ''))) <> ''

	DROP TABLE #view
END
GO
GRANT EXECUTE ON remispGetBatchDocuments TO REMI
GO
ALTER PROCEDURE [dbo].[remispDeviceTrackingLogSelectListByProductDate] @Lookupid INT, @Date as datetime = '05/22/1983'
AS
	SELECT dtl.ID,
		TestUnitId, 
		TrackingLocationId, 
		InTime, 
		OutTime, 
		InUser, 
		OutUser,
		dtl.ConcurrencyID,
		tu.BatchUnitNumber,
		b.QRANumber, 
		tl.TrackingLocationName
	FROM Batches as b
		INNER JOIN TestUnits tu ON tu.BatchID = b.id
		LEFT OUTER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID
		LEFT OUTER JOIN TrackingLocations as tl ON tl.ID = dtl.TrackingLocationID
	WHERE b.ProductID = @Lookupid and (dtl.InTime > @Date) 
	order by  dtl.intime desc
GO
GRANT EXECUTE ON remispDeviceTrackingLogSelectListByProductDate TO Remi
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
	ReportApprovedDate, IsMQual, JobID, ExecutiveSummary, MechanicalTools, batchesrows.RequestPurposeID, batchesrows.PriorityID, DepartmentID, Department, Requestor
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
					 ExecutiveSummary, MechanicalTools, RequestPurposeID, PriorityID, DepartmentID, Department, Requestor
                      from
				(SELECT DISTINCT 
                      b.ID, 
                      b.QRANumber, 
                      b.Comment,
                      b.RequestPurpose As RequestPurposeID, 
                      b.Priority AS PriorityID,
                      b.TestStageName, 
                      b.BatchStatus, 
                      lp.[Values] AS ProductGroupName, 
					  b.ProductTypeID,
					  b.AccessoryGroupID,
					  l.[Values] As ProductType,
					  l2.[Values] As AccessoryGroupName,
					  l3.[Values] As TestCenterLocation,
					  b.ProductID As ProductID,
                      b.JobName, 
                      b.LastUser, 
                      b.TestCenterLocationID,
                      b.ConcurrencyID,
                      b.TestStageCompletionStatus,
                      j.WILocation,
					  b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, j.ID As JobID,
					  ExecutiveSummary, MechanicalTools, l4.[Values] AS RequestPurpose, l5.[Values] AS Priority, b.DepartmentID, l6.[Values] AS Department, b.Requestor
				FROM Batches AS b 
					INNER JOIN DeviceTrackingLog AS dtl WITH(NOLOCK) 
					INNER JOIN TrackingLocations AS tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.ID 
					INNER JOIN TestUnits AS tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID ON b.id = tu.batchid --batches where there's a tracking log
					INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=b.ProductID
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
GRANT EXECUTE ON remispBatchesSelectListAtTrackingLocation TO Remi
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
	BatchesRows.PriorityID, DepartmentID, Department, Requestor
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
			RequestPurposeID, PriorityID, DepartmentID, Department, Requestor
		FROM 
		(
			SELECT DISTINCT b.ID, 
				b.QRANumber, 
				b.Comment,
				b.RequestPurpose As RequestPurposeID, 
				b.Priority AS PriorityID,
				b.TestStageName, 
				b.BatchStatus, 
				lp.[Values] AS ProductGroupName, 
				b.ProductTypeID,
				b.AccessoryGroupID,
				l.[Values] AS ProductType,
				l2.[Values] As AccessoryGroupName,
				b.ProductID As ProductID,
				b.JobName, 
				b.LastUser, 
				b.TestCenterLocationID,
				l3.[Values] As TestCenterLocation,
				b.ConcurrencyID,
				b.TestStageCompletionStatus, j.WILocation,b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, 
				b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, MechanicalTools, l4.[Values] As RequestPurpose, l5.[Values] As Priority, b.DepartmentID, l6.[Values] AS Department,
				b.Requestor
			FROM Batches AS b WITH(NOLOCK)
				LEFT OUTER JOIN Jobs as j WITH(NOLOCK) on b.jobname = j.JobName 
				inner join TestStages as ts WITH(NOLOCK) on j.ID = ts.JobID
				inner join Tests as t WITH(NOLOCK) on ts.TestID = t.ID
				inner join DeviceTrackingLog AS dtl WITH(NOLOCK) 
				INNER JOIN TrackingLocations AS tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.ID
				INNER JOIN TrackingLocationTypes as tlt WITH(NOLOCK) on tl.TrackingLocationTypeID = tlt.id 
				inner join TestUnits AS tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID on tu.CurrentTestName = t.TestName and b.id = tu.batchid  --batches where there's a tracking log
				INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=b.ProductID
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON b.TestCenterLocationID=l3.LookupID  
				LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON b.RequestPurpose=l4.LookupID   
				LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON b.Priority=l5.LookupID
				LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON b.DepartmentID=l6.LookupID
			WHERE (b.TestCenterLocationID = @TestCentreLocation or @TestCentreLocation is null) and j.TechnicalOperationsTest = 1 and j.MechanicalTest=0 and  tlt.TrackingLocationFunction= 4  and t.ResultBasedOntime = 1 AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL
			AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ud.LookupID FROM UserDetails ud WITH(NOLOCK) WHERE UserID=@UserID)))
		)as b
	) as batchesrows
 	WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex = -1 OR @maximumRows = -1) 
GO
GRANT EXECUTE ON remispBatchesSelectChamberBatches TO Remi
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
	BatchesRows.LastUser,BatchesRows.Priority AS PriorityID,lp.[Values] AS ProductGroupName,BatchesRows.QRANumber,BatchesRows.RequestPurpose As RequestPurposeID,batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,
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
	BatchesRows.DepartmentID, l6.[Values] AS Department, BatchesRows.Requestor
	from Batches as BatchesRows WITH(NOLOCK)
		LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = BatchesRows.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
		INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=BatchesRows.productID
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
GRANT EXECUTE ON remispBatchesSelectByQRANumber TO Remi
Go
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
		BatchesRows.RequestPurposeID, BatchesRows.PriorityID, DepartmentID, Department, Requestor
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
				b.BatchStatus,b.Comment,
				b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority AS PriorityID,lp.[Values] AS ProductGroupName,b.ProductTypeID, b.AccessoryGroupID,b.ProductID As ProductID,b.QRANumber,
				b.RequestPurpose AS RequestPurposeID,b.TestCenterLocationID,b.TestStageName, j.WILocation,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, b.RQID, l3.[Values] As TestCenterLocation,
				b.AssemblyNumber, b.AssemblyRevision, b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, 
				ExecutiveSummary, MechanicalTools, l4.[Values] As RequestPurpose, l5.[Values] As Priority, b.DepartmentID, l6.[Values] AS Department, b.Requestor
			FROM Batches as b
				INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=b.ProductID
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
GRANT EXECUTE ON remispBatchesGetActiveBatchesByRequestor TO REMI
GO
ALTER PROCEDURE [dbo].[remispBatchesGetActiveBatches]
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
		ReportRequiredBy, ReportApprovedDate, IsMQual, JobID, ExecutiveSummary, MechanicalTools, BatchesRows.RequestPurposeID, BatchesRows.PriorityID, DepartmentID, Department, Requestor
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
			b.BatchStatus,b.Comment, b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority As PriorityID,lp.[Values] AS ProductGroupName,b.ProductTypeID,b.AccessoryGroupID,b.ProductID as ProductID,
			b.QRANumber, b.RequestPurpose As RequestPurposeID,b.TestCenterLocationID,b.TestStageName, j.WILocation,
			(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
			l2.[Values] As AccessoryGroupName, l.[Values] As ProductType,b.RQID,l3.[Values] As TestCenterLocation,
			b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, ExecutiveSummary, 
			MechanicalTools, l4.[Values] As RequestPurpose, l5.[Values] As Priority, b.DepartmentID, l6.[Values] AS Department, b.Requestor
			FROM Batches as b WITH(NOLOCK)
				INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=b.ProductID
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
GRANT EXECUTE ON remispBatchesGetActiveBatches TO Remi
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
	@DepartmentID INT = NULL,
	@OnlyHasResults INT = NULL,
	@JobID int = 0
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
		MechanicalTools, BatchesRows.RequestPurpose, BatchesRows.PriorityID, DepartmentID, Department, Requestor
	FROM     
		(
			SELECT DISTINCT b.BatchStatus,b.Comment, b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority AS PriorityID,b.ProductTypeID,
				b.AccessoryGroupID,b.ProductID As ProductID,lp.[Values] As ProductGroup,b.QRANumber,b.RequestPurpose As RequestPurposeID,b.TestCenterLocationID,b.TestStageName,
				j.WILocation,(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, l3.[Values] As TestCenterLocation,
				b.CPRNumber,b.RelabJobID, b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, 
				b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, b.DateCreated, j.ContinueOnFailures, MechanicalTools, l4.[Values] As RequestPurpose, l5.[Values] As Priority, 
				ISNULL(b.[Order], 100) As PriorityOrder, b.DepartmentID, l6.[Values] AS Department, b.Requestor
			FROM Batches as b WITH(NOLOCK)
				INNER JOIN Lookups p WITH(NOLOCK) ON p.LookupID=b.ProductID
				INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
				LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON b.TestCenterLocationID=l3.LookupID
				INNER JOIN TestStages ts WITH(NOLOCK) ON ts.TestStageName=b.TestStageName
				LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON b.RequestPurpose=l4.LookupID
				LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON b.Priority=l5.LookupID
				LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON b.DepartmentID=l6.LookupID
			WHERE ((BatchStatus NOT IN (SELECT ID FROM #ExBatchStatus) OR @ExcludedStatus IS NULL) AND (BatchStatus = @Status OR @Status IS NULL))
				AND (p.LookupID = @ProductID OR @ProductID IS NULL)
				AND (b.Priority = @Priority OR @Priority IS NULL)
				AND (b.ProductTypeID = @ProductTypeID OR @ProductTypeID IS NULL)
				AND (b.AccessoryGroupID = @AccessoryGroupID OR @AccessoryGroupID IS NULL)
				AND (b.TestCenterLocationID = @GeoLocationID OR @GeoLocationID IS NULL)
				AND (b.DepartmentID = @DepartmentID OR @DepartmentID IS NULL)
				AND 
				(
					(@JobID > 0 AND j.ID=@JobID)
					OR
					(@JobName IS NOT NULL AND b.JobName = @JobName)
					OR
					(@JobName IS NULL AND @JobID = 0)
				)
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
						FROM TrackingLocations tl WITH(NOLOCK)
							INNER JOIN devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID AND dtl.OutTime IS NULL
							INNER JOIN TestUnits tu WITH(NOLOCK) on tu.ID=dtl.TestUnitID
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
						FROM TrackingLocations tl WITH(NOLOCK)
							INNER JOIN devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID AND dtl.OutTime IS NULL
							INNER JOIN TestUnits tu WITH(NOLOCK) on tu.ID=dtl.TestUnitID
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
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.LookupID IN (SELECT ud.LookupID FROM UserDetails ud WITH(NOLOCK) WHERE UserID=@ExecutingUserID)))
				AND
				(
					(@OnlyHasResults IS NULL OR @OnlyHasResults = 0)
					OR
					(@OnlyHasResults = 1 AND EXISTS(SELECT 1 FROM TestUnits tu WITH(NOLOCK) INNER JOIN Relab.Results r ON r.TestUnitID=tu.ID WHERE tu.BatchID=b.ID))
				)
		)AS BatchesRows		
	ORDER BY BatchesRows.PriorityOrder ASC, BatchesRows.QRANumber DESC
	
	DROP TABLE #ExTestStageType
	DROP TABLE #ExBatchStatus
	RETURN
GO
GRANT EXECUTE ON remispBatchesSearch TO Remi
GO
ALTER procedure [dbo].[remispUsersSearch] @ProductID INT = 0, @TestCenterID INT = 0, @TrainingID INT = 0, @TrainingLevelID INT = 0, @ByPass INT = 0, @showAllGrid BIT = 0, @UserID INT = 0, @DepartmentID INT = 0, @DetermineDelete INT = 1,  @IncludeInActive INT = 1
AS
BEGIN	
	IF (@showAllGrid = 0)
	BEGIN
		SELECT ID, LDAPLogin, BadgeNumber, ByPassProduct, DefaultPage, ISNULL(IsActive, 1) AS IsActive, LastUser, 
				ConcurrencyID, CASE WHEN @DetermineDelete = 1 THEN dbo.remifnUserCanDelete(LDAPLogin) ELSE 0 END AS CanDelete
		FROM 
			(SELECT DISTINCT u.ID, u.LDAPLogin, u.BadgeNumber, u.ByPassProduct, u.DefaultPage, ISNULL(u.IsActive, 1) AS IsActive, u.LastUser, 
				u.ConcurrencyID
			 FROM Users u
				LEFT OUTER JOIN UserTraining ut ON ut.UserID = u.ID
				INNER JOIN UserDetails udtc ON udtc.UserID=u.ID
				INNER JOIN UserDetails udd ON udd.UserID=u.ID
				LEFT OUTER JOIN UserDetails udp ON udp.UserID=u.ID
				LEFT OUTER JOIN Lookups p ON p.LookupID=udp.LookupID
			WHERE (
					(@IncludeInActive = 0 AND ISNULL(u.IsActive, 1)=1)
					OR
					@IncludeInActive = 1
				  )
				  AND 
				  (
					(udtc.LookupID=@TestCenterID) 
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
					(p.LookupID=@ProductID) 
					OR
					(@ProductID = 0)
				  )
				  AND 
				  (
					(udd.LookupID=@DepartmentID) 
					OR
					(@DepartmentID = 0)
				  )
			) AS UsersRows
			ORDER BY LDAPLogin
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
					INNER JOIN UserDetails ud ON ud.UserID=u.ID
				WHERE u.IsActive = 1 AND (
				(ud.lookupid=' + CONVERT(VARCHAR, @TestCenterID) + ') 
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
GRANT EXECUTE ON remispUsersSearch TO REMI
GO
ALTER procedure [dbo].[remispExceptionSearch] @AccessoryGroupID INT = 0, @ProductTypeID INT = 0, @TestID INT = 0, @TestStageID INT = 0, @JobName NVARCHAR(400) = NULL, 
	@IncludeBatches INT = 0, @RequestReason INT = 0, @TestCenterID INT = 0, @IsMQual INT = 0, @QRANumber NVARCHAR(11) = NULL
AS
BEGIN
	DECLARE @JobID INT
	SELECT @JobID = ID FROM Jobs WITH(NOLOCK) WHERE JobName=@JobName

	select row,ID,QRANumber, BatchUnitNumber, ReasonForRequestID, ProductGroupName, JobName, TestStageName, TestName, TestStageID, TestUnitID, LastUser, ProductTypeID, AccessoryGroupID, 
		ProductID, ProductType, AccessoryGroupName, IsMQual, TestCenter, TestCenterID, ReasonForRequest, TestID
	from 
	(
		select ROW_NUMBER() over (order by p.[values] desc)as row, pvt.ID, b.QRANumber, ISNULL(tu.Batchunitnumber, 0) as batchunitnumber, pvt.[ReasonForRequest] As ReasonForRequestID, p.[Values] AS ProductGroupName, 
		(select jobname from jobs,TestStages where teststages.id =pvt.TestStageid and Jobs.ID = TestStages.jobid) as jobname, 
		(select teststagename from teststages WITH(NOLOCK) where teststages.id =pvt.TestStageid) as teststagename, 
		t.TestName,pvt.TestStageID, pvt.TestUnitID,
		(select top 1 LastUser from TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
		(select top 1 ConcurrencyID from TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS ConcurrencyID,
		pvt.ProductTypeID, pvt.AccessoryGroupID, b.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, pvt.IsMQual, 
		l3.[Values] As TestCenter, l3.[LookupID] AS TestCenterID, l4.[Values] As ReasonForRequest, t.ID AS TestID
		FROM vw_ExceptionsPivoted as pvt WITH(NOLOCK)
			LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
			LEFT OUTER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = pvt.TestUnitID
			LEFT OUTER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
			LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.LookupID=pvt.ProductTypeID
			LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.LookupID=pvt.AccessoryGroupID
			LEFT OUTER JOIN Lookups p WITH(NOLOCK) on p.LookupID=b.ProductID
			LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.LookupID=pvt.TestCenterID
			LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON l4.LookupID=pvt.ReasonForRequest
		WHERE 
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
GRANT EXECUTE ON remispExceptionSearch TO REMI
GO
ALTER VIEW [dbo].[vw_ExceptionsPivoted]
AS
SELECT pvt.ID, pvt.[2] AS ReasonForRequest, pvt.[3] AS TestUnitID, pvt.[4] AS TestStageID, pvt.[5] AS Test, pvt.[6] AS ProductTypeID, pvt.[7] AS AccessoryGroupID,
	pvt.[3516] AS TestCenterID, pvt.[3517] As IsMQual
FROM 
(SELECT ID, Value, TestExceptions.LookupID as Look
FROM TestExceptions) te
PIVOT (MAX(Value) FOR Look IN ([2],[3],[4],[5],[6],[7],[3516],[3517])) as pvt
GO
ALTER procedure remispCountUnitsInLocation @startDate datetime, @endDate datetime, @geoGraphicalLocation int, @FilterBasedOnQraNumber bit, @LookupID INT
AS
BEGIN
	DECLARE @startYear int = Right(year( @StartDate), 2);
	DECLARE @endYear int = Right(year( @EndDate), 2);

	IF @geoGraphicalLocation = 0
		SET @geoGraphicalLocation = NULL

	SELECT tl.TrackingLocationName, count(tu.id) as CountedUnits 
	FROM TestUnits tu WITH(NOLOCK), trackinglocations tl WITH(NOLOCK), DeviceTrackingLog dtl WITH(NOLOCK), Batches b WITH(NOLOCK)
	WHERE tu.ID = dtl.TestUnitID AND dtl.TrackingLocationID = tl.ID AND dtl.OutUser IS NULL AND tu.BatchID = b.id
		AND dtl.InTime > @StartDate AND dtl.InTime < @EndDate 
		AND (@FilterBasedOnQraNumber = 0 OR (Convert(int , SUBSTRING(b.QRANumber, 5, 2)) >= @startYear
		AND Convert(int , SUBSTRING(b.QRANumber, 5, 2)) <= @endYear))
		AND (b.ProductID = @LookupID OR @LookupID = 0)
		AND (b.TestCenterLocationID = @geoGraphicalLocation OR @geoGraphicalLocation IS NULL) 
	GROUP BY TrackingLocationName 
	UNION ALL
	SELECT 'Total', count(tu.id) AS CountedUnits 
	FROM TestUnits tu, trackinglocations tl, DeviceTrackingLog dtl, Batches b
	WHERE tu.ID = dtl.TestUnitID AND dtl.TrackingLocationID = tl.ID AND dtl.OutUser IS NULL AND tu.BatchID = b.id
		AND dtl.InTime > @StartDate AND dtl.InTime < @EndDate 
		AND (@FilterBasedOnQraNumber = 0 or (Convert(int , SUBSTRING(b.QRANumber, 5, 2)) >= @startYear
		AND Convert(INT, SUBSTRING(b.QRANumber, 5, 2)) <= @endYear))
		AND (b.ProductID = @LookupID or @LookupID = 0)
		AND (b.TestCenterLocationID  = @geoGraphicalLocation OR @geoGraphicalLocation IS NULL)
	order by TrackingLocationName ASC
END
GO
GRANT EXECUTE On remispCountUnitsInLocation TO Remi
GO
ALTER PROCEDURE [dbo].[remispScanGetData]
	@qranumber nvarchar(11),
	@unitnumber int,
	@Hostname nvarchar(255)=  null,
	@selectedTrackingLocationID int = null,
	@selectedTestName nvarchar(300)=null,
	@selectedTestStageName nvarchar(300)=null,
	@trackingLocationName nvarchar(255) = null
AS
declare @jobName nvarchar(400)
declare @jobID int
declare @testUnitID int
declare @lookupID int
declare @BSN bigint
declare @selectedTLCapacityRemaining int
declare @currentTest nvarchar(300)
declare @currentTestStage nvarchar(300)
declare @currentTestRecordStatus int
declare @currentTestRecordID int
declare @currentTestID int
declare @currentTestRequiredTestTime float
declare @currentTestTotalTestTime float
declare @currentTestIsTimed bit
declare @currentTestType int
declare @batchStatus int
declare @inFA bit
declare @inQuarantine bit
declare @productGroup nvarchar(400)
declare @jobWILocation nvarchar(400)
declare @selectedTestWI nvarchar(400)
declare @ApplicableTestStages nvarchar(1000)=''
declare @ApplicableTests nvarchar(1000)=''
declare @selectedTestRequiredTestTime float
declare @selectedTestStageIsValid bit
declare @selectedTestIsValid bit
declare @selectedTestIsMarkedDoNotProcess bit
declare @selectedTestRecordStatus int
declare @selectedTestType int
declare @selectedTestIsValidForLocation bit
declare @selectedTestIsTimed bit
declare @selectedTestStageID int
declare @selectedTestID int
declare @selectedTestRecordID int
declare @selectedTestTotalTestTime float
declare @selectedTrackingLocationName nvarchar(400)
declare @selectedLocationNumberOfScans int
declare @selectedTrackinglocationCurrentTestName nvarchar(300)
declare @selectedTrackingLocationWILocation nvarchar(400)
declare @selectedTrackingLocationFunction int
declare @cprNumber nvarchar(500)
declare @hwrevision nvarchar(500)
declare @batchSpecificDuration float 
declare @exceptionsTable table(name nvarchar(300), TestUnitException nvarchar(50))
declare @currentDtlID int, @currentDtlInTime datetime, @currentDtlOutTime datetime, @currentDtlInUser nvarchar(255),
 @currentDtlOutUser nvarchar(255), @currentDtlTrackingLocationName nvarchar(400), @currentDtlTrackingLocationID int
declare @isBBX nvarchar(200)
declare @accessoryTypeID INT
declare @productTypeID INT
declare @accessoryType NVARCHAR(150)
declare @productType NVARCHAR(150)
Declare @NoBSN BIT
DECLARE @DepartmentID INT
DECLARE @BatchID INT

--jobname, product group, job WI, jobID
select @BatchID=b.ID,@jobName=b.jobname,@cprNumber =b.CPRNumber,@hwrevision = b.HWRevision, @productGroup=lp.[Values],@jobWILocation=j.WILocation,@jobid=j.ID, @batchStatus = b.BatchStatus ,
@NoBSN=j.NoBSN, @productTypeID=b.ProductTypeID, @accessoryTypeID=b.AccessoryGroupID, @DepartmentID = DepartmentID,
@lookupID = b.ProductID
from Batches as b
	INNER JOIN jobs as j ON j.JobName = b.JobName
	INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=b.ProductID
where b.QRANumber = @qranumber

SELECT @productType=[values] FROM Lookups WHERE LookupID=@productTypeID
SELECT @accessoryType=[values] FROM Lookups WHERE LookupID=@accessoryTypeID

--*******************
---This section gets the IsBBX value as a bit
declare @IsBBXvaluetext nvarchar(200) = (select ValueText FROM ProductSettings as ps where ps.LookupID = @lookupID and KeyName = 'IsBBX')
declare @IsBBXDefaultvaluetext nvarchar(200) =(select top (1) DefaultValue FROM ProductSettings as ps where KeyName = 'IsBBX' and DefaultValue is not null)
set @isBBX = case when @IsBBXvaluetext is not null then @IsBBXvaluetext else @IsBBXDefaultvaluetext end;

--tracking location wi
select TOP 1 @selectedTrackingLocationID = tl.ID, @selectedTrackingLocationWILocation=tlt.WILocation,@selectedTrackingLocationName = TrackingLocationName,@selectedTrackingLocationFunction = tlt.TrackingLocationFunction 
from TrackingLocations as tl
	INNER JOIN TrackingLocationTypes as tlt ON tlt.ID = tl.TrackingLocationTypeID
	LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
where (@selectedTrackingLocationID IS NULL AND tlh.HostName = @Hostname and @HostName is not null AND 
		((tl.TrackingLocationname= @trackingLocationName AND @trackingLocationName IS NOT NULL) OR @trackingLocationName IS NULL)
	  )
	OR
	(@selectedTrackingLocationID IS NOT NULL AND tl.ID = @selectedTrackingLocationID)


-- tracking location current test name
set @selectedTrackinglocationCurrentTestName = (SELECT top(1) tu.CurrentTestName as CurrentTestName
		                    FROM TestUnits AS tu, DeviceTrackingLog AS dtl 
		             where tu.ID = dtl.TestUnitID and tu.CurrentTestName is not null and dtl.TrackingLocationID = @selectedTrackingLocationID and (dtl.OutUser IS NULL))
--test unit id, bsncurrent test/test stage

(select @testUnitID=tu.id,@bsn = tu.BSN,@currentTest=tu.CurrentTestName,@currentTeststage=tu.CurrentTestStageName from testunits as tu, Batches as b 
	where tu.BatchID = b.ID and b.QRANumber = @qranumber and tu.BatchUnitNumber = @unitnumber)

--teststage id

select @selectedTestStageID = ts.id 
from teststages as ts
where ts.JobID = @jobID and ts.TestStageName = @selectedTestStageName

--selected test details

SELECT  @selectedTestID=t.ID, @selectedTestIsTimed =t.resultbasedontime,@selectedTestType = t.TestType, @selectedTestWI = t.WILocation
from Tests AS t, TestStages as ts
WHERE ts.ID = @selectedTestStageID  
and (
		(ts.TestStagetype = 2 and t.TestName=ts.teststagename and t.TestName = @selectedTestName and t.id = ts.TestID) --if its an env teststage get the equivelant test
		or (ts.teststagetype = 1 and t.testtype = 1 and t.TestName = @selectedTestName)--otherwise if its a para test stage get the para test
		or (ts.teststagetype = 3 and t.testtype = 3 and t.TestName = @selectedTestName) --or the incoming eval test
	)
--current test details

SELECT  @currentTestID=t.ID, @currentTestIsTimed =t.resultbasedontime,@currentTestType = t.TestType 
from Tests AS t, TestStages as ts 
WHERE ts.TestStageName = @currentTestStage
and ts.JobID = @jobid
and (
		(ts.TestStagetype = 2 and t.TestName=ts.teststagename and t.TestName = @currentTest and t.id = ts.TestID) --if its an env teststage get the equivelant test
		or (ts.teststagetype = 1 and t.testtype = 1 and t.TestName = @currentTest)--otherwise if its a para test stage get the para test
		or (ts.teststagetype = 3 and t.testtype = 3 and t.TestName = @currentTest) --or the incoming eval test
	)
--selected test record id

select @selectedTestRecordID = Tr.id, @selectedTestRecordStatus = tr.Status
from TestRecords as tr 
where tr.JobName = @jobName and tr.TestStageName = @selectedTestStageName and tr.TestName = @selectedTestName and tr.TestUnitID = @testUnitID

--OLD test record id

select @currentTestRecordID = Tr.id, @currentTestRecordStatus = tr.Status 
from TestRecords as tr
where tr.JobName = @jobName and tr.TestStageName = @currentTestStage and tr.TestName = @currentTest and tr.TestUnitID = @testUnitID

--time info. adjusted to select the selected test batch specific duration if applicable
set @batchSpecificDuration = (select Duration from BatchSpecificTestDurations, Batches where TestID = @selectedTestID and BatchID = Batches.ID and Batches.QRANumber = @qranumber)
set @selectedTestRequiredTestTime = case when @batchSpecificDuration is not null then @batchSpecificDuration else (select Tests.Duration from Tests where ID = @selectedTestID) end

--now select the currentTest test duration
set @batchSpecificDuration = (select Duration from BatchSpecificTestDurations, Batches where TestID = @currentTestID and BatchID = Batches.ID and Batches.QRANumber = @qranumber)
set @currentTestRequiredTestTime = case when @batchSpecificDuration is not null then @batchSpecificDuration else (select Tests.Duration from Tests where ID = @currentTestID) end

set @selectedTestTotalTestTime = (Select sum(datediff(MINUTE,dtl.intime,
(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end ))) 
	 from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl 
	 where trXtl.TestRecordID = @selectedTestRecordID and dtl.ID = trXtl.TrackingLogID)
	 
set @currentTestTotalTestTime = (Select sum(datediff(MINUTE,dtl.intime,
(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end ))) 
	 from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl 
	 where trXtl.TestRecordID = @currentTestRecordID and dtl.ID = trXtl.TrackingLogID)
	 
--tlcapacity
set @selectedTLCapacityRemaining = (select tlt.UnitCapacity - (SELECT COUNT(dtl.ID)--currentcount
		                    FROM  DeviceTrackingLog AS dtl
		                                          where 
		                                           dtl.TrackingLocationID = @selectedTrackingLocationID
		                                          and (dtl.OutUser IS NULL))
		                                          
		                                          from TrackingLocations as tl, TrackingLocationTypes as tlt
		                                          where tl.id = @selectedTrackingLocationID
		                                          and tlt.ID = tl.TrackingLocationTypeID)
--teststage is valid
set @selectedTestStageIsValid = (case when (@selectedTestStageID IS NULL) then 0 else 1 end)

--testisvalid
set @selectedTestIsValid = (case when (@selectedTestID IS NULL) then 0 else 1 end)

-- is dnp'd
insert @exceptionsTable exec remispTestExceptionsGetTestUnitTable @qranumber, @unitnumber, @selectedTestStageName  
set @selectedTestIsMarkedDoNotProcess = (select (case when (TestUnitException = 'True') then 1 else 0 end) from @exceptionstable where name = @selectedTestName)

-- is in FA
set @inFA = case when (select COUNT (*) from TestRecords as tr where TestUnitID = @testUnitID and (tr.Status = 3 or tr.Status = 10 or tr.Status = 11)) > 0 then 1 else 0 end --status is FARaised

-- is in Quarantine
set @inQuarantine = case when (select COUNT (*) from TestRecords as tr where TestUnitID = @testUnitID and tr.Status = 9)>0 then 1 else 0 end --status is Quarantine


--number of scans
set @selectedLocationNumberOfScans = (select COUNT (*) from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl where trXtl.TestRecordID = @selectedTestRecordID and dtl.ID = trXtl.TrackingLogID)
--test valid for tracking location
set @selectedTestIsValidForLocation = case when (select 1 from Tests as t, TrackingLocations as tl, trackinglocationtypes as tlt, TrackingLocationsForTests as tltfort 
where tlt.ID = tltfort.TrackingLocationtypeID and t.ID = tltfort.TestID and t.ID = @selectedTestID and tlt.ID = tl.TrackingLocationTypeID and tl.ID = @selectedTrackingLocationID) IS not null then 1 else 0 end

IF EXISTS (SELECT 1 FROM Req.RequestSetup WHERE BatchID=@BatchID)
BEGIN
	CREATE TABLE #Setup (TestStageID INT, TestStageName NVARCHAR(255), TestID INT, TestName NVARCHAR(255), Selected BIT)
	INSERT INTO #Setup
	EXEC Req.GetRequestSetupInfo @lookupID, @jobID, @BatchID, 1, 0, '', 0
	INSERT INTO #Setup
	EXEC Req.GetRequestSetupInfo @lookupID, @jobID, @BatchID, 2, 0, '', 0
	
	SELECT @ApplicableTestStages = @ApplicableTestStages + ',' + a.TestStageName
	FROM (
	SELECT DISTINCT s.TestStageName, ts.ProcessOrder
	FROM #Setup s
		INNER JOIN TestStages ts ON ts.ID = s.TestStageID
	) a
	ORDER BY a.ProcessOrder
	DROP TABLE #Setup
END
ELSE
BEGIN
	SELECT @ApplicableTestStages = @ApplicableTestStages + ','  + TestStageName 
	FROM TestStages ts
	WHERE ISNULL(ts.IsArchived, 0)=0 AND ts.TestStageType NOT IN (4,5,0) AND ts.JobID = @jobID 
	ORDER BY ProcessOrder
END

--get applicable tests
SELECT test.TestName, test.ProcessOrder
INTO #tests
FROM (
SELECT t.TestName, ts.ProcessOrder
FROM Tests t
	INNER JOIN TrackingLocationsForTests tlft ON t.ID = tlft.TestID
	INNER JOIN TrackingLocationTypes tlt ON tlt.ID = tlft.TrackingLocationtypeID
	INNER JOIN TrackingLocations tl ON tl.TrackingLocationTypeID = tlt.ID
	INNER JOIN TestStages ts ON ts.TestID = t.ID AND ts.JobID=@jobID AND t.TestType NOT IN (1, 3)
WHERE ISNULL(t.IsArchived, 0)=0 AND tl.ID = @selectedTrackingLocationID
UNION
SELECT t2.TestName, 0 AS ProcessOrder
FROM Tests t2
	INNER JOIN TrackingLocationsForTests tlft ON t2.ID = tlft.TestID
	INNER JOIN TrackingLocationTypes tlt ON tlt.ID = tlft.TrackingLocationtypeID
	INNER JOIN TrackingLocations tl ON tl.TrackingLocationTypeID = tlt.ID
	INNER JOIN TestsAccess ta ON ta.TestID=t2.id AND ta.LookupID IN (@DepartmentID)
WHERE ISNULL(t2.IsArchived, 0)=0 AND tl.ID = @selectedTrackingLocationID AND t2.TestType IN (1, 3)
) test
ORDER BY test.ProcessOrder

SELECT @ApplicableTests = @ApplicableTests + ','  + TestName FROM #tests
DROP TABLE #tests

set @ApplicableTestStages = SUBSTRING(@ApplicableTestStages,2,Len(@ApplicableTestStages))
set @ApplicableTests = SUBSTRING(@ApplicableTests,2,Len(@ApplicableTests))

----------------------------
---  Tracking Log Params ---
----------------------------
 
 select top(1) @currentDtlID=dtl.id,
 	@currentDtlInTime =InTime, 
 	@currentDtlOutTime=OutTime,
	@currentDtlInUser=InUser, 
	@currentDtlOutUser =OutUser,
	@currentDtlTrackingLocationName=trackinglocationname , 
	@currentDtlTrackingLocationID=tl.ID
	FROM DeviceTrackingLog as dtl, TrackingLocations as tl
	WHERE (dtl.TestUnitID = @testUnitID and tl.ID = dtl.TrackingLocationID)
	order by dtl.intime desc

----------------------
--  RETURN DATA ------
----------------------
select @currentDtlID as currentDtlID,
	@testUnitID as testunitID,
 	@currentDtlInTime as currentDtlInTime, 
 	@currentDtlOutTime as currentDtlOutTime,
	@currentDtlInUser as currentDtlInUser,
	@currentDtlOutUser as currentDtlOutUser,
	@currentDtlTrackingLocationName as currentDtlTrackingLocationName, 
	@currentDtlTrackingLocationID as currentDtlTrackingLocationID,		
	@currentTeststage as currentTestStage,
	@currentTest as currentTest,
	@currentTestRecordStatus as currentTestRecordStatus,
	@currentTestRecordID as currentTestRecordID,
	@currentTestRequiredTestTime as currentTestRequiredTestTime,
	@currentTestTotalTestTime as currentTestTotalTestTime,
	@currentTestIsTimed as currenttestIsTimed,
	@currentTestType as currenttestType,	
	@batchStatus as batchStatus,
	@inFA as inFA,	
    @productGroup as productGroup,
	@jobWILocation as jobWILocation,		
	@jobName as jobName,
	@BSN as bsn,	
	@isBBX as isBBX,	
	@selectedTLCapacityRemaining as selectedTLCapacityRemaining,
	@selectedTrackingLocationName as selectedTrackingLocationName,
	@selectedTrackingLocationID as selectedTrackingLocationID,
	@selectedTestStageIsValid as selectedTestStageIsValid,
	@selectedTestIsValid as selectedTestIsValid,
	@selectedTestIsMarkedDoNotProcess as selectedTestIsMarkedDoNotProcess,
	@selectedTestType as selectedTestType, 
	@selectedTrackinglocationCurrentTestName as selectedTrackinglocationCurrentTestName,
	@selectedTestRecordStatus as selectedTestRecordStatus,
	@selectedTrackingLocationWILocation as selectedTrackingLocationWILocation ,
	@selectedTrackingLocationFunction as selectedTrackingLocationFunction,
	@selectedTestRecordID as selectedTestRecordID,
	@selectedTestIsValidForLocation as selectedTestIsValidForLocation,
	@selectedTestIsTimed as selectedTestIsTimed,
	@selectedLocationNumberOfScans as selectedLocationNumberOfScans,	
	@selectedTestRequiredTestTime as selectedTestRequiredTestTime,
	@selectedTestTotalTestTime as selectedTestTotalTestTime,		
	@cprNumber as CPRNumber,
	@hwrevision as HWRevision,		
	@ApplicableTestStages as ApplicableTestStages, 
	@ApplicableTests as ApplicableTests,
	@selectedTestID as selectedTestID,
	@lookupID As ProductID,
	@selectedTestWI AS selectedTestWILocation, @NoBSN AS NoBSN, @productType AS ProductType, @productTypeID AS ProductTypeID, @accessoryType AS AccessoryType, @accessoryTypeID AS AccessoryTypeID
	
	exec remispTrackingLocationsSelectForTest @selectedTestID, @selectedTrackingLocationID
	 
IF (@@ERROR != 0)
	BEGIN
		RETURN -3
	END
	ELSE
	BEGIN
		RETURN 0
	END
GO
GRANT EXECUTE ON remispScanGetData TO REMI
GO
ALTER PROCEDURE [dbo].[remispTestExceptionsGetTestUnitTable]
/*	'===============================================================
	'   NAME:                	remispTestExceptionsGetTestUnitTable
	'   DATE CREATED:       	09 Oct 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves a list of test names / boolean
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
	@QRANumber nvarchar(11) = null,
	@BatchunitNumber int = null,
	@TestStageName nvarchar(400) = null,
	@TestStageID INT = NULL
AS
	declare @testunitid int
	declare @TestStageType int
		
	--get the test unit id
	if @QRANumber is not null and @BatchUnitNumber is not null
	begin
		set @testUnitID = (select tu.Id from TestUnits tu WITH(NOLOCK) INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID where b.QRANumber = @QRANumber AND tu.batchunitnumber = @Batchunitnumber)
		PRINT 'TestUnitID: ' + CONVERT(NVARCHAR, ISNULL(@testUnitID,''))
	end
		
	if (@TestStageID is null and @TestStageName is not null)
	begin
		set @TestStageID = (select ts.ID from Teststages as ts,jobs as j, Batches as b, TestUnits as tu
		where ts.TestStageName = @TestStageName and ts.JobID = j.id 
			and j.jobname = b.jobname 
			and tu.ID = @testunitid
			and b.ID = tu.BatchID)
	END

	PRINT 'TestStageID: ' + CONVERT(NVARCHAR, ISNULL(@TestStageID,''))

	--set up the required tables
	declare @testUnitExemptions table (exTestName nvarchar(255))

	insert into @testunitexemptions
	SELECT DISTINCT TestName
	FROM vw_ExceptionsPivoted as pvt
		INNER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	where (
			(pvt.TestUnitID = @TestUnitID) 
			or 
			(pvt.TestUnitID is null)
		  ) and( pvt.TestStageID = @TestStageID or @TestStageID is null)

	SELECT TestName AS Name, (CASE WHEN (SELECT exTestName FROM @testUnitExemptions WHERE exTestName = t.TestName) IS NOT NULL THEN 'True' ELSE 'False' END ) AS TestUnitException
	FROM Tests t WITH(NOLOCK), teststages ts WITH(NOLOCK)
	WHERE --where teststage type is environmental, the test name and test stage id's match
	ts.id = @TeststageID  and ((ts.TestStageType = 2  and ts.TestID = t.id) or
	--test stage type = incoming eval and test type is parametric
	( ts.TestStageType = 3 and t.testtype = 3) or
	--OR where test stage type is parametric and test type is also parametric (ie get all the measurment tests)
	(( ts.TeststageType = 1 ) and t.TestType = 1))
	ORDER BY TestName
GO
GRANT EXECUTE On remispTestExceptionsGetTestUnitTable TO Remi
GO

ALTER PROCEDURE remispGetLookups @Type NVARCHAR(150), @ProductID INT = NULL, @ParentID INT = NULL, @ParentLookupType NVARCHAR(150) = NULL, 
	@ParentLookup NVARCHAR(150) = NULL, @RequestTypeID INT = NULL, @ShowAdminSelected BIT = 0, @ShowArchived BIT = 0,
	@UserID INT = 0
AS
BEGIN
	DECLARE @ByPassSecureCheck BIT
	DECLARE @LookupTypeID INT
	DECLARE @IsSecureType BIT
	DECLARE @ParentLookupTypeID INT
	DECLARE @HierarchyExists BIT
	DECLARE @ParentLookupID INT
	
	SELECT @ByPassSecureCheck = ByPassProduct FROM Users u WHERE u.ID=@UserID
	SELECT @LookupTypeID = LookupTypeID, @IsSecureType = IsSecureType FROM LookupType WHERE Name=@Type
	SELECT @ParentLookupTypeID = LookupTypeID FROM LookupType WHERE Name=@ParentLookupType
	SELECT @ParentLookupID = LookupID FROM Lookups WHERE LookupTypeID=@ParentLookupTypeID AND Lookups.[Values]=@ParentLookup
	SET @HierarchyExists = CONVERT(BIT, 0)
	
	SET @HierarchyExists = ISNULL((SELECT TOP 1 CONVERT(BIT, 1) 
	FROM LookupsHierarchy lh
	WHERE lh.ParentLookupTypeID=@ParentLookupTypeID AND lh.ChildLookupTypeID=@LookupTypeID
		AND lh.ParentLookupID=@ParentLookupID AND lh.RequestTypeID=@RequestTypeID), CONVERT(BIT, 0))
	
	DECLARE @NotSetSelected BIT
	SET @NotSetSelected = CONVERT(BIT, 0)
	
	IF EXISTS (SELECT 1 FROM LookupsHierarchy lh WHERE lh.ParentLookupTypeID=@ParentLookupTypeID AND lh.ChildLookupTypeID=@LookupTypeID AND lh.ParentLookupID=@ParentLookupID AND lh.RequestTypeID=@RequestTypeID AND lh.ChildLookupID=0)
		SET @NotSetSelected = CONVERT(BIT, 1)	

	SELECT l.LookupID, @Type AS [Type], l.[Values] As LookupType, CASE WHEN pl.ID IS NOT NULL THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END As HasAccess, 
		l.Description, ISNULL(l.ParentID, 0) AS ParentID, p.[Values] AS Parent, CASE WHEN lh.ChildLookupID =l.LookupID THEN 1 ELSE 0 END AS RequestAssigned, l.IsActive
	INTO #type
	FROM Lookups l
		LEFT OUTER JOIN ProductLookups pl ON pl.ProductID=@ProductID AND l.LookupID=pl.LookupID
		LEFT OUTER JOIN Lookups p ON p.LookupID=l.ParentID
		LEFT OUTER JOIN LookupsHierarchy lh ON lh.ParentLookupTypeID=@ParentLookupTypeID AND lh.ChildLookupTypeID=@LookupTypeID
			AND lh.ParentLookupID=@ParentLookupID AND lh.RequestTypeID=@RequestTypeID AND lh.ChildLookupID=l.LookupID
	WHERE l.LookupTypeID=@LookupTypeID
		AND 
			(
				@ShowArchived = 1
				OR
				(@ShowArchived = 0 AND l.IsActive=1)
			)
		AND 
		(
			(@ParentID IS NOT NULL AND ISNULL(@ParentID, 0) <> 0 AND ISNULL(l.ParentID, 0) = ISNULL(@ParentID, 0))
			OR
			(@ParentID IS NULL OR ISNULL(@ParentID, 0) = 0)
		)
		AND
		(
			(
				@ShowAdminSelected = 1
				OR
				(l.LookupID IN (SELECT ChildLookupID 
							FROM LookupsHierarchy lh 
							WHERE lh.ParentLookupTypeID=@ParentLookupTypeID AND lh.ChildLookupTypeID=@LookupTypeID
								AND lh.ParentLookupID=@ParentLookupID AND lh.RequestTypeID=@RequestTypeID
							)
				) 
				OR
				@HierarchyExists = CONVERT(BIT, 0)
			)
		)
	
	IF (@IsSecureType = 1 AND @ByPassSecureCheck=0)
	BEGIN
		DELETE FROM #type WHERE LookupID NOT IN (SELECT LookupID FROM UserDetails ud WHERE ud.UserID=@UserID)
	END
	
	; WITH cte AS
	(
		SELECT LookupID, [Type], LookupType, HasAccess, Description, ISNULL(ParentID, 0) AS ParentID, Parent, RequestAssigned, IsActive,
			cast(row_number()over(partition by ParentID order by LookupType) as varchar(max)) as [path],
			0 as level,
			row_number()over(partition by ParentID order by LookupType) / power(10.0,0) as x
		FROM #type
		WHERE ISNULL(ParentID, 0) = 0
		UNION ALL
		SELECT t.LookupID, t.[Type], t.LookupType, t.HasAccess, t.Description, t.ParentID, t.Parent, cte.RequestAssigned, cte.IsActive,
		[path] +'-'+ cast(row_number() over(partition by t.ParentID order by t.LookupType) as varchar(max)),
		level+1,
		x + row_number()over(partition by t.ParentID order by t.LookupType) / power(10.0,level+1)
		FROM cte
			INNER JOIN #type t on cte.LookupID = t.ParentID
	)
	select LookupID, [Type], LookupType, HasAccess, Description, ParentID, (CONVERT(NVARCHAR, ParentID) + '-' + Parent) AS Parent, x, (CONVERT(NVARCHAR, LookupID) + '-' + LookupType) AS DisplayText, RequestAssigned, IsActive
	FROM cte
	UNION ALL
	SELECT 0 AS LookupID, @Type AS [Type], '' As LookupType, CONVERT(BIT, 0) As HasAccess, NULL AS Description, 0 AS ParentID, NULL AS Parent, NULL AS x, '' AS DisplayText, @NotSetSelected AS RequestAssigned, 1 AS IsActive
	ORDER BY x		
		
	DROP TABLE #type
END
GO
GRANT EXECUTE ON remispGetLookups TO REMI
GO
ALTER PROCEDURE [Req].[GetRequestSetupInfo] @ProductID INT, @JobID INT, @BatchID INT, @TestStageType INT, @BlankSelected INT, @UserID INT, @RequestTypeID INT
AS
BEGIN
	SELECT ta.TestID
	INTO #Tests
	FROM UserDetails ud
		INNER JOIN Lookups l ON l.LookupID=ud.LookupID
		INNER JOIN LookupType lt ON lt.LookupTypeID=l.LookupTypeID
		INNER JOIN TestsAccess ta ON ta.LookupID=ud.LookupID
		INNER JOIN Req.RequestTypeAccess rta ON rta.LookupID = ta.LookupID
	WHERE (@UserID = 0 OR ud.UserID=@UserID) AND lt.Name='Department' AND (@RequestTypeID = 0 OR rta.RequestTypeID=@RequestTypeID)

	IF NOT EXISTS(SELECT 1 FROM Req.RequestSetup rs INNER JOIN Tests t ON t.ID=rs.TestID WHERE BatchID=@BatchID AND t.TestType=@TestStageType)
	BEGIN
		IF EXISTS(SELECT 1 FROM Req.RequestSetup rs INNER JOIN Tests t ON t.ID=rs.TestID WHERE JobID=@JobID AND LookupID=@ProductID AND t.TestType=@TestStageType)
		BEGIN
			SELECT ts.ID As TestStageID, ts.TestStageName, t.ID AS TestID, t.TestName, CASE WHEN rs.ID IS NULL THEN CONVERT(BIT, 0) ELSE CONVERT(BIT, 1) END AS Selected
			FROM Jobs j
				INNER JOIN TestStages ts ON j.ID=ts.JobID
				INNER JOIN Tests t WITH(NOLOCK) ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
				LEFT OUTER JOIN Req.RequestSetup rs ON rs.JobID=@JobID AND rs.LookupID=@ProductID AND rs.TestID=t.ID AND rs.TestStageID=ts.ID
			WHERE j.ID=@JobID AND ts.TestStageType=@TestStageType AND ts.ProcessOrder >= 0 AND ISNULL(ts.IsArchived, 0) = 0 AND ISNULL(t.IsArchived, 0) = 0
				AND (@TestStageType <> 1 OR (@TestStageType = 1 AND t.ID IN (SELECT TestID FROM #Tests)))
				AND ISNULL(j.IsActive, 1) = 1
			ORDER BY ts.ProcessOrder, t.TestName
		END
		ELSE IF @BlankSelected = 0 AND EXISTS(SELECT 1 FROM Req.RequestSetup rs INNER JOIN Tests t ON t.ID=rs.TestID WHERE JobID=@JobID AND LookupID IS NULL AND t.TestType=@TestStageType)
		BEGIN
			SELECT ts.ID As TestStageID, ts.TestStageName, t.ID AS TestID, t.TestName, CASE WHEN rs.ID IS NULL THEN CONVERT(BIT, 0) ELSE CONVERT(BIT, 1) END AS Selected
			FROM Jobs j
				INNER JOIN TestStages ts ON j.ID=ts.JobID
				INNER JOIN Tests t WITH(NOLOCK) ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
				LEFT OUTER JOIN Req.RequestSetup rs ON rs.JobID=@JobID AND rs.LookupID IS NULL AND rs.TestID=t.ID AND rs.TestStageID=ts.ID
			WHERE j.ID=@JobID AND ts.TestStageType=@TestStageType AND ts.ProcessOrder >= 0 AND ISNULL(ts.IsArchived, 0) = 0 AND ISNULL(t.IsArchived, 0) = 0
				AND (@TestStageType <> 1 OR (@TestStageType = 1 AND t.ID IN (SELECT TestID FROM #Tests)))
				AND ISNULL(j.IsActive, 1) = 1
			ORDER BY ts.ProcessOrder, t.TestName
		END
		ELSE
		BEGIN
			SELECT ts.ID As TestStageID, ts.TestStageName, t.ID AS TestID, t.TestName, CASE WHEN @BlankSelected = 1 THEN CONVERT(BIT, 0) ELSE CONVERT(BIT, 1) END AS Selected
			FROM Jobs j
				INNER JOIN TestStages ts ON j.ID=ts.JobID
				INNER JOIN Tests t WITH(NOLOCK) ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
			WHERE j.ID=@JobID AND ts.TestStageType=@TestStageType AND ts.ProcessOrder >= 0 AND ISNULL(ts.IsArchived, 0) = 0 AND ISNULL(t.IsArchived, 0) = 0
				AND (@TestStageType <> 1 OR (@TestStageType = 1 AND t.ID IN (SELECT TestID FROM #Tests)))
				AND ISNULL(j.IsActive, 1) = 1
			ORDER BY ts.ProcessOrder, t.TestName
		END
	END
	ELSE
	BEGIN
		SELECT ts.ID As TestStageID, ts.TestStageName, t.ID AS TestID, t.TestName, CASE WHEN rs.ID IS NULL THEN CONVERT(BIT, 0) ELSE CONVERT(BIT, 1) END AS Selected
		FROM Jobs j
			INNER JOIN TestStages ts ON j.ID=ts.JobID
			INNER JOIN Tests t WITH(NOLOCK) ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
			LEFT OUTER JOIN Req.RequestSetup rs ON rs.TestID=t.ID 
											AND rs.BatchID=@BatchID 
											AND rs.TestStageID=ts.ID 
											AND 
											(
												(ISNULL(rs.LookupID,0)=ISNULL(@ProductID,0))
												OR
												(rs.LookupID IS NULL)
											)
		WHERE j.ID=@JobID AND ts.TestStageType=@TestStageType AND ts.ProcessOrder >= 0 AND ISNULL(ts.IsArchived, 0) = 0 AND ISNULL(t.IsArchived, 0) = 0
			AND (@TestStageType <> 1 OR (@TestStageType = 1 AND t.ID IN (SELECT TestID FROM #Tests)))
			AND ISNULL(j.IsActive, 1) = 1
		ORDER BY ts.ProcessOrder, t.TestName		
	END
	
	DROP TABLE #Tests
END
GO
GRANT EXECUTE ON [Req].[GetRequestSetupInfo] TO REMI
GO
ALTER VIEW [dbo].[vw_GetTaskInfo]
AS
SELECT qranumber, processorder, BatchID,
	   tsname, 
	   tname, 
	   testtype, 
	   teststagetype, 
	   resultbasedontime, 
	   testunitsfortest, 
	   (SELECT CASE WHEN specifictestduration IS NULL THEN generictestduration ELSE specifictestduration END) AS expectedDuration,
	   TestStageID, TestWI, TestID, IsArchived, ISNULL(RecordExists, 0) AS RecordExists, TestIsArchived, ISNULL(TestRecordExists, 0) AS TestRecordExists,
TestCounts
FROM   
	(
		SELECT b.qranumber,b.ID AS BatchID,
		ts.processorder, ts.teststagename AS tsname, t.testname AS tname, t.testtype, ts.teststagetype, t.duration AS genericTestDuration, ts.ID AS TestStageID,t.ID AS TestID,
		t.WILocation As TestWI, ISNULL(ts.IsArchived, 0) AS IsArchived, ISNULL(t.IsArchived, 0) AS TestIsArchived, 
			t.resultbasedontime, 
			(
				SELECT bstd.duration 
				FROM   batchspecifictestdurations AS bstd WITH(NOLOCK)
				WHERE  bstd.testid = t.id 
					   AND bstd.batchid = b.id
			) AS specificTestDuration,
			(
				SELECT CONVERT(NVARCHAR, tur.BatchUnitNumber) + ':' + CONVERT(NVARCHAR, ISNULL((SELECT MAX(x.VerNum) FROM Relab.ResultsXML x WHERE x.ResultID=r.ID), 1)) + '-' + CONVERT(NVARCHAR, CASE WHEN tr.RelabVersion = 0 THEN 1 ELSE ISNULL(tr.RelabVersion,1) END) + ','
				FROM TestUnits tur
					LEFT OUTER JOIN Relab.Results r ON r.TestUnitID=tur.ID AND r.TestID=t.ID AND r.TestStageID=ts.ID
					LEFT OUTER JOIN TestRecords tr ON tr.TestID=r.TestID AND tr.TestStageID=r.TestStageID AND tr.TestUnitID=r.TestUnitID
				WHERE tur.BatchID=b.id
				FOR xml path ('')	
			) AS TestCounts,
			(				
				SELECT Cast(tu.batchunitnumber AS VARCHAR(MAX)) + ', ' 
				FROM testunits AS tu WITH(NOLOCK)
				WHERE tu.batchid = b.id 
					AND 
					(
						NOT EXISTS 
						(
							SELECT DISTINCT 1
							FROM vw_ExceptionsPivoted as pvt WITH(NOLOCK)
							where pvt.ID IN (SELECT ID FROM TestExceptions WITH(NOLOCK) WHERE LookupID=3 AND Value = tu.ID) AND
							(
								(pvt.TestStageID IS NULL AND pvt.Test = t.ID ) 
								OR 
								(pvt.Test IS NULL AND pvt.TestStageID = ts.id) 
								OR 
								(pvt.TestStageID = ts.id AND pvt.Test = t.ID)
								OR
								(pvt.TestStageID IS NULL AND pvt.Test IS NULL)
							)
						)
					)
				FOR xml path ('')
			) AS TestUnitsForTest,
			(SELECT TOP 1 1
			FROM TestRecords tr WITH(NOLOCK)
				INNER JOIN TestUnits tu ON tr.TestUnitID = tu.ID
			WHERE tr.TestStageID=ts.ID AND tu.BatchID=b.ID) AS RecordExists,
			(SELECT TOP 1 1
			FROM TestRecords tr WITH(NOLOCK)
				INNER JOIN TestUnits tu ON tr.TestUnitID = tu.ID
			WHERE tr.TestID=t.ID AND tu.BatchID=b.ID AND tr.TestStageID = ts.ID) AS TestRecordExists
		FROM TestStages ts WITH(NOLOCK)
		INNER JOIN Jobs j WITH(NOLOCK) ON ts.JobID=j.ID
		INNER JOIN Batches b WITH(NOLOCK) on j.jobname = b.jobname 
		INNER JOIN Tests t WITH(NOLOCK) ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
		INNER JOIN Lookups p WITH(NOLOCK) ON b.ProductID=p.LookupID
		WHERE EXISTS 
			(
				SELECT DISTINCT 1
				FROM Req.RequestSetup rs
				WHERE
					(
						(rs.JobID IS NULL )
						OR
						(rs.JobID IS NOT NULL AND rs.JobID = j.ID)
					)
					AND
					(
						(rs.LookupID IS NULL)
						OR
						(rs.LookupID IS NOT NULL AND rs.LookupID = p.LookupID)
					)
					AND
					(
						(rs.TestID IS NULL)
						OR
						(rs.TestID IS NOT NULL AND rs.TestID = t.ID)
					)
					AND
					(
						(rs.TestStageID IS NULL)
						OR
						(rs.TestStageID IS NOT NULL AND rs.TestStageID = ts.ID)
					)
					AND
					(
						(rs.BatchID IS NULL) AND NOT EXISTS(SELECT 1 
															FROM Req.RequestSetup rs2 
																INNER JOIN TestStages ts2 ON ts2.ID=rs2.TestStageID AND ts2.TestStageType=ts.TestStageType
															WHERE rs2.BatchID = b.ID )
						OR
						(rs.BatchID IS NOT NULL AND rs.BatchID = b.ID)
					)
			)
	) AS unitData
WHERE TestUnitsForTest IS NOT NULL AND 
	(
		(ISNULL(RecordExists,0) > 0 AND IsArchived = 1 AND ISNULL(TestRecordExists, 0) > 0 AND TestIsArchived = 1)
		OR
		(ISNULL(IsArchived, 0) = 0 AND ISNULL(TestIsArchived, 0) = 0)
		OR
		(ISNULL(RecordExists,0) > 0 AND IsArchived = 0 AND ISNULL(TestRecordExists, 0) > 0 AND TestIsArchived = 1)
		OR
		(ISNULL(RecordExists,0) > 0 AND IsArchived = 1 AND ISNULL(TestRecordExists, 0) > 0 AND TestIsArchived = 0)
	)
GO
ALTER PROCEDURE [dbo].remispSaveCalibrationConfiguration @LookupID INT, @TestID INT, @HostID INT, @Name As NVARCHAR(150), @XML AS NTEXT, @LastUser As NVARCHAR(255)
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM Calibration WHERE TestID=@TestID AND LookupID=@LookupID And HostID=@HostID And Name=@Name)
	BEGIN
		INSERT INTO Calibration (HostID, LookupID, TestID, Name, DateCreated, [File], LastUser) Values (@HostID, @LookupID, @TestID, @Name, GETDATE(), CONVERT(XML, @XML), @LastUser)
	END
	ELSE
	BEGIN
		UPDATE Calibration
		SET [File]=CONVERT(XML, @XML), LastUser=@LastUser, DateCreated=GETDATE()
		WHERE TestID=@TestID AND LookupID=@LookupID And HostID=@HostID And Name=@Name
	END
END
GO
GRANT EXECUTE ON remispSaveCalibrationConfiguration TO REMI
GO
ALTER PROCEDURE remispGetAllCalibrationXML @LookupID INT, @HostID INT, @TestID INT
AS
BEGIN
	SELECT c.ID, c.HostID, tlh.HostName, c.LookupID AS ProductID, p.[values] AS ProductGroupName, c.DateCreated, c.[File], c.Name, c.TestID, t.TestName
	FROM Calibration c
		INNER JOIN Lookups p WITH(NOLOCK) on p.LookupID=c.LookupID
		INNER JOIN TrackingLocationsHosts tlh ON tlh.ID=c.HostID
		INNER JOIN Tests t ON t.ID=c.TestID
	WHERE c.LookupID=@LookupID AND c.HostID=@HostID AND c.TestID=@TestID
END
GO
GRANT EXECUTE ON remispGetAllCalibrationXML TO REMI
GO
ALTER procedure [dbo].[remispTestExceptionsGetBatchExceptions] @qraNumber nvarchar(11) = null
AS
--get any for the product
select distinct pvt.id, null as batchunitnumber, pvt.ReasonForRequest AS ReasonForRequestID,(select [values] from Lookups where LookupID=b.ProductID) AS ProductGroupName,b.JobName, ts.teststagename
, t.TestName, (SELECT TOP 1 LastUser FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS ConcurrencyID,
pvt.TestStageID, pvt.TestUnitID, pvt.ProductTypeID, pvt.AccessoryGroupID, b.ProductID,
l2.[Values] As AccessoryGroupName, l.[Values] As ProductType, pvt.IsMQual, l3.[Values] As TestCenter, l3.[LookupID] As TestCenterID,
l4.[Values] AS ReasonForRequest
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.LookupID=pvt.TestCenterID
	LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON l4.LookupID=pvt.ReasonForRequest
	, Batches as b, teststages ts WITH(NOLOCK), Jobs j WITH(NOLOCK)
where b.QRANumber = @qranumber 
	and (ts.JobID = j.ID or j.ID is null)
	and (b.JobName = j.JobName or j.JobName is null)
	and pvt.TestUnitID is null
	and (ts.id = pvt.teststageid or pvt.TestStageID is null)
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
select distinct pvt.id, tu.BatchUnitNumber, pvt.ReasonForRequest AS ReasonForRequestID,lp.[Values] AS ProductGroupName,b.JobName, 
(select teststagename from teststages WITH(NOLOCK) where teststages.id =pvt.TestStageid) as teststagename, t.testname,
(SELECT TOP 1 LastUser FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS ConcurrencyID
, pvt.TestStageID, pvt.TestUnitID, pvt.ProductTypeID, pvt.AccessoryGroupID,b.ProductID,
l2.[Values] As AccessoryGroupName, l.[Values] As ProductType, pvt.IsMQual, l3.[Values] As TestCenter, l3.[LookupID] As TestCenterID,
l4.[Values] AS ReasonForRequest
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.LookupID=pvt.TestCenterID
	LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON l4.LookupID=pvt.ReasonForRequest
	INNER JOIN testunits tu WITH(NOLOCK) ON tu.ID=pvt.TestUnitID
	INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
	LEFT OUTER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=b.ProductID
WHERE b.QRANumber = @qranumber and tu.batchid = b.id and pvt.TestUnitID = tu.id
order by pvt.TestUnitID desc,TestName
GO
GRANT EXECUTE ON remispTestExceptionsGetBatchExceptions TO Remi
GO
ALTER PROCEDURE [dbo].remispGetBatchUnitsInStage @QRANumber nvarchar(11)
AS
BEGIN
	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	DECLARE @RowID INT
	DECLARE @TestUnitID INT
	DECLARE @BatchUnitNumber INT
	CREATE TABLE #Testing (TestStageID INT, TestStageName NVARCHAR(400), ProcessOrder INT)

	SELECT @rows=  ISNULL(STUFF(
			( 
			SELECT DISTINCT '],[' + CONVERT(VARCHAR, tu.BatchUnitNumber)
			FROM TestUnits tu
				INNER JOIN Batches b ON b.ID=tu.BatchID
			WHERE b.QRANumber=@QRANumber
			FOR XML PATH('')), 1, 2, '') + ']','[na]')

	INSERT INTO #Testing (TestStageID, TestStageName, ProcessOrder)
	SELECT ID, TestStageName, ProcessOrder
	FROM (
	SELECT ts.ID, ts.TestStageName, ts.ProcessOrder
	FROM TestStages ts WITH(NOLOCK)
		INNER JOIN Jobs j WITH(NOLOCK) ON ts.JobID=j.ID
		INNER JOIN Batches b WITH(NOLOCK) on j.jobname = b.jobname 
		INNER JOIN Tests t WITH(NOLOCK) ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
	WHERE b.QRANumber = @QRANumber AND EXISTS 
		(
			SELECT DISTINCT 1
			FROM Req.RequestSetup rs
			WHERE
				(
					(rs.JobID IS NULL )
					OR
					(rs.JobID IS NOT NULL AND rs.JobID = j.ID)
				)
				AND
				(
					(rs.LookupID IS NULL)
					OR
					(rs.LookupID IS NOT NULL AND rs.LookupID = b.ProductID)
				)
				AND
				(
					(rs.TestID IS NULL)
					OR
					(rs.TestID IS NOT NULL AND rs.TestID = t.ID)
				)
				AND
				(
					(rs.TestStageID IS NULL)
					OR
					(rs.TestStageID IS NOT NULL AND rs.TestStageID = ts.ID)
				)
				AND
				(
					(rs.BatchID IS NULL) AND NOT EXISTS(SELECT 1 
														FROM Req.RequestSetup rs2 
															INNER JOIN TestStages ts2 ON ts2.ID=rs2.TestStageID AND ts2.TestStageType=ts.TestStageType
														WHERE rs2.BatchID = b.ID )
					OR
					(rs.BatchID IS NOT NULL AND rs.BatchID = b.ID)
				)
		)
	) s
	ORDER BY ProcessOrder

	SET @sql = 'ALTER TABLE #Testing ADD ' + convert(varchar(8000), replace(@rows, ']', '] BIT '))
	EXEC (@sql)

	SELECT ROW_NUMBER() OVER (ORDER BY tu.ID) AS RowID, tu.BatchUnitNumber, tu.ID
	INTO #units
	FROM TestUnits tu WITH(NOLOCK)
		INNER JOIN Batches b ON b.ID=tu.BatchID
	WHERE b.QRANumber=@QRANumber

	SELECT @RowID = MIN(RowID) FROM #units
				
	WHILE (@RowID IS NOT NULL)
	BEGIN
		SELECT @BatchUnitNumber=BatchUnitNumber, @TestUnitID=ID FROM #units WITH(NOLOCK) WHERE RowID=@RowID

		SET @sql = 'UPDATE t SET [' + CONVERT(VARCHAR,@BatchUnitNumber) + '] = 
			ISNULL((
				SELECT DISTINCT CONVERT(BIT, 1)
				FROM vw_GetTaskInfo ti 
				WHERE ti.QRANumber = ''' + @QRANumber + ''' AND t.TestStageID=ti.TestStageID 
					AND ti.testunitsfortest LIKE ''%' + CONVERT(VARCHAR,@BatchUnitNumber) + ',%''
			), 0)
		FROM #Testing t
	'
		
		print @sql

		EXECUTE (@sql)
		
		SELECT @RowID = MIN(RowID) FROM #units WITH(NOLOCK) WHERE RowID > @RowID

	END


	SELECT * FROM #Testing

	DROP TABLE #Testing
	DROP TABLE #units
END
GO
GRANT EXECUTE ON remispGetBatchUnitsInStage TO REMI
GO
ALTER PROCEDURE remispGetSimilarTestConfiguration @LookupID INT, @TestID INT
AS
BEGIN
	SELECT pc.LookupID AS ID, lp.[Values] AS ProductGroupName
	FROM ProductConfigurationUpload pc
		INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=pc.LookupID
	WHERE pc.TestID=@TestID AND pc.LookupID <> @LookupID
	GROUP BY pc.LookupID, lp.[Values]
END
GO
GRANT EXECUTE ON remispGetSimilarTestConfiguration TO REMI
GO
ALTER PROCEDURE remispCopyTestConfiguration @LookupID INT, @TestID INT, @copyFromLookupID INT, @LastUser NVARCHAR(255)
AS
BEGIN
	BEGIN TRANSACTION
	
	BEGIN TRY
		DECLARE @FromCount INT
		DECLARE @ToCount INT
		DECLARE @max INT
		DECLARE @UploadID INT
		SET @max = (SELECT MAX(ID) +1 FROM ProductConfiguration)
		
		SELECT @FromCount = COUNT(*) 
		FROM ProductConfiguration pc
			INNER JOIN ProductConfigurationUpload u ON u.ID=pc.UploadID
		WHERE TestID=@TestID AND u.LookupID=@copyFromLookupID
		
		SELECT tempID=IDENTITY (int, 1, 1), CONVERT(int,pc.ID) As ID, ParentId, ViewOrder, NodeName, @TestID AS TestID, @LookupID AS ProductID, @LastUser AS LastUser, 0 AS newproID, NULL AS newParentID
		INTO #ProductConfiguration
		FROM ProductConfiguration pc
			INNER JOIN ProductConfigurationUpload u ON u.ID=pc.UploadID
		WHERE u.TestID=@TestID AND u.LookupID=@copyFromLookupID
		
		IF ((SELECT COUNT(*) FROM #ProductConfiguration) > 0)
		BEGIN
			UPDATE #ProductConfiguration SET newproID=@max+tempid
			
			UPDATE #ProductConfiguration 
			SET #ProductConfiguration.newParentID = pc2.newproID
			FROM #ProductConfiguration
				LEFT OUTER JOIN #ProductConfiguration pc2 ON #ProductConfiguration.ParentID=pc2.ID
				
			INSERT INTO ProductConfigurationUpload (IsProcessed, LastUser, TestID, PCName, LookupID)
			SELECT 1 AS IsProcessed, @LastUser AS LastUser, c.TestID, c.PCName, @LookupID AS LookupID
			FROM ProductConfigurationUpload c
			WHERE c.TestID=@TestID AND c.LookupID=@copyFromLookupID
			
			SELECT @UploadID = c.ID
			FROM ProductConfigurationUpload c
			WHERE c.TestID=@TestID AND c.LookupID=@LookupID
				
			SET Identity_Insert ProductConfiguration ON
			
			INSERT INTO ProductConfiguration (ID, ParentId, ViewOrder, NodeName, LastUser, UploadID)
			SELECT newproID, newParentId, ViewOrder, NodeName, LastUser, @UploadID AS UploadID
			FROM #ProductConfiguration
			
			SET Identity_Insert ProductConfiguration OFF
			
			SELECT @ToCount = COUNT(*) 
			FROM ProductConfiguration pc
				INNER JOIN ProductConfigurationUpload u ON u.ID=pc.UploadID
			WHERE u.TestID=@TestID AND u.LookupID=@LookupID

			IF (@FromCount = @ToCount)
			BEGIN
				SELECT @FromCount = COUNT(*) 
				FROM ProductConfiguration pc 
					INNER JOIN ProductConfigValues pcv ON pc.ID=pcv.ProductConfigID
					INNER JOIN ProductConfigurationUpload u ON u.ID=pc.UploadID
				WHERE u.TestID=@TestID AND u.LookupID=@copyFromLookupID
			
				INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
				SELECT Value, LookupID, #ProductConfiguration.newproID AS ProductConfigID, @LastUser AS LastUser, IsAttribute
				FROM ProductConfigValues
					INNER JOIN ProductConfiguration ON ProductConfigValues.ProductConfigID=ProductConfiguration.ID
					INNER JOIN #ProductConfiguration ON ProductConfiguration.ID=#ProductConfiguration.ID	
					
				SELECT @ToCount = COUNT(*) 
				FROM ProductConfiguration pc
					INNER JOIN ProductConfigValues pcv ON pc.ID=pcv.ProductConfigID 
					INNER JOIN ProductConfigurationUpload u ON u.ID=pc.UploadID
				WHERE u.TestID=@TestID AND u.LookupID=@LookupID
				
				IF (@FromCount <> @ToCount)
				BEGIN
					GOTO HANDLE_ERROR
				END
				GOTO HANDLE_SUCESS
			END
			ELSE
			BEGIN
				GOTO HANDLE_ERROR
			END
		END
		ELSE
		BEGIN
			GOTO HANDLE_SUCESS
		END
	END TRY
	BEGIN CATCH
		  SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_SEVERITY() AS ErrorSeverity, ERROR_STATE() as ErrorState, ERROR_PROCEDURE() as ErrorProcedure, ERROR_LINE() as ErrorLine, ERROR_MESSAGE() as ErrorMessage

		  GOTO HANDLE_ERROR
	END CATCH
	
	HANDLE_SUCESS:
		IF @@TRANCOUNT > 0
			COMMIT TRANSACTION
			RETURN	
	
	HANDLE_ERROR:
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION
			RETURN
END
GO
GRANT EXECUTE ON remispCopyTestConfiguration TO REMI
GO
ALTER PROCEDURE [dbo].remispProductConfigurationUpload @LookupID INT, @TestID INT, @XML AS NTEXT, @LastUser As NVARCHAR(255), @PCName NVARCHAR(200) = NULL
AS
BEGIN
	IF (@PCName IS NULL OR LTRIM(RTRIM(@PCName)) = '') --Get The Root Name Of the XML
	BEGIN
		DECLARE @xmlTemp XML = CONVERT(XML, @XML)
		SELECT @PCName= LTRIM(RTRIM(x.c.value('local-name(/*[1])','nvarchar(max)')))
		FROM @xmlTemp.nodes('/*') x ( c )
		
		IF (@PCName = '')
		BEGIN
			SET @PCName = 'ProductConfiguration'
		END
	END

	IF EXISTS (SELECT 1 FROM ProductConfigurationUpload WHERE TestID=@TestID AND LookupID=@LookupID AND PCName=@PCName)
	BEGIN
		DECLARE @increment INT
		DECLARE @PCNameTemp NVARCHAR(200)
		SET @PCNameTemp = @PCName
		SET @increment = 1
		
		WHILE EXISTS (SELECT 1 FROM ProductConfigurationUpload WHERE TestID=@TestID AND LookupID=@LookupID AND PCName=@PCNameTemp)
		BEGIN
			SET @PCNameTemp = @PCName + CONVERT(NVARCHAR, @increment)
			SET @increment = @increment + 1
			print @PCNameTemp
		END
		
		SET @PCName = @PCNameTemp
	END
	
	IF NOT EXISTS (SELECT 1 FROM ProductConfigurationUpload WHERE TestID=@TestID AND LookupID=@LookupID AND PCName=@PCName)
	BEGIN
		INSERT INTO ProductConfigurationUpload (IsProcessed, LookupID, TestID, LastUser, PCName) 
		Values (CONVERT(BIT, 0), @LookupID, @TestID, @LastUser, @PCName)
		
		DECLARE @UploadID INT
		SET @UploadID =  @@IDENTITY

		EXEC remispProductConfigurationSaveXMLVersion @XML, @LastUser, @UploadID
	END
END
GO
GRANT EXECUTE ON remispProductConfigurationUpload TO REMI
GO
ALTER PROCEDURE [dbo].remispProductConfigurationProcess AS
BEGIN
	CREATE TABLE #temp2 (ID INT, ParentID INT NULL, NodeType INT, LocalName NVARCHAR(100), Text NVARCHAR(2000), ID_temp INT IDENTITY(1,1), ID_NEW INT NULL, ParentID_NEW INT NULL)
	CREATE TABLE #temp3 (LookupID INT, Type INT, LocalName NVARCHAR(150), ID INT IDENTITY(1,1))
	DECLARE @MaxID INT
	DECLARE @MaxLookupID INT
	DECLARE @LookupTypeID INT
	DECLARE @idoc INT
	DECLARE @ID INT
	DECLARE @xml XML
	DECLARE @LastUser NVARCHAR(255)

	IF ((SELECT COUNT(*) FROM ProductConfigurationUpload WHERE ISNULL(IsProcessed,0)=0 AND LookupID IN (SELECT LookupID FROM Lookups))=0)
		RETURN
	
	SELECT @LookupTypeID=LookupTypeID FROM LookupType WHERE Name='Configuration'

	WHILE ((SELECT COUNT(*) FROM ProductConfigurationUpload WHERE ISNULL(IsProcessed,0)=0)>0)
	BEGIN
		SELECT TOP 1 @ID=pcu.ID, @xml =pcv.PCXML, @LastUser=pcu.LastUser
		FROM ProductConfigurationUpload pcu
			INNER JOIN ProductConfigurationVersion pcv ON pcu.ID=pcv.UploadID AND pcv.VersionNum=1
		WHERE ISNULL(IsProcessed,0)=0 AND LookupID IN (SELECT LookupID FROM Lookups)
		
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

		insert into Lookups (LookupID, [Values], LookupTypeID)
		select LookupID, localname as [Values], [Type] AS LookupTypeID from #temp3
			
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
GRANT EXECUTE ON remispProductConfigurationProcess TO Remi
GO
ALTER VIEW [dbo].[vw_BatchAudit]
AS
SELECT ba.QRANumber, ba.Priority AS PriorityID, ba.BatchStatus, ba.JobName, ba.TestStageName, ba.UserName, ba.InsertTime, ba.Action, ba.RequestPurpose AS RequestPurposeID, 
lp.[Values] AS ProductGroupName, tc.[Values] AS TestCenter, ba.IsMQual, pt.[Values] AS ProductType, at.[Values] AS AccessoryGroup,
rp.[Values] AS RequestPurpose, pr.[Values] AS Priority
FROM dbo.BatchesAudit AS ba 
INNER JOIN dbo.Lookups lp ON lp.LookupID=ba.ProductID
LEFT OUTER JOIN dbo.Lookups AS at ON at.LookupID = ba.AccessoryGroupID 
LEFT OUTER JOIN dbo.Lookups AS pt ON pt.LookupID = ba.ProductTypeID 
LEFT OUTER JOIN dbo.Lookups AS tc ON tc.LookupID = ba.TestCenterLocationID 
LEFT OUTER JOIN dbo.Lookups AS rp ON rp.LookupID = ba.RequestPurpose 
LEFT OUTER JOIN dbo.Lookups AS pr ON pr.LookupID = ba.Priority
GO
ALTER PROCEDURE Relab.remispGetObservations @BatchID INT
AS
BEGIN
	DECLARE @ObservationLookupID INT
	SELECT @ObservationLookupID = LookupID FROM Lookups WITH(NOLOCK) WHERE LookupTypeID=7 AND [values] = 'Observation'

	SELECT b.QRANumber, tu.BatchUnitNumber AS Unit, (SELECT TOP 1 ts2.TestStageName
								FROM Relab.Results r2 WITH(NOLOCK)
									INNER JOIN TestStages ts2 WITH(NOLOCK) ON ts2.ID=r2.TestStageID AND ts2.TestStageType=2
								WHERE r2.TestUnitID=r.TestUnitID
								ORDER BY ts2.ProcessOrder DESC
								) AS MaxStage, 
			ts.TestStageName AS Stage, [Relab].[ResultsObservation] (m.ID) AS Observation, 
			(SELECT TOP 1 T.c.value('@Description', 'varchar(MAX)')
			FROM jo.Definition.nodes('/Orientations/Orientation') T(c)
			WHERE T.c.value('@Unit', 'varchar(MAX)') = tu.BatchUnitNumber AND ts.TestStageName LIKE T.c.value('@Drop', 'varchar(MAX)') + ' %') AS Orientation, 
			m.Comment, (CASE WHEN (SELECT COUNT(*) FROM Relab.ResultsMeasurementsFiles rmf WITH(NOLOCK) WHERE rmf.ResultMeasurementID=m.ID) > 0 THEN 1 ELSE 0 END) AS HasFiles, m.ID AS MeasurementID
	FROM Relab.ResultsMeasurements m WITH(NOLOCK)
		INNER JOIN Relab.Results r WITH(NOLOCK) ON r.ID=m.ResultID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID=r.TestStageID
		INNER JOIN Tests t WITH(NOLOCK) ON t.ID=r.TestID
		INNER JOIN Lookups lm WITH(NOLOCK) ON lm.LookupID=m.MeasurementTypeID
		INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
		LEFT OUTER JOIN JobOrientation jo WITH(NOLOCK) ON jo.ID=b.OrientationID
	WHERE MeasurementTypeID = @ObservationLookupID
		AND b.ID=@BatchID AND ISNULL(m.Archived,0) = 0
	ORDER BY tu.BatchUnitNumber, ts.ProcessOrder
END
GO
GRANT EXECUTE ON Relab.remispGetObservations TO REMI
GO
ALTER PROCEDURE [Relab].[remispResultsStatus] @BatchID INT
AS
BEGIN
	DECLARE @Status NVARCHAR(18)
	
	SELECT CASE WHEN r.PassFail = 0 THEN 'Fail' ELSE 'Pass' END AS Result, COUNT(*) AS NumRecords
	INTO #ResultCount
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
	WHERE tu.BatchID=@BatchID
	GROUP BY r.PassFail
	
	SELECT CASE 
			WHEN rs.PassFail = 1 THEN 'Pass' 
			WHEN rs.PassFail=2 THEN 'Fail' 
			WHEN rs.PassFail=4 THEN 'Un-Verified Pass' 
			WHEN rs.PassFail=5 THEN 'Un-Verified Fail' 
			ELSE 'No Result' END AS Result, 
		rs.ApprovedBy, rs.ApprovedDate
	INTO #ResultOverride
	FROM Relab.ResultsStatus rs WITH(NOLOCK)
	WHERE rs.BatchID=@BatchID
	ORDER BY ResultStatusID DESC
	
	IF ((SELECT COUNT(*) FROM #ResultOverride) > 0)
		BEGIN
			SELECT TOP 1 @Status = Result FROM #ResultOverride
		END
	ELSE
		BEGIN
			IF EXISTS ((SELECT 1 FROM #ResultCount WHERE Result='Fail'))
				SET @Status = 'Un-Verified Fail'
			ELSE IF EXISTS ((SELECT 1 FROM #ResultCount WHERE Result='Pass'))
				SET @Status = 'Un-Verified Pass'
			ELSE
				SET @Status = 'No Result'
		END
	
	SELECT * FROM #ResultCount
	SELECT * FROM #ResultOverride
		
	SELECT @Status AS FinalStatus
	
	DROP TABLE #ResultCount
	DROP TABLE #ResultOverride
END
GO
GRANT EXECUTE ON [Relab].[remispResultsStatus] TO Remi
GO
ALTER PROCEDURE [dbo].[remispESResultSummary] @BatchID INT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @UnitRows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	DECLARE @BatchUnitNumber INT
	DECLARE @UnitCount INT
	DECLARE @RowID INT
	DECLARE @ID INT
	CREATE TABLE #Results (TestStageID INT, Stage NVARCHAR(MAX), TestID INT, Test NVARCHAR(MAX), ProcessOrder INT)

	SELECT ROW_NUMBER() OVER (ORDER BY tu.ID) AS RowID, tu.BatchUnitNumber, tu.ID
	INTO #units
	FROM TestUnits tu WITH(NOLOCK)
	WHERE BatchID=@BatchID

	INSERT INTO #Results (TestID, Test, TestStageID, Stage, ProcessOrder)
	SELECT DISTINCT r.TestID, t.TestName, r.TestStageID, ts.TestStageName, ts.ProcessOrder
	FROM Batches b 
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.BatchID=b.ID
		INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Tests t WITH(NOLOCK) ON t.ID=r.TestID
		INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID=r.TestStageID
	WHERE b.ID=@BatchID AND ts.TestStageName NOT IN ('Analysis')
	ORDER BY ts.ProcessOrder

	SELECT @UnitCount = COUNT(RowID) FROM #units WITH(NOLOCK)

	SELECT @RowID = MIN(RowID) FROM #units
				
	WHILE (@RowID IS NOT NULL)
	BEGIN
		SELECT @BatchUnitNumber=BatchUnitNumber, @ID=ID FROM #units WITH(NOLOCK) WHERE RowID=@RowID

		EXECUTE ('ALTER TABLE #Results ADD [' + @BatchUnitNumber + '] NVARCHAR(10) NULL')
		print @ID
		SET @SQL = 'UPDATE rr
				SET [' + CONVERT(VARCHAR,@BatchUnitNumber) + '] = (
						SELECT CASE WHEN PassFail  = 1 THEN ''Pass'' WHEN PassFail = 0 THEN ''Fail'' ELSE NULL END + 
							CASE WHEN (SELECT CONVERT(VARCHAR,COUNT(*))
							FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
								INNER JOIN Relab.ResultsMeasurementsFiles rmf WITH(NOLOCK) ON rmf.ResultMeasurementID=rm.ID
							WHERE rm.ResultID=r.ID) > 0 THEN ''1'' ELSE ''0'' END
						FROM Relab.Results r WITH(NOLOCK) 
						WHERE r.TestUnitID=' + CONVERT(NVARCHAR, @ID) + '
							AND rr.TestID=r.TestID AND rr.TestStageID=r.TestStageID
					)
				FROM #Results rr'
		
		EXECUTE (@SQL)
		SELECT @RowID = MIN(RowID) FROM #units WITH(NOLOCK) WHERE RowID > @RowID
	END
	
	ALTER TABLE #Results DROP COLUMN TestID
	ALTER TABLE #Results DROP COLUMN TestStageID
	
	ALTER TABLE #Results DROP COLUMN ProcessOrder
	
	SELECT * 
	FROM #Results WITH(NOLOCK)

	DROP TABLE #units
	DROP TABLE #Results
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [dbo].[remispESResultSummary] TO Remi
GO
ALTER PROCEDURE [Relab].[remispResultsSummary] @BatchID INT
AS
BEGIN
	SELECT r.ID, ts.TestStageName AS Stage, t.TestName AS Test, tu.BatchUnitNumber AS Unit, CASE WHEN PassFail=1 THEN 'Pass' ELSE 'Fail' END AS PassFail,
		ISNULL((SELECT TOP 1 1 FROM Relab.ResultsMeasurements WHERE ResultID=r.ID),0) AS HasMeasurements
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
		INNER JOIN Tests t WITH(NOLOCK) ON r.TestID=t.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
	WHERE tu.BatchID=@BatchID
	ORDER BY tu.BatchUnitNumber, ts.ProcessOrder, t.TestName
END
GO
GRANT EXECUTE ON [Relab].[remispResultsSummary] TO Remi
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
	
	IF NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='Products' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@ProductGroupName)))
	BEGIn
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Products'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@ProductGroupName)))
				
		SET @ProductID = @maxid
	END
	ELSE
	BEGIN
		SELECT @ProductID = l.LookupID FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='Products' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@ProductGroupName))
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
ALTER PROCEDURE [dbo].[remispSaveLookup] @LookupType NVARCHAR(150), @Value NVARCHAR(150), @IsActive INT = 1, @Description NVARCHAR(200) = NULL, @ParentID INT = NULL, @Success AS BIT = NULL OUTPUT
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
			
		SET @Success = 1
	END
	ELSE
	BEGIN
		UPDATE Lookups
		SET IsActive=@IsActive, Description=@Description, ParentID=@ParentID
		WHERE LookupTypeID=@LookupTypeID AND [values]=LTRIM(RTRIM(@Value))
		
		SET @Success = 1
	END

	PRINT @Success
END
GO
GRANT EXECUTE ON remispSaveLookup TO Remi
GO
ALTER PROCEDURE [dbo].[remispGetJobOrientations] @JobID INT = 0, @JobName NVARCHAR(400) = NULL
AS
BEGIN
	SELECT jo.ID, jo.Name, jo.ProductTypeID, l.[Values] AS ProductType, jo.NumUnits, jo.NumDrops,
		jo.Description, jo.CreatedDate, jo.IsActive, jo.Definition
	FROM JobOrientation jo
		INNER JOIN Lookups l ON l.LookupID=jo.ProductTypeID
		INNER JOIN Jobs j ON j.ID=jo.JobID
	WHERE jo.IsActive = 1 AND ( 
			(jo.JobID=@JobID AND @JobID > 0)
			OR
			(j.JobName = @JobName AND @JobName IS NOT NULL)
		  )
END
GO
GRANT EXECUTE ON [dbo].[remispGetJobOrientations] TO REMI
GO
ALTER procedure [dbo].[remispUsersSearch] @ProductID INT = 0, @TestCenterID INT = 0, @TrainingID INT = 0, @TrainingLevelID INT = 0, @showAllGrid BIT = 0, 
	@UserID INT = 0, @DepartmentID INT = 0, @DetermineDelete INT = 1,  @IncludeInActive INT = 1, @IsProductManager BIT = 0, @IsTSDContact BIT = 0, @ByPass INT = 0
AS
BEGIN	
	IF (@showAllGrid = 0)
	BEGIN
		SELECT ID, LDAPLogin, BadgeNumber, ByPassProduct, DefaultPage, ISNULL(IsActive, 1) AS IsActive, LastUser, 
				ConcurrencyID, CASE WHEN @DetermineDelete = 1 THEN dbo.remifnUserCanDelete(LDAPLogin) ELSE 0 END AS CanDelete
		FROM 
			(SELECT DISTINCT u.ID, u.LDAPLogin, u.BadgeNumber, u.ByPassProduct, u.DefaultPage, ISNULL(u.IsActive, 1) AS IsActive, u.LastUser, 
				u.ConcurrencyID
			 FROM Users u
				LEFT OUTER JOIN UserTraining ut ON ut.UserID = u.ID
				INNER JOIN UserDetails udtc ON udtc.UserID=u.ID
				INNER JOIN UserDetails udd ON udd.UserID=u.ID
				LEFT OUTER JOIN UserDetails udp ON udp.UserID=u.ID
				LEFT OUTER JOIN Lookups p ON p.LookupID=udp.LookupID
			WHERE (
					(@IncludeInActive = 0 AND ISNULL(u.IsActive, 1)=1)
					OR
					@IncludeInActive = 1
				  )
				  AND 
				  (
					(udtc.LookupID=@TestCenterID) 
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
					(p.LookupID=@ProductID) 
					OR
					(@ProductID = 0)
				  )
				  AND 
				  (
					(udd.LookupID=@DepartmentID) 
					OR
					(@DepartmentID = 0)
				  )
				  AND
				  (
					(@ByPass = 0)
					OR
					(@ByPass > 0 AND u.ByPassProduct = CASE @ByPass WHEN 1 THEN 1 WHEN 2 THEN 0 ELSE 0 END) 
				  )
				  AND
				  (
					(@IsProductManager = 0)
					OR
					(@IsProductManager > 0 AND udp.IsProductManager = CASE @IsProductManager WHEN 1 THEN 1 WHEN 2 THEN 0 ELSE 0 END)
				  )
				  AND
				  (
					(@IsTSDContact = 0)
					OR
					(@IsTSDContact > 0 AND udp.IsTSDContact = CASE @IsTSDContact WHEN 1 THEN 1 WHEN 2 THEN 0 ELSE 0 END)
				  )
			) AS UsersRows
			ORDER BY LDAPLogin
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
					INNER JOIN UserDetails ud ON ud.UserID=u.ID
				WHERE u.IsActive = 1 AND (
				(ud.lookupid=' + CONVERT(VARCHAR, @TestCenterID) + ') 
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
GRANT EXECUTE ON remispUsersSearch TO REMI
GO
rollback tran