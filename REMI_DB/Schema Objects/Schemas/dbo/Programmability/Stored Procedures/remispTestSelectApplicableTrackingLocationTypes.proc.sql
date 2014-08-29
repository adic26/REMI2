ALTER PROCEDURE [dbo].[remispTestSelectApplicableTrackingLocationTypes] @TestID int
AS
BEGIN
	SELECT tlt.id, tlt.TrackingLocationTypeName    
	FROM trackinglocationtypes as tlt, TrackingLocationsForTests as tlfort
	WHERE tlfort.testid = @testid and tlt.ID = tlfort.TrackingLocationtypeID
	ORDER BY tlt.TrackingLocationTypeName asc
END
GO
GRANT EXECUTE ON remispTestSelectApplicableTrackingLocationTypes TO Remi
GO