ALTER PROCEDURE [dbo].[remispUsersSelectSingleItemByBadgeNumber] @BadgeNumber int
AS
	SELECT u.BadgeNumber,u.ConcurrencyID,u.ID,u.LastUser,u.LDAPLogin, u.TestCentreID, ISNULL(u.IsActive,1) As IsActive, u.DefaultPage, Lookups.[values] As TestCentre,
		u.ByPassProduct, u.DepartmentID, ld.[Values] AS Department
	FROM Users as u
		LEFT OUTER JOIN Lookups ON LookupID=TestCentreID
		LEFT OUTER JOIN Lookups ld ON ld.LookupID=DepartmentID
	WHERE BadgeNumber = @BadgeNumber
GO
GRANT EXECUTE ON remispUsersSelectSingleItemByBadgeNumber TO Remi
GO