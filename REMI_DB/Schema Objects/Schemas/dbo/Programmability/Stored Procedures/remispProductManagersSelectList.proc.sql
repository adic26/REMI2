ALTER PROCEDURE [dbo].[remispProductManagersSelectList] @UserID INT
AS
	SELECT lp.[values] AS ProductGroupName, p.ID  
	FROM UsersProducts AS uxpg
		INNER JOIN Products p ON p.ID=uxpg.ProductID
		INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
	WHERE uxpg.UserID = @UserID
	ORDER BY lp.[values] 
GO
GRANT EXECUTE ON remispProductManagersSelectList TO Remi
GO