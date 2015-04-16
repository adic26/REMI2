alter PROCEDURE [dbo].[remispGetUser] @SearchBy INT, @SearchStr NVARCHAR(255)
AS	
	DECLARE @UserID INT
	DECLARE @UserName NVARCHAR(255)

	IF (@SearchBy = 0)
	BEGIN
		SELECT @UserID=ID, @UserName = u.LDAPLogin
		FROM Users u
		WHERE u.BadgeNumber=@SearchStr
	END
	ELSE IF (@SearchBy = 1)
	BEGIN
		SELECT @UserID=ID, @UserName = u.LDAPLogin
		FROM Users u
		WHERE u.LDAPLogin=@SearchStr
	END
	ELSE IF (@SearchBy = 2)
	BEGIN
		SELECT @UserID=ID, @UserName = u.LDAPLogin
		FROM Users u
		WHERE u.ID=@SearchStr
	END
	
	SELECT u.BadgeNumber, u.ConcurrencyID, u.ID, u.LastUser, u.LDAPLogin, ISNULL(u.IsActive, 1) AS IsActive, 
		u.DefaultPage, u.ByPassProduct
	FROM Users u
	WHERE u.ID=@UserID
	
	EXEC remispGetUserDetails @UserID
	
	EXEC remispGetUserTraining @UserID =@UserID, @ShowTrainedOnly = 1

	EXEC Req.remispGetRequestTypes @UserName
	
	SELECT s.ServiceID, s.ServiceName, l.[Values] AS Department
	FROM UserDetails ud
		INNER JOIN Lookups l ON l.LookupID=ud.LookupID
		INNER JOIN LookupType lt ON lt.LookupTypeID=l.LookupTypeID
		INNER JOIN ServicesAccess sa ON sa.LookupID=l.LookupID
		INNER JOIN Services s ON sa.ServiceID=s.ServiceID 
	WHERE ud.UserID=@UserID AND lt.Name='Department' AND ISNULL(s.IsActive, 0) = 1
GO
GRANT EXECUTE ON remispGetUser TO Remi
GO