CREATE PROCEDURE [dbo].[remispTrackingLocationTypePermissionsInsertUpdateSingleItem]
/*	'===============================================================
	'   NAME:                	remispTrackingLocationTypePermissionsInsertUpdateSingleItem
	'   DATE CREATED:       	8 Sept 2011
	'   CREATED BY:          	Darragh O Riordan
	'   FUNCTION:            	Creates or updates an item in a table: TrackingLocationTypePermissions     
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	
	@TrackingLocationTypeID int,
	@PermissionBitMask int,
	@Username nvarchar(255),
	
	@LastUser nvarchar(255),
	@ConcurrencyID rowversion OUTPUT
		
	AS
	--check if there is already a record for this user at this station
	declare @id int = (select id from TrackingLocationTypePermissions where TrackingLocationTypeID = @TrackingLocationTypeID and Username = @Username)
	DECLARE @ReturnValue int
	
	
	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO TrackingLocationTypePermissions
		(
			TrackingLocationTypeID,
			PermissionBitMask,
			Username,
			LastUser
		)
		VALUES
		(
			@TrackingLocationTypeID,
			@PermissionBitMask,
			@Username,
			@LastUser
		)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE TrackingLocationTypePermissions SET
		
			PermissionBitMask = @PermissionBitMask,
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

