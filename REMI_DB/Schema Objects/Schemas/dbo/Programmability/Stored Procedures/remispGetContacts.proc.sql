ALTER PROCEDURE dbo.remispGetContacts @ProductID INT
AS
BEGIN
	DECLARE @ProductManager NVARCHAR(255)
	DECLARE @TSDContact NVARCHAR(255)
	
	SELECT @ProductManager = us.LDAPLogin 
	FROM aspnet_Users u
		INNER JOIN aspnet_UsersInRoles ur ON u.UserId=ur.UserId
		INNER JOIN aspnet_Roles r ON r.RoleId=ur.RoleId
		INNER JOIN Users us ON us.LDAPLogin = u.UserName
		INNER JOIN UsersProducts up ON up.UserID=us.ID
	WHERE r.RoleName='ProjectManager' AND CONVERT(BIT, r.hasProductCheck) = 1 AND up.ProductID=@ProductID
	
	SELECT @TSDContact = p.TSDContact
	FROM Products p
	WHERE p.ID=@ProductID
	
	SELECT @ProductManager AS ProductManager, @TSDContact AS TSDContact
END
GO
GRANT EXECUTE ON [dbo].remispGetContacts TO REMI
GO