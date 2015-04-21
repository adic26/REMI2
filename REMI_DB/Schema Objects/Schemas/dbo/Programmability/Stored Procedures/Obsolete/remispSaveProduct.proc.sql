ALTER PROCEDURE [dbo].[remispSaveProduct] @LookupID int , @isActive int, @ProductGroupName NVARCHAR(150), @QAP NVARCHAR(255), @Success AS BIT = NULL OUTPUT
AS
BEGIN
	IF (@LookupID = 0)--ensure we don't have it
	BEGIN
		SELECT @LookupID = ID
		FROM Products p
			INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
		WHERE LTRIM(RTRIM(lp.[values]))=LTRIM(RTRIM(@ProductGroupName))
	END

	IF (@LookupID = 0)--if we still dont have it insert it
	BEGIN
		DECLARE @LookupTypeID INT
		SELECT @LookupID = MAX(LookupID)+1 FROM Lookups
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Products'		
				
		INSERT INTO Lookups ([Values], LookupID, IsActive) VALUES (LTRIM(RTRIM(@ProductGroupName)), @LookupID, 1)
		INSERT INTO Products (LookupID, QAPLocation) 
		VALUES (@LookupID, @QAP)

		SET @Success = 1
	END
	ELSE
	BEGIN
		UPDATE Products
		SET QAPLocation = @QAP
		WHERE LookupID=@LookupID

		SET @Success = 1
	END
END
GRANT EXECUTE ON remispSaveProduct TO REMI
GO