ALTER PROCEDURE remispGetLookups @Type NVARCHAR(150), @ProductID INT = NULL, @ParentID INT = NULL, @ParentLookupType NVARCHAR(150) = NULL, @ParentLookup NVARCHAR(150) = NULL, @RequestTypeID INT = NULL,
	@ShowAdminSelected BIT = 0
AS
BEGIN
	DECLARE @LookupTypeID INT
	DECLARE @ParentLookupTypeID INT
	DECLARE @HierarchyExists BIT
	DECLARE @ParentLookupID INT
	SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name=@Type
	SELECT @ParentLookupTypeID = LookupTypeID FROM LookupType WHERE Name=@ParentLookupType
	SELECT @ParentLookupID = LookupID FROM Lookups WHERE LookupTypeID=@ParentLookupTypeID AND Lookups.[Values]=@ParentLookup
	SET @HierarchyExists = CONVERT(BIT, 0)
	
	SET @HierarchyExists = ISNULL((SELECT TOP 1 CONVERT(BIT, 1) 
	FROM LookupsHierarchy lh
	WHERE lh.ParentLookupTypeID=@ParentLookupTypeID AND lh.ChildLookupTypeID=@LookupTypeID
		AND lh.ParentLookupID=@ParentLookupID AND lh.RequestTypeID=@RequestTypeID), CONVERT(BIT, 0))
	
	DECLARE @NotSetSelected BIT
	SET @NotSetSelected = CONVERT(BIT, 0)
	
	IF EXISTS (SELECT 1 FROM LookupsHierarchy lh WHERE lh.ParentLookupTypeID=@ParentLookupTypeID AND lh.ChildLookupTypeID=@LookupTypeID AND lh.ParentLookupID=@ParentLookupID AND lh.RequestTypeID=@RequestTypeID AND lh.ChildLookupID=0)
		SET @NotSetSelected = CONVERT(BIT, 1)	

	SELECT l.LookupID, @Type AS [Type], l.[Values] As LookupType, CASE WHEN pl.ID IS NOT NULL THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END As HasAccess, 
		l.Description, ISNULL(l.ParentID, 0) AS ParentID, p.[Values] AS Parent, CASE WHEN lh.ChildLookupID =l.LookupID THEN 1 ELSE 0 END AS RequestAssigned
	INTO #type
	FROM Lookups l
		LEFT OUTER JOIN ProductLookups pl ON pl.ProductID=@ProductID AND l.LookupID=pl.LookupID
		LEFT OUTER JOIN Lookups p ON p.LookupID=l.ParentID
		LEFT OUTER JOIN LookupsHierarchy lh ON lh.ParentLookupTypeID=@ParentLookupTypeID AND lh.ChildLookupTypeID=@LookupTypeID
			AND lh.ParentLookupID=@ParentLookupID AND lh.RequestTypeID=@RequestTypeID AND lh.ChildLookupID=l.LookupID
	WHERE l.LookupTypeID=@LookupTypeID AND l.IsActive=1 AND 
		(
			(@ParentID IS NOT NULL AND ISNULL(@ParentID, 0) <> 0 AND ISNULL(l.ParentID, 0) = ISNULL(@ParentID, 0))
			OR
			(@ParentID IS NULL OR ISNULL(@ParentID, 0) = 0)
		)
		AND
		(
			(
				@ShowAdminSelected = 1
				OR
				(l.LookupID IN (SELECT ChildLookupID 
							FROM LookupsHierarchy lh 
							WHERE lh.ParentLookupTypeID=@ParentLookupTypeID AND lh.ChildLookupTypeID=@LookupTypeID
								AND lh.ParentLookupID=@ParentLookupID AND lh.RequestTypeID=@RequestTypeID
							)
				) 
				OR
				@HierarchyExists = CONVERT(BIT, 0)
			)
		)
		
	; WITH cte AS
	(
		SELECT LookupID, [Type], LookupType, HasAccess, Description, ISNULL(ParentID, 0) AS ParentID, Parent, RequestAssigned,
			cast(row_number()over(partition by ParentID order by LookupType) as varchar(max)) as [path],
			0 as level,
			row_number()over(partition by ParentID order by LookupType) / power(10.0,0) as x
		FROM #type
		WHERE ISNULL(ParentID, 0) = 0
		UNION ALL
		SELECT t.LookupID, t.[Type], t.LookupType, t.HasAccess, t.Description, t.ParentID, t.Parent, cte.RequestAssigned,
		[path] +'-'+ cast(row_number() over(partition by t.ParentID order by t.LookupType) as varchar(max)),
		level+1,
		x + row_number()over(partition by t.ParentID order by t.LookupType) / power(10.0,level+1)
		FROM cte
			INNER JOIN #type t on cte.LookupID = t.ParentID
	)
	select LookupID, [Type], LookupType, HasAccess, Description, ParentID, (CONVERT(NVARCHAR, ParentID) + '-' + Parent) AS Parent, x, (CONVERT(NVARCHAR, LookupID) + '-' + LookupType) AS DisplayText, RequestAssigned
	FROM cte
	UNION ALL
	SELECT 0 AS LookupID, @Type AS [Type], '' As LookupType, CONVERT(BIT, 0) As HasAccess, NULL AS Description, 0 AS ParentID, NULL AS Parent, NULL AS x, '' AS DisplayText, @NotSetSelected AS RequestAssigned
	ORDER BY x		
		
	DROP TABLE #type
END
GO
GRANT EXECUTE ON remispGetLookups TO REMI
GO