ALTER VIEW [req].[vw_RequestDataAudit] AS
SELECT r.RequestNumber, fs.Name, fda.Value, fda.UserName, fda.InsertTime, fda.InstanceID AS RecordNum, 
	CASE fda.Action WHEN 'U' THEN 'Updated' WHEN 'D' THEN 'Deleted' WHEN 'I' THEN 'Inserted' END AS Action
FROM Req.ReqFieldDataAudit fda
	INNER JOIN Req.Request r ON fda.RequestID=r.RequestID
	INNER JOIN Req.ReqFieldSetup fs ON fs.ReqFieldSetupID=fda.ReqFieldSetupID
GO