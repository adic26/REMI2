ALTER PROCEDURE [dbo].[remispSaveLookup] @LookupType NVARCHAR(150), @Value NVARCHAR(150), @IsActive INT = 1, @Description NVARCHAR(200) = NULL, @ParentID INT = NULL
AS
BEGIN
	DECLARE @LookupID INT
	SELECT @LookupID = MAX(LookupID) + 1 FROM Lookups

	IF (@ParentID = 0)
	BEGIN
		SET @ParentID = NULL
	END
	
	IF LTRIM(RTRIM(@Value)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups WHERE Type=@LookupType AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@Value)))
	BEGIN
		INSERT INTO Lookups (LookupID, Type, [Values], IsActive, Description, ParentID) 
		VALUES (@LookupID, @LookupType, LTRIM(RTRIM(@Value)), @IsActive, @Description, @ParentID)
	END
	ELSE
	BEGIN
		UPDATE Lookups
		SET IsActive=@IsActive, Description=@Description, ParentID=@ParentID
		WHERE Type=@LookupType AND [values]=LTRIM(RTRIM(@Value))
	END
END
GO
GRANT EXECUTE ON remispSaveLookup TO Remi
GO