ALTER PROCEDURE [dbo].[remispUsersSelectListByTestCentre] @TestLocation INT, @IncludeInActive INT = 1, @determineDelete INT = 1, @RecordCount int = NULL OUTPUT
AS
	DECLARE @ConCurID timestamp

	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) 
							FROM Users 
							WHERE TestCentreID=TestCentreID
								AND 
								(
									(@IncludeInActive = 0 AND IsActive=1)
									OR
									@IncludeInActive = 1
								)
							)
		RETURN
	END

	SELECT Users.BadgeNumber, Users.ConcurrencyID, Users.ID, Users.LastUser, Users.LDAPLogin, 
		Lookups.[Values] AS TestCentre, ISNULL(Users.IsActive,1) AS IsActive, Users.DefaultPage, Users.TestCentreID, Users.ByPassProduct, 
		CASE WHEN @determineDelete = 1 THEN dbo.remifnUserCanDelete(Users.LDAPLogin) ELSE 0 END AS CanDelete
	FROM Users
		LEFT OUTER JOIN Lookups ON Type='TestCenter' AND LookupID=TestCentreID
	WHERE (TestCentreID=@TestLocation OR @TestLocation = 0)
		AND 
		(
			(@IncludeInActive = 0 AND ISNULL(Users.IsActive, 1)=1)
			OR
			@IncludeInActive = 1
		)
	ORDER BY IsActive DESC, LDAPLogin
GO
GRANT EXECUTE ON remispUsersSelectListByTestCentre TO Remi
GO