ALTER PROCEDURE Relab.remispResultsMeasurementFileUpload @File VARBINARY(MAX), @ContentType NVARCHAR(50), @FileName NVARCHAR(200)
AS
BEGIN
	IF (DATALENGTH(@File) > 0)
	BEGIN
		INSERT INTO Relab.ResultsMeasurementsFiles ( ResultMeasurementID, [File], ContentType, FileName)
		VALUES (NULL, @File, @ContentType, @FileName)
	END
END
GO
GRANT EXECUTE ON Relab.remispResultsMeasurementFileUpload TO REMI
GO