ALTER PROCEDURE remispGetLookup @Type NVARCHAR(150), @Lookup NVARCHAR(150), @ParentID INT = NULL
AS
BEGIN
	SELECT LookupID, IsActive FROM Lookups 
	WHERE Type=@Type AND [Values]=@Lookup AND 
		(
			(ISNULL(@ParentID, 0) > 0 AND ParentID=@ParentID)
			OR
			(ISNULL(@ParentID, 0) = 0)
		)
END
GO
GRANT EXECUTE ON remispGetLookup TO Remi
GO