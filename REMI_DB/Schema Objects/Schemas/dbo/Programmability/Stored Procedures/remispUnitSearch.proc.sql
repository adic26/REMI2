ALTER procedure [dbo].[remispUnitSearch] @BSN INT=0, @IMEI NVARCHAR(150)= NULL
AS
BEGIN
	SELECT b.QRANumber, tu.BatchUnitNumber
	FROM Batches b
		INNER JOIN TestUnits tu ON tu.BatchID=b.ID
	WHERE (@BSN > 0 AND tu.BSN=@BSN)
		OR
		(@IMEI IS NOT NULL AND tu.IMEI=@IMEI)
END
GO
GRANT EXECUTE ON remispUnitSearch TO REMI
GO