ALTER PROCEDURE [dbo].[remispDeleteProductConfiguration] @PCUID INT, @LastUser NVARCHAR(255)
AS
BEGIN
	UPDATE ProductConfigValues 
	SET LastUser=@LastUser
	WHERE ProductConfigID IN (SELECT pc.ID FROM ProductConfiguration pc WHERE pc.UploadID=@PCUID)
	
	UPDATE pc 
	SET LastUser=@LastUser
	FROM ProductConfiguration pc
	WHERE pc.UploadID=@PCUID
	
	DELETE FROM ProductConfigValues WHERE ProductConfigID IN (SELECT ID FROM ProductConfiguration WHERE UploadID=@PCUID)
	DELETE ProductConfiguration FROM ProductConfiguration WHERE UploadID=@PCUID
	DELETE FROM ProductConfigurationVersion WHERE UploadID=@PCUID
	DELETE FROM ProductConfigurationUpload WHERE ID=@PCUID
END
GO
GRANT EXECUTE ON remispDeleteProductConfiguration TO REMI
GO