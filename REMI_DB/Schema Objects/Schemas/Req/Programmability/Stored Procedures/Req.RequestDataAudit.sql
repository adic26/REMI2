ALTER PROCEDURE [Req].[RequestDataAudit] @RequestNumber NVARCHAR(11)
AS
BEGIN
	SELECT *
	FROM Req.vw_RequestDataAudit
	WHERE RequestNumber=@RequestNumber
	ORDER BY InsertTime ASC
END
GO
GRANT EXECUTE ON [Req].[RequestDataAudit] TO REMI
GO