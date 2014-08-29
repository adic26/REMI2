CREATE PROCEDURE [dbo].[remispTrackingLocationTypesInsertUpdateSingleItem]
/*	'===============================================================
	'   NAME:                	remispTrackingLocationTypesInsertUpdateSingleItem
	'   DATE CREATED:       	9 April 2009
	'   CREATED BY:          	Darragh O Riordan
	'   FUNCTION:            	Creates or updates an item in a table: TrackingLocationTypes     
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@ID int OUTPUT,
	
	@TrackingLocationTypeName nvarchar (100),
	@WILocation nvarchar(800)=null,
	@UnitCapacity int,
	@Comment nvarchar(1000) = null,
	@TrackingLocationTypeFunction int,
	@LastUser nvarchar(255),
	@ConcurrencyID rowversion OUTPUT
	
	
	AS

	DECLARE @ReturnValue int

	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO TrackingLocationTypes
		(
			TrackingLocationTypeName,
			TrackingLocationFunction,
			Comment,
			WILocation,
			UnitCapacity,
			LastUser
		)
		VALUES
		(
			@TrackingLocationTypeName,
			@TrackingLocationTypeFunction,
			@Comment,
			@WILocation,
			@UnitCapacity,
			@LastUser
		)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE TrackingLocationTypes SET
	TrackingLocationTypeName = @TrackingLocationTypeName,
	TrackingLocationFunction = @TrackingLocationTypeFunction,
			Comment  =@Comment,
			WILocation = @WILocation,
			UnitCapacity = @UnitCapacity,
			LastUser = @LastUser
		WHERE 
			ID = @ID
			AND ConcurrencyID = @ConcurrencyID

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

