ALTER PROCEDURE [dbo].[remispGetProductIDByName] @ProductGroupName NVARCHAR(800)
AS
BEGIN
	SELECT ID, lp.[values] AS ProductGroupName
	FROM Products p
		INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
	WHERE LTRIM(RTRIM(lp.[values]))=LTRIM(RTRIM(@ProductGroupName))
END
GO
GRANT EXECUTE ON remispGetProductIDByName TO Remi
GO