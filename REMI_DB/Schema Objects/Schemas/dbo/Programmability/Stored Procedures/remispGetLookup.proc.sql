ALTER PROCEDURE remispGetLookup @Type NVARCHAR(150), @Lookup NVARCHAR(150)
AS
BEGIN
	SELECT LookupID, IsActive FROM Lookups WHERE Type=@Type AND [Values]=@Lookup
END
GO
GRANT EXECUTE ON remispGetLookup TO Remi
GO