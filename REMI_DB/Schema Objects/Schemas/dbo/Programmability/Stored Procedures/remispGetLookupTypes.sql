ALTER PROCEDURE remispGetLookupTypes @ShowSystemTypes BIT
AS
BEGIN
	SELECT 0 AS LookupTypeID, 'SELECT...' AS Name, 0 As IsSystem
	UNION ALL
	SELECT lt.LookupTypeID, lt.Name, IsSystem
	FROM LookupType lt
	WHERE 
		(
			@ShowSystemTypes = 1
			OR
			lt.IsSystem=@ShowSystemTypes
		)
END
GO
GRANT EXECUTE ON remispGetLookupTypes TO REMI
GO