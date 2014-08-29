ALTER PROCEDURE [dbo].remispProductConfigurationSaveXMLVersion @XML AS NTEXT, @LastUser As NVARCHAR(255), @PCUID INT
AS
BEGIN
	DECLARE @VersionNum INT
	DECLARE @DoInsert INT
	DECLARE @XMLPrev XML
	SELECT @VersionNum = ISNULL(MAX(VersionNum), 0) + 1 FROM ProductConfigurationVersion WHERE UploadID=@PCUID
	
	IF (@VersionNum > 1)
		BEGIN
			SELECT @XMLPrev = PCXML FROM ProductConfigurationVersion WHERE UploadID=@PCUID AND VersionNum = @VersionNum-1
		END
	ELSE
		BEGIN
			SET @XMLPrev = NULL
		END
	
	IF ((SELECT dbo.CompareXml(CONVERT(XML, @XML), @XMLPrev)) = 1)
		BEGIN
			INSERT INTO ProductConfigurationVersion (UploadID, PCXML, LastUser, VersionNum)
			VALUES (@PCUID, CONVERT(XML, @XML), @LastUser, @VersionNum)
		END
END
GO
GRANT EXECUTE ON remispProductConfigurationSaveXMLVersion TO REMI
GO