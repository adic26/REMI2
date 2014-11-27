ALTER PROCEDURE [dbo].[aspnet_GetPermissions] @ApplicationName nvarchar(256)
AS
BEGIN
	DECLARE @ApplicationId uniqueidentifier
	SELECT  @ApplicationId = NULL
	SELECT  @ApplicationId = ApplicationId FROM aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
	
	IF (@ApplicationId IS NULL)
		RETURN

	SELECT p.PermissionID, p.Permission
	FROM aspnet_Permissions p
	ORDER BY p.Permission
END
GO
GRANT EXECUTE ON [aspnet_GetPermissions] TO REMI
GO