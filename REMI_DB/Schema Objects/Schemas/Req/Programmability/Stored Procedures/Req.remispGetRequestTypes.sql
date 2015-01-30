ALTER PROCEDURE Req.remispGetRequestTypes @UserName NVARCHAR(255)
AS
BEGIN
	SELECT lt.[Values] AS RequestType, l.[Values] AS Department, rta.IsActive, rt.HasIntegration, rt.RequestTypeID, 
		ISNULL(udt.IsAdmin, 0) AS IsAdmin, ISNULL(udt.UserDetailsID,-1) AS UserDetailsID, rt.IsExternal, rt.TypeID, rta.RequestTypeAccessID
	FROM Req.RequestTypeAccess rta
		INNER JOIN Lookups l ON rta.LookupID=l.LookupID
		INNER JOIN Req.RequestType rt ON rt.RequestTypeID=rta.RequestTypeID
		INNER JOIN Lookups lt ON rt.TypeID=lt.LookupID
		INNER JOIN UserDetails ud ON ud.LookupID = l.LookupID
		LEFT OUTER JOIN UserDetails udt ON udt.LookupID = lt.LookupID and udt.UserID=ud.UserID
		INNER JOIN Users u ON u.ID=ud.UserID
	WHERE u.LDAPLogin=@UserName
END
GO
GRANT EXECUTE ON Req.remispGetRequestTypes TO REMI
GO