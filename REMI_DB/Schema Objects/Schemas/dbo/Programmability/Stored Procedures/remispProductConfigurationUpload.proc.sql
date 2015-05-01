ALTER PROCEDURE [dbo].remispProductConfigurationUpload @LookupID INT, @TestID INT, @XML AS NTEXT, @LastUser As NVARCHAR(255), @PCName NVARCHAR(200) = NULL
AS
BEGIN
	IF (@PCName IS NULL OR LTRIM(RTRIM(@PCName)) = '') --Get The Root Name Of the XML
	BEGIN
		DECLARE @xmlTemp XML = CONVERT(XML, @XML)
		SELECT @PCName= LTRIM(RTRIM(x.c.value('local-name(/*[1])','nvarchar(max)')))
		FROM @xmlTemp.nodes('/*') x ( c )
		
		IF (@PCName = '')
		BEGIN
			SET @PCName = 'ProductConfiguration'
		END
	END

	IF EXISTS (SELECT 1 FROM ProductConfigurationUpload WHERE TestID=@TestID AND LookupID=@LookupID AND PCName=@PCName)
	BEGIN
		DECLARE @increment INT
		DECLARE @PCNameTemp NVARCHAR(200)
		SET @PCNameTemp = @PCName
		SET @increment = 1
		
		WHILE EXISTS (SELECT 1 FROM ProductConfigurationUpload WHERE TestID=@TestID AND LookupID=@LookupID AND PCName=@PCNameTemp)
		BEGIN
			SET @PCNameTemp = @PCName + CONVERT(NVARCHAR, @increment)
			SET @increment = @increment + 1
			print @PCNameTemp
		END
		
		SET @PCName = @PCNameTemp
	END
	
	IF NOT EXISTS (SELECT 1 FROM ProductConfigurationUpload WHERE TestID=@TestID AND LookupID=@LookupID AND PCName=@PCName)
	BEGIN
		INSERT INTO ProductConfigurationUpload (IsProcessed, LookupID, TestID, LastUser, PCName) 
		Values (CONVERT(BIT, 0), @LookupID, @TestID, @LastUser, @PCName)
		
		DECLARE @UploadID INT
		SET @UploadID =  @@IDENTITY

		EXEC remispProductConfigurationSaveXMLVersion @XML, @LastUser, @UploadID
	END
END
GO
GRANT EXECUTE ON remispProductConfigurationUpload TO REMI
GO