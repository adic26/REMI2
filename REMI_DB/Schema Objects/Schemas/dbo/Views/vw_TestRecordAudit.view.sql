ALTER VIEW [dbo].[vw_TestRecordAudit] AS
SELECT tr.ID, tr.TestRecordID, TestName, TestStageName, JobName, Status, RelabVersion, tr.Comment, UserName, Action, InsertTime, ResultSource
FROM TestRecordsAudit tr
GO