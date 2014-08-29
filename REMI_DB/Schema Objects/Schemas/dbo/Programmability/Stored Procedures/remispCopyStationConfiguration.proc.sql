ALTER PROCEDURE remispCopyStationConfiguration @HostID INT, @copyFromHostID INT, @LastUser NVARCHAR(255), @ProfileID INT = NULL
AS
BEGIN
	BEGIN TRANSACTION

	BEGIN TRY	
		DECLARE @FromCount INT
		DECLARE @ToCount INT
		DECLARE @max INT
		DECLARE @copyFromProfileID INT
		SET @max = (SELECT MAX(ID) +1 FROM TrackingLocationsHostsConfiguration)
	
		SELECT TOP 1 @copyFromProfileID = TrackingLocationProfileID FROM TrackingLocationsHostsConfiguration WHERE TrackingLocationHostID=@copyFromHostID
	
		if (@copyFromProfileID = 0)
			SET @copyFromProfileID = NULL

		IF (@ProfileID = 0)
			SET @ProfileID = NULL
	
		SELECT @FromCount = COUNT(*) FROM TrackingLocationsHostsConfiguration WHERE TrackingLocationHostID=@copyFromHostID AND ((@copyFromProfileID IS NULL AND TrackingLocationProfileID IS NULL) OR (TrackingLocationProfileID=@copyFromProfileID AND @copyFromProfileID IS NOT NULL))
	
		SELECT tempID=IDENTITY (int, 1, 1), CONVERT(int,ID) As ID, ParentId, ViewOrder, NodeName, @HostID AS TrackingLocationHostID, @LastUser AS LastUser, 0 AS newproID, NULL AS newParentID, @ProfileID As TrackingLocationProfileID
		INTO #TrackingLocationsHostsConfiguration
		FROM TrackingLocationsHostsConfiguration
		WHERE TrackingLocationHostID=@copyFromHostID AND ((@copyFromProfileID IS NULL AND TrackingLocationProfileID IS NULL) OR (TrackingLocationProfileID=@copyFromProfileID AND @copyFromProfileID IS NOT NULL))
	
		UPDATE #TrackingLocationsHostsConfiguration SET newproID=@max+tempid
	
		UPDATE #TrackingLocationsHostsConfiguration 
		SET #TrackingLocationsHostsConfiguration.newParentID = pc2.newproID
		FROM #TrackingLocationsHostsConfiguration
			LEFT OUTER JOIN #TrackingLocationsHostsConfiguration pc2 ON #TrackingLocationsHostsConfiguration.ParentID=pc2.ID
		
		SET Identity_Insert TrackingLocationsHostsConfiguration ON
	
		INSERT INTO TrackingLocationsHostsConfiguration (ID, ParentId, ViewOrder, NodeName, TrackingLocationHostID, LastUser, TrackingLocationProfileID)
		SELECT newproID, newParentId, ViewOrder, NodeName, TrackingLocationHostID, LastUser, TrackingLocationProfileID
		FROM #TrackingLocationsHostsConfiguration
	
		SET Identity_Insert TrackingLocationsHostsConfiguration OFF
	
		SELECT @ToCount = COUNT(*) FROM TrackingLocationsHostsConfiguration WHERE TrackingLocationHostID=@HostID

		IF (@FromCount = @ToCount)
		BEGIN
			SELECT @FromCount = COUNT(*) 
			FROM TrackingLocationsHostsConfiguration pc 
				INNER JOIN TrackingLocationsHostsConfigValues pcv ON pc.ID=pcv.TrackingConfigID 
			WHERE TrackingLocationHostID=@copyFromHostID AND ((@copyFromProfileID IS NULL AND TrackingLocationProfileID IS NULL) OR (TrackingLocationProfileID=@copyFromProfileID AND @copyFromProfileID IS NOT NULL))
	
			INSERT INTO TrackingLocationsHostsConfigValues (Value, LookupID, TrackingConfigID, LastUser, IsAttribute)
			SELECT Value, LookupID, #TrackingLocationsHostsConfiguration.newproID AS TrackingConfigID, @LastUser AS LastUser, IsAttribute
			FROM TrackingLocationsHostsConfigValues
				INNER JOIN TrackingLocationsHostsConfiguration ON TrackingLocationsHostsConfigValues.TrackingConfigID=TrackingLocationsHostsConfiguration.ID
				INNER JOIN #TrackingLocationsHostsConfiguration ON TrackingLocationsHostsConfiguration.ID=#TrackingLocationsHostsConfiguration.ID	
		
			SELECT @ToCount = COUNT(*) 
			FROM TrackingLocationsHostsConfiguration pc 
				INNER JOIN TrackingLocationsHostsConfigValues pcv ON pc.ID=pcv.TrackingConfigID 
			WHERE TrackingLocationHostID=@HostID AND ((@copyFromProfileID IS NULL AND TrackingLocationProfileID IS NULL) OR (TrackingLocationProfileID=@copyFromProfileID AND @copyFromProfileID IS NOT NULL))
		
			IF (@FromCount <> @ToCount)
			BEGIN
				GOTO HANDLE_ERROR
			END
			GOTO HANDLE_SUCESS
		END
		ELSE
		BEGIN
			GOTO HANDLE_ERROR
		END
	END TRY
	BEGIN CATCH
		  SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_SEVERITY() AS ErrorSeverity, ERROR_STATE() as ErrorState, ERROR_PROCEDURE() as ErrorProcedure, ERROR_LINE() as ErrorLine, ERROR_MESSAGE() as ErrorMessage

		  GOTO HANDLE_ERROR
	END CATCH
	
	HANDLE_SUCESS:
		IF @@TRANCOUNT > 0
			COMMIT TRANSACTION
			RETURN	
	
	HANDLE_ERROR:
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION
			RETURN	
    
END
GO
GRANT EXECUTE ON remispCopyStationConfiguration TO REMI
GO