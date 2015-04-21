ALTER PROCEDURE [dbo].[remispGetProductNameByID] @ProductID INT
AS
BEGIN
	SELECT ID, lp.[Values] AS ProductGroupName
	FROM Products p
		INNER JOIN Lookups lp ON lp.LookupID=p.LookupID
	WHERE ID=@ProductID
END
GO
GRANT EXECUTE ON remispGetProductNameByID TO Remi
GO