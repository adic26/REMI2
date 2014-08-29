CREATE PROCEDURE [dbo].[remispDeviceTrackingLogInsertUpdateSingleItem]
/*	'===============================================================
	'   NAME:                	remispDeviceTrackingLogInsertUpdateSingleItem
	'   DATE CREATED:       	22 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates or updates an item in a table: DeviceTrackingLog
	'   IN:        ID, TestUnitId, TrackingLocationId, InTime, OutTime, InUser, OutUser  
	'   OUT: 		ID, ConcurrencyID         
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@ID int OUTPUT,
	@TestUnitId int, 
	@TrackingLocationId int, 
	@InTime datetime, 
	@InUser nvarchar(255), 
	@outuser nvarchar(255),
	@outtime datetime,
	@ConcurrencyID rowversion OUTPUT

	AS

	DECLARE @ReturnValue int

	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO DeviceTrackingLog
		(
			TestUnitId, 
			TrackingLocationId, 
			InTime, 
			OutTime,
			InUser,
			outuser
		)
		VALUES
		(
			@TestUnitId, 
			@TrackingLocationId, 
			@InTime, 
			@outtime,
			@InUser,
			@outuser
			
		)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE DeviceTrackingLog SET

		TestUnitId = @TestUnitId, 
		TrackingLocationID = @TrackingLocationID, 
		InTime = @InTime, 
		OutTime = @outtime,
		InUser = @InUser,
		outuser = @outuser
		WHERE 
			ID = @ID
			AND ConcurrencyID = @ConcurrencyID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM DeviceTrackingLog WHERE ID = @ReturnValue)
	SET @ID = @ReturnValue
	
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN 0
	END
