ALTER PROCEDURE remispGetLookupTypes
AS
BEGIN
	SELECT 0 AS LookupTypeID, 'SELECT...' AS Name
	UNION ALL
	SELECT lt.LookupTypeID, lt.Name 
	FROM LookupType lt
END
GO
GRANT EXECUTE ON remispGetLookupTypes TO REMI
GO