ALTER PROCEDURE [dbo].[remispUsersDeleteSingleItem] @userIDToDelete nvarchar(255), @UserID INT
AS
	UPDATE Users 
	SET LastUser = (SELECT LDAPLogin FROM Users WHERE ID=@UserID)
	WHERE ID = @userIDToDelete

	DELETE FROM UserSearchFilter WHERE UserID = @userIDToDelete
	DELETE FROM UserDetails WHERE UserID=@userIDToDelete
	DELETE FROM UserTraining WHERE UserID=@userIDToDelete
	DELETE FROM users WHERE ID = @userIDToDelete
GO
GRANT EXECUTE ON remispUsersDeleteSingleItem TO Remi
GO