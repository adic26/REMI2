ALTER PROCEDURE [dbo].[remispTrackingLocationsInsertUpdateSingleItem]
	@ID int OUTPUT,
	@trackingLocationName nvarchar(400),
	@TrackingLocationTypeID int, 
	@GeoLocationID INT, 
	@ConcurrencyID rowversion OUTPUT,
	@Status int,
	@LastUser nvarchar(255),
	@Comment nvarchar(1000) = null,
	@HostName nvarchar(255) = null,
	@Decommissioned BIT = 0,
	@IsMultiDeviceZone BIT = 0,
	@LocationStatus INT
AS
	DECLARE @ReturnValue int
	DECLARE @AlreadyExists as integer 

	IF (@ID IS NULL) -- New Item
	BEGIN
		IF (@ID IS NULL) -- New Item
		BEGIN
			set @AlreadyExists = (select ID from TrackingLocations 
			where TrackingLocationName = LTRIM(RTRIM(@trackingLocationName)) and TestCenterLocationID = @GeoLocationID)

			if (@AlreadyExists is not null) 
				return -1
			end

			PRINT 'INSERTING'

			INSERT INTO TrackingLocations (TrackingLocationName, TestCenterLocationID, TrackingLocationTypeID, LastUser, Comment, Decommissioned, IsMultiDeviceZone, Status)
			VALUES (LTRIM(RTRIM(@TrackingLocationname)), @GeoLocationID, @TrackingLocationtypeID, @LastUser, LTRIM(RTRIM(@Comment)), @Decommissioned, @IsMultiDeviceZone, @LocationStatus)
			
			SELECT @ReturnValue = SCOPE_IDENTITY()

			INSERT INTO TrackingLocationsHosts (TrackingLocationID, HostName, LastUser, [Status]) 
			VALUES (@ReturnValue, LTRIM(RTRIM(@HostName)), @LastUser, @Status)
		END
		ELSE -- Exisiting Item
		BEGIN
			PRINT 'UDPATING TrackingLocations'
		
			UPDATE TrackingLocations 
			SET TrackingLocationName=LTRIM(RTRIM(@TrackingLocationName)) ,
				TestCenterLocationID=@GeoLocationID, 
				TrackingLocationTypeID=@TrackingLocationtypeID,
				LastUser = @LastUser,
				Comment = LTRIM(RTRIM(@Comment)),
				Decommissioned = @Decommissioned,
				IsMultiDeviceZone = @IsMultiDeviceZone,
				Status = @LocationStatus
			WHERE ID = @ID AND ConcurrencyID = @ConcurrencyID
		
			SELECT @ReturnValue = @ID
		END

		SET @ConcurrencyID = (SELECT ConcurrencyID FROM TrackingLocations WHERE ID = @ReturnValue)
		SET @ID = @ReturnValue
	
		IF (@@ERROR != 0)
		BEGIN
			RETURN -1
		END
		ELSE
		BEGIN
			RETURN 0
		END
GO
GRANT EXECUTE ON remispTrackingLocationsInsertUpdateSingleItem TO Remi
GO