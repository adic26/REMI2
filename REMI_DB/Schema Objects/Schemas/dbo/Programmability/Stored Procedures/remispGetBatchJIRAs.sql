ALTER PROCEDURE [dbo].[remispGetBatchJIRAs] @BatchID INT
AS
BEGIN
	SELECT 0 AS JIRAID, @BatchID As BatchID, '' AS DisplayName, '' AS Link, '' AS Title
	UNION
	SELECT bj.JIRAID, bj.BatchID, bj.DisplayName, bj.Link, bj.Title
	FROM BatchesJira bj
	WHERE bj.BatchID=@BatchID
END
GO
GRANT EXECUTE ON [dbo].[remispGetBatchJIRAs] TO Remi
GO