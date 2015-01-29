ALTER VIEW [req].[vw_RequestDataAudit] AS
SELECT r.RequestNumber, fs.Name, fda.Value, fda.UserName, fda.InsertTime
FROM Req.ReqFieldDataAudit fda
	INNER JOIN Req.Request r ON fda.RequestID=r.RequestID
	INNER JOIN Req.ReqFieldSetup fs ON fs.ReqFieldSetupID=fda.ReqFieldSetupID
GO