ALTER PROCEDURE dbo.remispGetContacts @ProductID INT
AS
BEGIN
	DECLARE @TSDContact NVARCHAR(255)
	
	SELECT @TSDContact = p.TSDContact
	FROM Products p
	WHERE p.ID=@ProductID

	SELECT ISNULL(us.LDAPLogin, '') AS ProductManager
	INTO #temp
	FROM UserDetails ud WITH(NOLOCK)
		INNER JOIN Products p WITH(NOLOCK) ON p.LookupID=ud.LookupID
		INNER JOIN Users us WITH(NOLOCK) ON us.ID=ud.UserID
	WHERE ud.IsProductManager=1 AND p.ID=@ProductID
	
	IF ((SELECT COUNT(*) FROM #temp) = 0)
	BEGIN
		SELECT NULL AS ProductManager, @TSDContact AS TSDContact
	END
	ELSE
	BEGIN
		SELECT *, @TSDContact AS TSDContact
		FROM #temp
	END
	
	DROP TABLE #temp
END
GO
GRANT EXECUTE ON [dbo].remispGetContacts TO REMI
GO
