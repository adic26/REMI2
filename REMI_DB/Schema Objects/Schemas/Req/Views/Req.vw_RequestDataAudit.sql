ALTER VIEW [req].[vw_RequestDataAudit] WITH SCHEMABINDING
AS
SELECT ISNULL((ROW_NUMBER() OVER (ORDER BY r.RequestNumber)), 0) AS ID, r.RequestNumber, fs.Name, fda.Value, fda.UserName, fda.InsertTime, 
	ISNULL(fda.InstanceID,1) AS RecordNum, CASE fda.Action WHEN 'U' THEN 'Updated' WHEN 'D' THEN 'Deleted' WHEN 'I' THEN 'Inserted' ELSE '' END AS Action
FROM Req.ReqFieldDataAudit fda
	INNER JOIN Req.Request r ON fda.RequestID=r.RequestID
	INNER JOIN Req.ReqFieldSetup fs ON fs.ReqFieldSetupID=fda.ReqFieldSetupID
GO
