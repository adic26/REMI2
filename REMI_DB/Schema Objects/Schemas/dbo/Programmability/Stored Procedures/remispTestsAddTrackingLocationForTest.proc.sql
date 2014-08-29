ALTER PROCEDURE [dbo].[remispTestsAddTrackingLocationForTest] @TestID int, @TrackingLocationTypeID int
AS
declare @ID int

Set @id = (select ID from TrackingLocationsForTests where testid = @TestID and TrackingLocationtypeID = @TrackingLocationtypeID)
	
	DECLARE @ReturnValue int

	IF (@ID IS NULL) -- New Item so insert it
	BEGIN
		INSERT INTO TrackingLocationsForTests (TestID, TrackingLocationtypeid)
		VALUES (@TestID, @TrackingLocationtypeID)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
		
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN 0
	END
GO
GRANT EXECUTE ON remispTestsAddTrackingLocationForTest TO REMI
GO