
ALTER procedure [dbo].[remispUsersSearch] @ProductID INT = 0, @TestCenterID INT = 0, @TrainingID INT = 0, @TrainingLevelID INT = 0, @showAllGrid BIT = 0, 
	@UserID INT = 0, @DepartmentID INT = 0, @DetermineDelete INT = 1,  @IncludeInActive INT = 1, @IsProductManager BIT = 0, @IsTSDContact BIT = 0, @ByPass INT = 0,
	@IsAdmin INT = 0, @IsTestCenterAdmin INT = 0
AS
BEGIN	
	IF (@showAllGrid = 0)
	BEGIN
		DECLARE @AdminRoleID UNIQUEIDENTIFIER
		DECLARE @TestCenterAdminRoleID UNIQUEIDENTIFIER
		
		SELECT @AdminRoleID = RoleID FROM aspnet_Roles WHERE RoleName='Administrator'
		SELECT @TestCenterAdminRoleID = RoleID FROM aspnet_Roles WHERE RoleName='TestCenterAdmin'

		SELECT ID, LDAPLogin, BadgeNumber, ByPassProduct, DefaultPage, ISNULL(IsActive, 1) AS IsActive, LastUser, 
				ConcurrencyID, CASE WHEN @DetermineDelete = 1 THEN dbo.remifnUserCanDelete(LDAPLogin) ELSE 0 END AS CanDelete
		FROM 
			(SELECT DISTINCT u.ID, u.LDAPLogin, u.BadgeNumber, u.ByPassProduct, u.DefaultPage, ISNULL(u.IsActive, 1) AS IsActive, u.LastUser, 
				u.ConcurrencyID
			 FROM Users u
				LEFT OUTER JOIN UserTraining ut WITH(NOLOCK) ON ut.UserID = u.ID
				INNER JOIN UserDetails udtc WITH(NOLOCK) ON udtc.UserID=u.ID
				INNER JOIN UserDetails udd WITH(NOLOCK) ON udd.UserID=u.ID
				LEFT OUTER JOIN UserDetails udp WITH(NOLOCK) ON udp.UserID=u.ID
				LEFT OUTER JOIN Lookups p WITH(NOLOCK) ON p.LookupID=udp.LookupID
				LEFT OUTER JOIN aspnet_Users au WITH(NOLOCK) ON au.UserName=u.LDAPLogin
			WHERE
				(
					(@IncludeInActive = 0 AND ISNULL(u.IsActive, 1)=1)
					OR
					@IncludeInActive = 1
				)
				AND 
				(
					(@TestCenterID > 0 AND @IsTestCenterAdmin = 1 AND udtc.LookupID=@TestCenterID AND au.UserId IN (SELECT UserId FROM aspnet_UsersInRoles WHERE RoleId=@TestCenterAdminRoleID))
					OR
					(@TestCenterID > 0 AND udtc.LookupID=@TestCenterID AND @IsTestCenterAdmin IN (0,2))
					OR
					(@TestCenterID = 0)
				)
				AND
				(
					(ut.LookupID=@TrainingID) 
					OR
					(@TrainingID = 0)
				)
				AND
				(
					(ut.LevelLookupID=@TrainingLevelID) 
					OR
					(@TrainingLevelID = 0)
				)
				AND
				(
					(p.LookupID=@ProductID) 
					OR
					(@ProductID = 0)
				)
				AND 
				(
					(udd.LookupID=@DepartmentID) 
					OR
					(@DepartmentID = 0)
				)
				AND
				(
					(@ByPass = 0)
					OR
					(@ByPass > 0 AND u.ByPassProduct = CASE @ByPass WHEN 1 THEN 1 WHEN 2 THEN 0 ELSE 0 END) 
				)
				AND
				(
					(@IsProductManager = 0)
					OR
					(@IsProductManager > 0 AND udp.IsProductManager = CASE @IsProductManager WHEN 1 THEN 1 WHEN 2 THEN 0 ELSE 0 END)
				)
				AND
				(
					(@IsTSDContact = 0)
					OR
					(@IsTSDContact > 0 AND udp.IsTSDContact = CASE @IsTSDContact WHEN 1 THEN 1 WHEN 2 THEN 0 ELSE 0 END)
				)
				AND
				(
					(@IsAdmin = 1 AND au.UserId IN (SELECT UserId FROM aspnet_UsersInRoles WHERE RoleId=@AdminRoleID))
					OR
					(@IsAdmin IN (0,2))
				)
			) AS UsersRows
			ORDER BY LDAPLogin
	END
	ELSE
	BEGIN
		DECLARE @rows VARCHAR(8000)
		DECLARE @query VARCHAR(4000)
		SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + l.[Values]
		FROM Lookups l
			INNER JOIN LookupType lt ON lt.LookupTypeID=l.LookupTypeID
		WHERE lt.Name='Training' And l.IsActive=1
		AND (
				(l.LookupID=@TrainingID) 
				OR
				(@TrainingID = 0)
			  )
		ORDER BY '],[' + l.[Values]
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

		SET @query = '
			SELECT *
			FROM
			(
				SELECT CASE WHEN ut.lookupID IS NOT NULL THEN (CASE WHEN ut.LevelLookupID IS NULL THEN ''*'' ELSE (SELECT SUBSTRING([values], 1, 1) FROM Lookups WHERE LookupID=LevelLookupID) END) ELSE NULL END As Row, u.LDAPLogin, l.[values] As Training
				FROM Users u WITH(NOLOCK)
					LEFT OUTER JOIN UserTraining ut ON ut.UserID = u.ID
					LEFT OUTER JOIN Lookups l on l.lookupid=ut.lookupid
					INNER JOIN UserDetails ud ON ud.UserID=u.ID
				WHERE u.IsActive = 1 AND (
				(ud.lookupid=' + CONVERT(VARCHAR, @TestCenterID) + ') 
				OR
				(' + CONVERT(VARCHAR, @TestCenterID) + ' = 0)
			  )
			  AND
			  (
				(ut.LookupID=' + CONVERT(VARCHAR, @TrainingID) + ') 
				OR
				(' + CONVERT(VARCHAR, @TrainingID) + ' = 0)
			  )
			  AND
			  (
				(u.ID=' + CONVERT(VARCHAR, @UserID) + ')
				OR
				(' + CONVERT(VARCHAR, @UserID) + ' = 0)
			  )
			)r
			PIVOT 
			(
				MAX(row) 
				FOR Training 
					IN ('+@rows+')
			) AS pvt'
		EXECUTE (@query)	
	END
END
GO
GRANT EXECUTE ON remispUsersSearch TO REMI
GO