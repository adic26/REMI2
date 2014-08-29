ALTER PROCEDURE remispSaveProductConfigurationDetails @PCID INT, @configID INT, @lookupID INT, @lookupValue NVARCHAR(2000), @LastUser NVARCHAR(255), @IsAttribute BIT = 0, @LookupAlt NVARCHAR(255)
AS
BEGIN
	IF (@lookupID = 0 AND LEN(LTRIM(RTRIM(@LookupAlt))) > 0)
	BEGIN
		SELECT @lookupID = LookupID FROM Lookups WHERE [values]=@LookupAlt AND Type='Configuration'
		
		IF (@lookupID IS NULL OR @lookupID = 0)
		BEGIN
			SELECT @lookupID = MAX(LookupID)+1 FROM Lookups
			
			INSERT INTO Lookups (LookupID, Type,[Values], IsActive) VALUES (@lookupID, 'Configuration', LTRIM(RTRIM(@LookupAlt)), 1)
		END
	END

	If ((@configID IS NULL OR @configID = 0 OR NOT EXISTS (SELECT 1 FROM ProductConfigValues WHERE ID=@configID)) AND @lookupValue IS NOT NULL AND LTRIM(RTRIM(@lookupValue)) <> '' AND @LookupID IS NOT NULL AND @LookupID > 0 AND EXISTS(SELECT 1 FROM ProductConfiguration WHERE ID=@PCID))
	BEGIN
		INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
		VALUES (@lookupValue, @LookupID, @PCID, @LastUser, ISNULL(@IsAttribute,0))
	END
	ELSE IF (@configID > 0)
	BEGIN
		UPDATE ProductConfigValues
		SET Value=@lookupValue, LookupID=@LookupID, LastUser=@LastUser, ProductConfigID=@PCID, IsAttribute=ISNULL(@IsAttribute,0)
		WHERE ID=@configID
	END
END
GO
GRANT EXECUTE ON remispSaveProductConfigurationDetails TO Remi
GO