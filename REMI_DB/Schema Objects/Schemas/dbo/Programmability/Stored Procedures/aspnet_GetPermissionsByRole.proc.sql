ALTER PROCEDURE [dbo].[aspnet_GetPermissionsByRole] @ApplicationName nvarchar(256), @RoleName nvarchar(256)
AS
BEGIN
	DECLARE @ApplicationId uniqueidentifier
	SELECT  @ApplicationId = NULL
	SELECT  @ApplicationId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
	
	IF (@ApplicationId IS NULL)
		RETURN

	DECLARE @RoleId uniqueidentifier

	SELECT @RoleId = RoleId
	FROM dbo.aspnet_Roles
	WHERE LOWER(@RoleName) = LoweredRoleName AND ApplicationId = @ApplicationId

	IF (@RoleId IS NULL)
		RETURN

	SELECT Permission
	FROM aspnet_Permissions p
		INNER JOIN aspnet_PermissionsInRoles pr ON pr.PermissionID=p.PermissionID
	WHERE pr.RoleId = @RoleId
END
GO
GRANT EXECUTE ON [aspnet_GetPermissionsByRole] TO REMI
GO