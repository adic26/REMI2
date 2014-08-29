ALTER PROCEDURE [dbo].[remispProductManagersSelectList] @UserID INT
AS
	SELECT p.ProductGroupName, p.ID  
	FROM UsersProducts AS uxpg
		INNER JOIN Products p ON p.ID=uxpg.ProductID
	WHERE uxpg.UserID = @UserID
	ORDER BY p.ProductGroupName
GO
GRANT EXECUTE ON remispProductManagersSelectList TO Remi
GO