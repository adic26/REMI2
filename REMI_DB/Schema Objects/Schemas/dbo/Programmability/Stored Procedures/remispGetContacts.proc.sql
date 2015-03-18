ALTER PROCEDURE dbo.remispGetContacts @ProductID INT
AS
BEGIN
	DECLARE @TSDContact NVARCHAR(255)
	
	SELECT @TSDContact = p.TSDContact
	FROM Products p
	WHERE p.ID=@ProductID
	
	SELECT us.LDAPLogin, @TSDContact AS TSDContact
	FROM aspnet_Users u
		INNER JOIN aspnet_UsersInRoles ur ON u.UserId=ur.UserId
		INNER JOIN aspnet_Roles r ON r.RoleId=ur.RoleId
		INNER JOIN Users us ON us.LDAPLogin = u.UserName
		INNER JOIN UsersProducts up ON up.UserID=us.ID
	WHERE r.RoleName='ProjectManager' AND CONVERT(BIT, r.hasProductCheck) = 1 AND up.ProductID=@ProductID
END
GO
GRANT EXECUTE ON [dbo].remispGetContacts TO REMI
GO