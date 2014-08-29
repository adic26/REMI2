ALTER PROCEDURE [dbo].[remispBatchesSelectRandomSampleQRANumbers]
AS
BEGIN
	SELECT top(5) b.QRANumber
	FROM Batches AS b WITH(NOLOCK)
		INNER JOIN DeviceTrackingLog AS dtl WITH(NOLOCK)
		INNER JOIN TrackingLocations AS tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.ID 
		INNER JOIN TestUnits AS tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID ON b.id = tu.batchid --batches where there's a tracking log
	WHERE tl.ID = 25 AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL --where they're in remstar
		and (select COUNT (*) from TestUnits WITH(NOLOCK) where TestUnits.BatchID = b.ID) <=20 -- and there are less that 20 of them
	ORDER BY CAST(CHECKSUM(NEWID(), b.id) & 0x7fffffff AS float) --generates a random number between 0 and 1
/ CAST (0x7fffffff AS int)
END
GO
GRANT EXECUTE ON remispBatchesSelectRandomSampleQRANumbers TO REMI
GO