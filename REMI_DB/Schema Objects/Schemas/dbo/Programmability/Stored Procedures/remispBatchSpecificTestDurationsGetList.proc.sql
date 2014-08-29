ALTER PROCEDURE [dbo].[remispBatchSpecificTestDurationsGetList] @qraNumber nvarchar(11)
AS
BEGIN
	SELECT testid, duration 
	FROM Batches as b WITH(NOLOCK)
		INNER JOIN BatchSpecificTestDurations as bstd WITH(NOLOCK) ON bstd.BatchID = b.id
	WHERE b.QRANumber = @qraNumber
END
GO
GRANT EXECUTE ON remispBatchSpecificTestDurationsGetList TO REMI
GO