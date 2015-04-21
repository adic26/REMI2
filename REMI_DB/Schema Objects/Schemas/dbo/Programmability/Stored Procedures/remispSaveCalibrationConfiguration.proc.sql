ALTER PROCEDURE [dbo].remispSaveCalibrationConfiguration @LookupID INT, @TestID INT, @HostID INT, @Name As NVARCHAR(150), @XML AS NTEXT, @LastUser As NVARCHAR(255)
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM Calibration WHERE TestID=@TestID AND LookupID=@LookupID And HostID=@HostID And Name=@Name)
	BEGIN
		INSERT INTO Calibration (HostID, LookupID, TestID, Name, DateCreated, [File], LastUser) Values (@HostID, @LookupID, @TestID, @Name, GETDATE(), CONVERT(XML, @XML), @LastUser)
	END
	ELSE
	BEGIN
		UPDATE Calibration
		SET [File]=CONVERT(XML, @XML), LastUser=@LastUser, DateCreated=GETDATE()
		WHERE TestID=@TestID AND LookupID=@LookupID And HostID=@HostID And Name=@Name
	END
END
GO
GRANT EXECUTE ON remispSaveCalibrationConfiguration TO REMI
GO