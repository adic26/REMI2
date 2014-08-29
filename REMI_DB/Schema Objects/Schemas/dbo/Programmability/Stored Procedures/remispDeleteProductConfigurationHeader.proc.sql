ALTER PROCEDURE remispDeleteProductConfigurationHeader @PCID INT, @LastUser NVARCHAR(255)
AS
BEGIN
	IF (EXISTS (SELECT 1 FROM ProductConfiguration WHERE ID=@PCID) AND NOT EXISTS (SELECT 1 FROM ProductConfigValues WHERE ProductConfigID=@PCID))
	BEGIN
		DELETE FROM ProductConfiguration WHERE ID=@PCID
	END
	
	IF NOT EXISTS (SELECT 1 FROM ProductConfiguration WHERE ID=@PCID)
	BEGIN
		DELETE FROM ProductConfigurationUpload WHERE ID=@PCID
	END
END
GO
GRANT EXECUTE ON remispDeleteProductConfigurationHeader TO REMI
GO