ALTER PROCEDURE remispAddRemovePermissiontoRole @Permission NVARCHAR(256), @Role NVARCHAR(256), @Success AS BIT = NULL OUTPUT
AS
BEGIN
	DECLARE @RoleID UNIQUEIDENTIFIER
	DECLARE @PermissionID UNIQUEIDENTIFIER

	SELECT @PermissionID = PermissionID FROM aspnet_Permissions WHERE Permission=@Permission
	SELECT @RoleID = RoleID FROM aspnet_Roles WHERE RoleName=@Role
	
	IF EXISTS (SELECT 1 FROM aspnet_PermissionsInRoles WHERE PermissionID=@PermissionID AND RoleID=@RoleID)
		BEGIN
			DELETE FROM aspnet_PermissionsInRoles WHERE PermissionID=@PermissionID AND RoleID=@RoleID
			SET @Success = 1
		END
	ELSE
		BEGIN
			INSERT INTO aspnet_PermissionsInRoles (PermissionID, RoleID) VALUES (@PermissionID, @RoleID)
			SET @Success = 1
		END
END
GO
GRANT EXECUTE ON remispAddRemovePermissiontoRole TO REMI
GO