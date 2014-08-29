ALTER PROCEDURE remispDeleteProductConfigurationDetail @ConfigID INT, @LastUser NVARCHAR(255)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM ProductConfigValues WHERE ID=@ConfigID)
	BEGIN
		DELETE FROM ProductConfigValues WHERE ID=@ConfigID
	END
END
GO
GRANT EXECUTE ON remispDeleteProductConfigurationDetail TO REMI
GO