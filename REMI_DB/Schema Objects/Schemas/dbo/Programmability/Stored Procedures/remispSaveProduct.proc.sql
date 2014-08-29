ALTER PROCEDURE [dbo].[remispSaveProduct] @ProductID int , @isActive int, @ProductGroupName NVARCHAR(150), @QAP NVARCHAR(255), @TSDContact NVARCHAR(255)
AS
BEGIN
	IF (@ProductID = 0)--ensure we don't have it
	BEGIN
		SELECT @ProductID = ID
		FROM Products
		WHERE LTRIM(RTRIM(ProductGroupName))=LTRIM(RTRIM(@ProductGroupName))
	END

	IF (@ProductID = 0)--if we still dont have it insert it
	BEGIN
		INSERT INTO Products (ProductGroupName, IsActive, QAPLocation, TSDContact) VALUES (LTRIM(RTRIM(@ProductGroupName)), CONVERT(BIT, @isActive), @QAP, @TSDContact)
	END
	ELSE
	BEGIN
		UPDATE Products
		SET IsActive = CONVERT(BIT, @isActive), ProductGroupName = @ProductGroupName, QAPLocation = @QAP, TSDContact = @TSDContact
		WHERE ID=@ProductID
	END
END
GRANT EXECUTE ON remispSaveProduct TO REMI
GO