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
