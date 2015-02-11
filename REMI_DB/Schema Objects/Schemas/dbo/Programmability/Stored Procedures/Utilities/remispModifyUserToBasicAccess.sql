ALTER PROCEDURE [dbo].[remispModifyUserToBasicAccess] @UserName NVARCHAR(255)
AS
BEGIN
	DECLARE @UserID INT
	DECLARE @UserIDGuid UNIQUEIDENTIFIER
	DECLARE @RoleID UNIQUEIDENTIFIER
	SELECT @UserID=ID FROM Users WHERE LDAPLogin=@UserName
	SELECT @UserIDGuid = UserID FROM aspnet_Users WHERE UserName=@UserName
	SELECT @RoleID = RoleID FROM aspnet_Roles WHERE RoleName='LabTestAssociate'
	
	DELETE FROM UserDetails WHERE UserID=@UserID
	
	UPDATE Users SET ByPassProduct=0 WHERE ID=@UserID
	DELETE FROM UsersProducts WHERE UserID=@UserID
	DELETE FROM aspnet_UsersInRoles WHERE UserId=@UserIDGuid AND RoleId <> @RoleID
	DELETE FROM UserTraining WHERE UserID=@UserID
END
GO
GRANT EXECUTE ON [remispModifyUserToBasicAccess] TO REMI
GO