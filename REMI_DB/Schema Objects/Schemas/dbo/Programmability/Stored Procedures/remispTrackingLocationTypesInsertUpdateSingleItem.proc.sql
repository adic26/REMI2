ALTER PROCEDURE [dbo].[remispTrackingLocationTypesInsertUpdateSingleItem] @ID int OUTPUT, @TrackingLocationTypeName nvarchar (100), @WILocation nvarchar(800)=null,
	@UnitCapacity int, @Comment nvarchar(1000) = null, @TrackingLocationTypeFunction int, @LastUser nvarchar(255), @ConcurrencyID rowversion OUTPUT
AS
BEGIN
	DECLARE @ReturnValue int

	IF (@ID IS NULL AND NOT EXISTS (SELECT 1 FROM TrackingLocationTypes WHERE TrackingLocationTypeName=@TrackingLocationTypeName)) -- New Item
	BEGIN
		INSERT INTO TrackingLocationTypes (TrackingLocationTypeName, TrackingLocationFunction, Comment,WILocation,UnitCapacity,LastUser)
		VALUES (@TrackingLocationTypeName, @TrackingLocationTypeFunction, @Comment, @WILocation, @UnitCapacity, @LastUser)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE IF (@ConcurrencyID IS NOT NULL) -- Exisiting Item
	BEGIN
		UPDATE TrackingLocationTypes
		SET TrackingLocationTypeName = @TrackingLocationTypeName, TrackingLocationFunction = @TrackingLocationTypeFunction,
			Comment  =@Comment, WILocation = @WILocation, UnitCapacity = @UnitCapacity, LastUser = @LastUser
		WHERE ID = @ID AND ConcurrencyID = @ConcurrencyID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM TrackingLocationTypes WHERE ID = @ReturnValue)
	SET @ID = @ReturnValue
	
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN 0
	END
END
GO
GRANT EXECUTE ON [dbo].[remispTrackingLocationTypesInsertUpdateSingleItem] TO REMI
GO