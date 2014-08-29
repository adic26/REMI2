ALTER procedure [dbo].[remispUnitSearch] @BSN INT
AS
BEGIN
	SELECT b.QRANumber, tu.BatchUnitNumber
	FROM Batches b
		INNER JOIN TestUnits tu ON tu.BatchID=b.ID
	WHERE tu.BSN=@BSN
END
GO
GRANT EXECUTE ON remispUnitSearch TO REMI
GO