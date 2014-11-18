ALTER PROCEDURE remispGetUserDetails @UserID INT
AS
BEGIN
	SELECT lt.Name, l.[Values], l.LookupID, ISNULL(ud.IsDefault, 0) AS IsDefault
	FROM UserDetails ud
		INNER JOIN Lookups l ON l.LookupID=ud.LookupID
		INNER JOIN LookupType lt ON lt.LookupTypeID=l.LookupTypeID
	WHERE ud.UserID=@UserID
	ORDER BY lt.Name, l.[Values]
END
GO
GRANT EXECUTE ON remispGetUserDetails TO REMI
GO
