ALTER PROCEDURE remispRolePermissions
AS
BEGIN
	DECLARE @rows VARCHAR(8000)
	DECLARE @query VARCHAR(4000)
	SELECT @rows=  ISNULL(STUFF(
	( 
	SELECT DISTINCT '],[' + r.RoleName
	FROM  dbo.aspnet_Roles r WITH(NOLOCK)
	ORDER BY '],[' +  r.RoleName
	FOR XML PATH('')), 1, 2, '') + ']','[na]')


	SET @query = '
		SELECT *
		FROM
		(
			SELECT CASE WHEN pr.PermissionID IS NOT NULL THEN 1 ELSE NULL END As Row, p.Permission, r.RoleName
			FROM dbo.aspnet_Roles r WITH(NOLOCK)
				LEFT OUTER JOIN dbo.aspnet_PermissionsInRoles pr WITH(NOLOCK) on r.RoleId=pr.RoleID
				INNER JOIN dbo.aspnet_Permissions p WITH(NOLOCK) on pr.PermissionID=p.PermissionID
			WHERE p.Permission IS NOT NULL
		)r
		PIVOT 
		(
			MAX(row) 
			FOR RoleName 
				IN ('+@rows+')
		) AS pvt'
	EXECUTE (@query)
END
GO
GRANT EXECUTE ON remispRolePermissions TO REMI
GO