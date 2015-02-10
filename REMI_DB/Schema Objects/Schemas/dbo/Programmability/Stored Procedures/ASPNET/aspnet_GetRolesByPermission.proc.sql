ALTER PROCEDURE [dbo].[aspnet_GetRolesByPermission] @ApplicationName nvarchar(256), @PermissionName nvarchar(256)
AS
BEGIN
	DECLARE @ApplicationId uniqueidentifier
	SELECT  @ApplicationId = NULL
	SELECT  @ApplicationId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
	
	IF (@ApplicationId IS NULL)
		RETURN

	DECLARE @PermissionID uniqueidentifier

	SELECT @PermissionID = PermissionID
	FROM dbo.aspnet_Permissions
	WHERE Permission=@PermissionName AND ApplicationId = @ApplicationId

	IF (@PermissionID IS NULL)
		RETURN

	SELECT r.RoleName, ISNULL(r.hasProductCheck,0) AS hasProductCheck
	FROM aspnet_Permissions p
		INNER JOIN aspnet_PermissionsInRoles pr ON pr.PermissionID=p.PermissionID
		INNER JOIN aspnet_Roles r ON pr.RoleID=r.RoleId
	WHERE pr.PermissionID=@PermissionID
END
GO
GRANT EXECUTE ON aspnet_GetRolesByPermission TO REMI
GO