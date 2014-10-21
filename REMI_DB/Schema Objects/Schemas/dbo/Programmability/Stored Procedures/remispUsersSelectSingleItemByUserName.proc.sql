ALTER PROCEDURE [dbo].[remispUsersSelectSingleItemByUserName] @LDAPLogin nvarchar(255) = '', @UserID INT = 0
AS
	SELECT Users.BadgeNumber,Users.ConcurrencyID,Users.ID,Users.LastUser,Users.LDAPLogin, Users.TestCentreID, ISNULL(Users.IsActive, 1) AS IsActive, 
		Users.DefaultPage, Lookups.[Values] As TestCentre, Users.ByPassProduct, Users.DepartmentID, ld.[Values] AS Department
	FROM Users
		LEFT OUTER JOIN Lookups ON Type='TestCenter' AND LookupID=TestCentreID
		LEFT OUTER JOIN Lookups ld ON ld.Type='Department' AND ld.LookupID=DepartmentID
	WHERE (@UserID = 0 AND LDAPLogin = @LDAPLogin) OR (@UserID > 0 AND Users.ID=@UserID)
GO
GRANT EXECUTE ON remispUsersSelectSingleItemByUserName TO Remi
GO