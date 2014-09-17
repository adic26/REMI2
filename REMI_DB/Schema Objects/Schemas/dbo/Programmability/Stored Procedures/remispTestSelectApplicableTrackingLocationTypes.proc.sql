ALTER PROCEDURE [dbo].[remispTestSelectApplicableTrackingLocationTypes] @TestID int
AS
BEGIN
	SELECT tlt.*   
	FROM trackinglocationtypes as tlt, TrackingLocationsForTests as tlfort
	WHERE tlfort.testid = @testid and tlt.ID = tlfort.TrackingLocationtypeID
	ORDER BY tlt.TrackingLocationTypeName asc
END
GO
GRANT EXECUTE ON remispTestSelectApplicableTrackingLocationTypes TO Remi
GO