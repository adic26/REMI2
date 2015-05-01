ALTER PROCEDURE remispCopyTestConfiguration @LookupID INT, @TestID INT, @copyFromLookupID INT, @LastUser NVARCHAR(255)
AS
BEGIN
	BEGIN TRANSACTION
	
	BEGIN TRY
		DECLARE @FromCount INT
		DECLARE @ToCount INT
		DECLARE @max INT
		DECLARE @UploadID INT
		SET @max = (SELECT MAX(ID) +1 FROM ProductConfiguration)
		
		SELECT @FromCount = COUNT(*) 
		FROM ProductConfiguration pc
			INNER JOIN ProductConfigurationUpload u ON u.ID=pc.UploadID
		WHERE TestID=@TestID AND u.LookupID=@copyFromLookupID
		
		SELECT tempID=IDENTITY (int, 1, 1), CONVERT(int,pc.ID) As ID, ParentId, ViewOrder, NodeName, @TestID AS TestID, @LookupID AS ProductID, @LastUser AS LastUser, 0 AS newproID, NULL AS newParentID
		INTO #ProductConfiguration
		FROM ProductConfiguration pc
			INNER JOIN ProductConfigurationUpload u ON u.ID=pc.UploadID
		WHERE u.TestID=@TestID AND u.LookupID=@copyFromLookupID
		
		IF ((SELECT COUNT(*) FROM #ProductConfiguration) > 0)
		BEGIN
			UPDATE #ProductConfiguration SET newproID=@max+tempid
			
			UPDATE #ProductConfiguration 
			SET #ProductConfiguration.newParentID = pc2.newproID
			FROM #ProductConfiguration
				LEFT OUTER JOIN #ProductConfiguration pc2 ON #ProductConfiguration.ParentID=pc2.ID
				
			INSERT INTO ProductConfigurationUpload (IsProcessed, LastUser, TestID, PCName, LookupID)
			SELECT 1 AS IsProcessed, @LastUser AS LastUser, c.TestID, c.PCName, @LookupID AS LookupID
			FROM ProductConfigurationUpload c
			WHERE c.TestID=@TestID AND c.LookupID=@copyFromLookupID
			
			SELECT @UploadID = c.ID
			FROM ProductConfigurationUpload c
			WHERE c.TestID=@TestID AND c.LookupID=@LookupID
				
			SET Identity_Insert ProductConfiguration ON
			
			INSERT INTO ProductConfiguration (ID, ParentId, ViewOrder, NodeName, LastUser, UploadID)
			SELECT newproID, newParentId, ViewOrder, NodeName, LastUser, @UploadID AS UploadID
			FROM #ProductConfiguration
			
			SET Identity_Insert ProductConfiguration OFF
			
			SELECT @ToCount = COUNT(*) 
			FROM ProductConfiguration pc
				INNER JOIN ProductConfigurationUpload u ON u.ID=pc.UploadID
			WHERE u.TestID=@TestID AND u.LookupID=@LookupID

			IF (@FromCount = @ToCount)
			BEGIN
				SELECT @FromCount = COUNT(*) 
				FROM ProductConfiguration pc 
					INNER JOIN ProductConfigValues pcv ON pc.ID=pcv.ProductConfigID
					INNER JOIN ProductConfigurationUpload u ON u.ID=pc.UploadID
				WHERE u.TestID=@TestID AND u.LookupID=@copyFromLookupID
			
				INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
				SELECT Value, LookupID, #ProductConfiguration.newproID AS ProductConfigID, @LastUser AS LastUser, IsAttribute
				FROM ProductConfigValues
					INNER JOIN ProductConfiguration ON ProductConfigValues.ProductConfigID=ProductConfiguration.ID
					INNER JOIN #ProductConfiguration ON ProductConfiguration.ID=#ProductConfiguration.ID	
					
				SELECT @ToCount = COUNT(*) 
				FROM ProductConfiguration pc
					INNER JOIN ProductConfigValues pcv ON pc.ID=pcv.ProductConfigID 
					INNER JOIN ProductConfigurationUpload u ON u.ID=pc.UploadID
				WHERE u.TestID=@TestID AND u.LookupID=@LookupID
				
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
		END
		ELSE
		BEGIN
			GOTO HANDLE_SUCESS
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
GRANT EXECUTE ON remispCopyTestConfiguration TO REMI
GO