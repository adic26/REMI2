ALTER PROCEDURE dbo.remispGetContacts @ProductID INT
AS
BEGIN
	SELECT ISNULL(us.LDAPLogin, '') AS TSDContact
	INTO #tempTSD
	FROM UserDetails ud WITH(NOLOCK)
		INNER JOIN Products p WITH(NOLOCK) ON p.LookupID=ud.LookupID
		INNER JOIN Users us WITH(NOLOCK) ON us.ID=ud.UserID
	WHERE ud.IsTSDContact=1 AND p.ID=@ProductID

	SELECT ISNULL(us.LDAPLogin, '') AS ProductManager
	INTO #temp
	FROM UserDetails ud WITH(NOLOCK)
		INNER JOIN Products p WITH(NOLOCK) ON p.LookupID=ud.LookupID
		INNER JOIN Users us WITH(NOLOCK) ON us.ID=ud.UserID
	WHERE ud.IsProductManager=1 AND p.ID=@ProductID
	
	SELECT pm.*, tsd.*
	FROM
	(
		SELECT ProductManager
		FROM #temp
	) pm,
	(
		SELECT TSDContact
		FROM #tempTSD
	) tsd
	
	DROP TABLE #temp
	DROP TABLE #tempTSD
END
GO
GRANT EXECUTE ON [dbo].remispGetContacts TO REMI
GO