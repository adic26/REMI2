CREATE PROCEDURE [dbo].[remispAddRemoveTypeToTest] @TestName NVARCHAR(256), @TrackingType NVARCHAR(256)
AS
BEGIN
	DECLARE @TestID INT
	DECLARE @TrackingTypeID INT

	SELECT @TestID = ID FROM Tests WHERE TestName=@TestName
	SELECT @TrackingTypeID = ID FROM TrackingLocationTypes WHERE TrackingLocationTypeName=@TrackingType

	IF EXISTS (SELECT 1 FROM TrackingLocationsForTests WHERE TestID=@TestID AND TrackingLocationtypeID=@TrackingTypeID)
		BEGIN
			DELETE FROM TrackingLocationsForTests WHERE TestID=@TestID AND TrackingLocationtypeID=@TrackingTypeID
		END
	ELSE
		BEGIN
			INSERT INTO TrackingLocationsForTests (TestID, TrackingLocationtypeID) VALUES (@TestID, @TrackingTypeID)
		END
END
GO
GRANT EXECUTE ON remispAddRemoveTypeToTest TO REMI
GO