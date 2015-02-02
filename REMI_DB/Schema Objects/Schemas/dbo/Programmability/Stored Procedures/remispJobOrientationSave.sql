ALTER PROCEDURE [dbo].[remispJobOrientationSave] @ID INT = 0, @Name NVARCHAR(150), @JobID INT, @ProductTypeID INT, @Description NVARCHAR(250), @IsActive BIT, @Definition NTEXT = NULL, @Success AS BIT = NULL OUTPUT
AS
BEGIN
	IF (@ID = 0)
	BEGIN
		DECLARE @XML XML
		DECLARE @NumUnits INT
		DECLARE @NumDrops INT
		SELECT @XML = CONVERT(XML, @Definition)
		
		SELECT @NumUnits=MAX(T.c.value('(@Unit)[1]', 'int')), @NumDrops =MAX(T.c.value('(@Drop)[1]', 'int'))
		FROM @XML.nodes('/Orientations/Orientation') as T(c)

		IF (@NumUnits IS NULL)
		BEGIN
			SET @NumUnits = 0
		END
		
		IF (@NumDrops IS NULL)
		BEGIN
			SET @NumDrops = 0
		END
				
		INSERT INTO JobOrientation (JobID, ProductTypeID, NumUnits, NumDrops, Description, IsActive, Definition, Name)
		VALUES (@JobID, @ProductTypeID, @NumUnits, @NumDrops, @Description, @IsActive, @XML, @Name)

		SET @Success = 1
	END
	ELSE
	BEGIN
		UPDATE JobOrientation
		SET IsActive = @IsActive, Name = @Name, Description=@Description, ProductTypeID=@ProductTypeID
		WHERE ID=@ID

		SET @Success = 1
	END
END
GO
GRANT EXECUTE ON [dbo].[remispJobOrientationSave] TO REMI
GO
