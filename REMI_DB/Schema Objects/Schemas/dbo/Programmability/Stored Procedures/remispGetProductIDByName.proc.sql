ALTER PROCEDURE [dbo].[remispGetProductIDByName] @ProductGroupName NVARCHAR(800)
AS
BEGIN
	SELECT ID, ProductGroupName
	FROM Products
	WHERE LTRIM(RTRIM(ProductGroupName))=LTRIM(RTRIM(@ProductGroupName))
END
GO
GRANT EXECUTE ON remispGetProductIDByName TO Remi
GO