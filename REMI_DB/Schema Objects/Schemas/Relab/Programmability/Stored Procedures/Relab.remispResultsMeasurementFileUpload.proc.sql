ALTER PROCEDURE Relab.remispResultsMeasurementFileUpload @File VARBINARY(MAX), @ContentType NVARCHAR(50), @FileName NVARCHAR(200), @Success AS BIT = NULL OUTPUT
AS
BEGIN
	IF (DATALENGTH(@File) > 0)
	BEGIN
		INSERT INTO Relab.ResultsMeasurementsFiles ( ResultMeasurementID, [File], ContentType, FileName)
		VALUES (NULL, @File, @ContentType, @FileName)
		SET @Success = 1
	END
	ELSE
	BEGIN
		SET @Success = 0
	END

	PRINT @Success
END
GO
GRANT EXECUTE ON Relab.remispResultsMeasurementFileUpload TO REMI
GO