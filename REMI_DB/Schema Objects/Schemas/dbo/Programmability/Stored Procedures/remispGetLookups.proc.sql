ALTER PROCEDURE remispGetLookups @Type NVARCHAR(150), @ProductID INT = NULL, @ParentID INT = NULL
AS
BEGIN
	SELECT 0 AS LookupID, @Type AS Type, '' As LookupType, CONVERT(BIT, 0) As HasAccess, NULL AS Description, NULL AS ParentID, NULL AS Parent
	UNION
	SELECT l.LookupID, l.Type, l.[Values] As LookupType, CASE WHEN pl.ID IS NOT NULL THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END As HasAccess, l.Description, l.ParentID, p.[Values] AS Parent
	FROM Lookups l
		LEFT OUTER JOIN ProductLookups pl ON pl.ProductID=@ProductID AND l.LookupID=pl.LookupID
		LEFT OUTER JOIN Lookups p ON p.LookupID=l.ParentID
	WHERE l.Type=@Type AND l.IsActive=1 AND 
		(
			(@ParentID IS NOT NULL AND @ParentID <> 0 AND l.ParentID = @ParentID)
			OR
			(@ParentID IS NULL OR @ParentID = 0)
		)
	ORDER By LookupType
END
GO
GRANT EXECUTE ON remispGetLookups TO REMI