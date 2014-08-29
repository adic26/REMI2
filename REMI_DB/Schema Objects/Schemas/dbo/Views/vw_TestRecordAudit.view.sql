alter VIEW [dbo].[vw_TestRecordAudit] AS
SELECT tr.TestRecordID, TestName, TestStageName, JobName, Status, RelabVersion, tr.Comment, UserName, Action, InsertTime, ResultSource
FROM TestRecordsAudit tr
