ALTER PROCEDURE [dbo].[remispSaveLookup] @LookupType NVARCHAR(150), @Value NVARCHAR(150), @IsActive INT = 1, @Description NVARCHAR(200) = NULL, @ParentID INT = NULL, @Success AS BIT = NULL OUTPUT
AS
BEGIN
	DECLARE @LookupID INT
	DECLARE @LookupTypeID INT
	SELECT @LookupID = MAX(LookupID) + 1 FROM Lookups
	SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name=@LookupType

	IF (@ParentID = 0)
	BEGIN
		SET @ParentID = NULL
	END
	
	IF LTRIM(RTRIM(@Value)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups WHERE LookupTypeID=@LookupTypeID AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@Value)))
	BEGIN
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values], IsActive, Description, ParentID) 
		VALUES (@LookupID, @LookupTypeID, LTRIM(RTRIM(@Value)), @IsActive, @Description, @ParentID)
		
		SET @Success = 1
	END
	ELSE
	BEGIN
		UPDATE Lookups
		SET IsActive=@IsActive, Description=@Description, ParentID=@ParentID
		WHERE LookupTypeID=@LookupTypeID AND [values]=LTRIM(RTRIM(@Value))
		
		SET @Success = 1
	END

	PRINT @Success
END
GO
GRANT EXECUTE ON remispSaveLookup TO Remi
GO