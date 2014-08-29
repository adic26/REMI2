ALTER PROCEDURE [dbo].[remispUsersSelectSingleItemByBadgeNumber] @BadgeNumber int
AS
	SELECT u.BadgeNumber,u.ConcurrencyID,u.ID,u.LastUser,u.LDAPLogin, u.TestCentreID, ISNULL(u.IsActive,1) As IsActive, u.DefaultPage, Lookups.[values] As TestCentre,
		u.ByPassProduct
	FROM Users as u
		LEFT OUTER JOIN Lookups ON Type='TestCenter' AND LookupID=TestCentreID
	WHERE BadgeNumber = @BadgeNumber
GO
GRANT EXECUTE ON remispUsersSelectSingleItemByBadgeNumber TO Remi
GO