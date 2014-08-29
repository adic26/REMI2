begin tran
GO
PRINT 'Update testID test records'
WHILE ((SELECT COUNT(*) FROM TestRecords tr with(nolock) INNER JOIN Tests t with(nolock) ON t.TestName=tr.TestName WHERE tr.TestID IS NULL) > 0)
BEGIN
	UPDATE TOP (10000) tr
	SET tr.TestID=t.ID
	FROM TestRecords tr with(nolock)
		INNER JOIN Tests t with(nolock) ON t.TestName=tr.TestName
	WHERE tr.TestID IS NULL
END

PRINT 'Update testStageID test records'
WHILE ((SELECT COUNT(*) FROM TestRecords tr with(nolock) LEFT OUTER JOIN Jobs j with(nolock) ON j.JobName=tr.JobName LEFT OUTER JOIN TestStages ts with(nolock) ON ts.TestStageName=tr.TestStageName AND ts.JobID=j.ID WHERE ts.ID IS NOT NULL AND tr.TestStageID IS NULL) > 0)
BEGIN
	UPDATE TOP (10000) tr
	SET tr.TestStageID=ts.ID
	FROM TestRecords tr with(nolock)
		LEFT OUTER JOIN Jobs j with(nolock) ON j.JobName=tr.JobName
		LEFT OUTER JOIN TestStages ts with(nolock) ON ts.TestStageName=tr.TestStageName AND ts.JobID=j.ID
	WHERE ts.ID IS NOT NULL AND tr.TestStageID IS NULL
END

GO
ROLLBACK TRAN
