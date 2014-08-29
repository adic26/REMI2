ALTER PROCEDURE [dbo].[remispUsersSelectList]
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@determineDelete INT = 1,
	@RecordCount int = NULL OUTPUT
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Users)
		RETURN
	END

	SELECT UsersRows.BadgeNumber,UsersRows.ConcurrencyID,UsersRows.ID,usersrows.TestCentre, UsersRows.LastUser,UsersRows.LDAPLogin,UsersRows.Row, UsersRows.IsActive, 
		CASE WHEN @determineDelete = 1 THEN dbo.remifnUserCanDelete(UsersRows.LDAPLogin) ELSE 0 END AS CanDelete, UsersRows.DefaultPage, UsersRows.TestCentreID,
		ByPassProduct
	FROM     
		(SELECT ROW_NUMBER() OVER (ORDER BY ID) AS Row, Users.BadgeNumber,Users.ConcurrencyID,Users.ID,Users.LastUser,Users.LDAPLogin, 
			Lookups.[Values] AS TestCentre, ISNULL(Users.IsActive,1) AS IsActive, Users.DefaultPage, Users.TestCentreID, Users.ByPassProduct
		FROM Users
			LEFT OUTER JOIN Lookups ON Type='TestCenter' AND LookupID=TestCentreID
		) AS UsersRows
	WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1) 
	ORDER BY IsActive desc, LDAPLogin
GO
GRANT EXECUTE ON remispUsersSelectList TO Remi
GO