ALTER PROCEDURE [dbo].[remispTestUnitsAvailable] @RequestNumber NVARCHAR(11)
AS
BEGIN
	SELECT tu.BatchUnitNumber
	FROM Batches b WITH(NOLOCK)
		INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID=tu.BatchID
	WHERE QRANumber=@RequestNumber
		AND tu.ID NOT IN (SELECT dtl.TestUnitID
					FROM DeviceTrackingLog dtl WITH(NOLOCK)
						INNER JOIN TrackingLocations tl WITH(NOLOCK) ON dtl.TrackingLocationID=tl.ID AND tl.ID NOT IN (25,81)
					WHERE TestUnitID = 214734 AND OutTime IS NULL)
END
GO
GRANT EXECUTE ON remispTestUnitsAvailable TO REMI
GO