CREATE PROCEDURE [dbo].[remispGetProductNameByID] @ProductID INT
AS
BEGIN
	SELECT ID, ProductGroupName
	FROM Products
	WHERE ID=@ProductID
END
GO
GRANT EXECUTE ON remispGetProductNameByID TO Remi
GO