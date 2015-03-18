BEGIN TRAN
GO
ALTER TABLE LookupType ADD IsSystem BIT DEFAULT(0) NOT NULL
GO
ALTER TABLE Req.ReqFieldSetup ADD DefaultValue NVARCHAR (400) NULL
GO
ALTER PROCEDURE [Req].[RequestFieldSetup] @RequestTypeID INT, @IncludeArchived BIT = 0, @RequestNumber NVARCHAR(12) = NULL
AS
BEGIN
	DECLARE @RequestID INT
	DECLARE @TrueBit BIT
	DECLARE @FalseBit BIT
	DECLARE @RequestType NVARCHAR(150)
	SET @RequestID = 0
	SET @TrueBit = CONVERT(BIT, 1)
	SET @FalseBit = CONVERT(BIT, 0)

	SELECT @RequestType=lrt.[values] FROM Req.RequestType rt INNER JOIN Lookups lrt ON lrt.LookupID=rt.TypeID WHERE rt.RequestTypeID=@RequestTypeID

	IF (@RequestNumber IS NOT NULL)
		BEGIN
			SELECT @RequestID = RequestID FROM Req.Request WHERE RequestNumber=@RequestNumber
		END
	ELSE
		BEGIN
			SELECT @RequestNumber = REPLACE(RequestNumber, @RequestType + '-' + Right(Year(getDate()),2) + '-', '') + 1 
			FROM Req.Request 
			WHERE RequestNumber LIKE @RequestType + '-' + Right(Year(getDate()),2) + '-%'
			
			IF (LEN(@RequestNumber) < 4)
			BEGIN
				SET @RequestNumber = REPLICATE('0', 4-LEN(@RequestNumber)) + @RequestNumber
			END
		
			IF (@RequestNumber IS NULL)
				SET @RequestNumber = '0001'
		
			SET @RequestNumber = @RequestType + '-' + Right(Year(getDate()),2) + '-' + @RequestNumber
		END

	SELECT rfs.ReqFieldSetupID, @RequestType AS RequestType, rfs.Name, lft.[Values] AS FieldType, rfs.FieldTypeID, 
			lvt.[Values] AS ValidationType, rfs.FieldValidationID, ISNULL(rfs.IsRequired, 0) AS IsRequired, rfs.DisplayOrder, 
			rfs.ColumnOrder, ISNULL(rfs.Archived, 0) AS Archived, rfs.Description, rfs.OptionsTypeID, @RequestTypeID AS RequestTypeID,
			@RequestNumber AS RequestNumber, @RequestID AS RequestID, 
			CASE WHEN rfm.IntField = 'RequestLink' AND Value IS NULL THEN 'http://go/requests/' + @RequestNumber ELSE rfd.Value END AS Value, 
			rfm.IntField, rfm.ExtField,
			CASE WHEN rfm.ID IS NOT NULL THEN 1 ELSE 0 END AS InternalField,
			CASE WHEN @RequestID = 0 THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END AS NewRequest, Req.RequestType.IsExternal AS IsFromExternalSystem, rfs.Category,
			rfs.ParentReqFieldSetupID, Req.RequestType.HasIntegration, rfsp.Name As ParentFieldSetupName, rfs.DefaultValue
	FROM Req.RequestType
		INNER JOIN Lookups lrt ON lrt.LookupID=Req.RequestType.TypeID
		INNER JOIN Req.ReqFieldSetup rfs ON rfs.RequestTypeID=Req.RequestType.RequestTypeID                  
		INNER JOIN Lookups lft ON lft.LookupID=rfs.FieldTypeID
		LEFT OUTER JOIN Lookups lvt ON lvt.LookupID=rfs.FieldValidationID
		LEFT OUTER JOIN Req.ReqFieldSetupRole ON Req.ReqFieldSetupRole.ReqFieldSetupID=rfs.ReqFieldSetupID
		LEFT OUTER JOIN Req.Request ON RequestNumber=@RequestNumber
		LEFT OUTER JOIN Req.ReqFieldData rfd ON rfd.ReqFieldSetupID=rfs.ReqFieldSetupID AND rfd.RequestID=Req.Request.RequestID
		LEFT OUTER JOIN Req.ReqFieldMapping rfm ON rfm.RequestTypeID=Req.RequestType.RequestTypeID AND rfm.ExtField=rfs.Name AND ISNULL(rfm.IsActive, 0) = 1
		LEFT OUTER JOIN Req.ReqFieldSetup rfsp ON rfsp.ReqFieldSetupID=rfs.ParentReqFieldSetupID
	WHERE (lrt.[Values] = @RequestType) AND
		(
			(@IncludeArchived = @TrueBit)
			OR
			(@IncludeArchived = @FalseBit AND ISNULL(rfs.Archived, @FalseBit) = @FalseBit)
			OR
			(@IncludeArchived = @FalseBit AND rfd.Value IS NOT NULL AND ISNULL(rfs.Archived, @FalseBit) = @TrueBit)
		)
	ORDER BY Category, ISNULL(rfs.DisplayOrder, 0) ASC
END
GO
GRANT EXECUTE ON [Req].[RequestFieldSetup] TO REMI
GO
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
ALTER PROCEDURE Req.remispGetRequestTypes @UserName NVARCHAR(255)
AS
BEGIN
	SELECT lt.[Values] AS RequestType, l.[Values] AS Department, rta.IsActive, rt.HasIntegration, rt.RequestTypeID, 
		ISNULL(udt.IsAdmin, 0) AS IsAdmin, ISNULL(udt.UserDetailsID,-1) AS UserDetailsID, rt.IsExternal, rt.TypeID, rta.RequestTypeAccessID
	FROM Req.RequestTypeAccess rta
		INNER JOIN Lookups l ON rta.LookupID=l.LookupID
		INNER JOIN Req.RequestType rt ON rt.RequestTypeID=rta.RequestTypeID
		INNER JOIN Lookups lt ON rt.TypeID=lt.LookupID
		INNER JOIN UserDetails ud ON ud.LookupID = l.LookupID
		LEFT OUTER JOIN UserDetails udt ON udt.LookupID = lt.LookupID and udt.UserID=ud.UserID
		INNER JOIN Users u ON u.ID=ud.UserID
	WHERE u.LDAPLogin=@UserName
END
GO
GRANT EXECUTE ON Req.remispGetRequestTypes TO REMI
GO
UPDATE LookupType SET IsSystem=1 WHERE Name IN ('AccFunctionalMatrix','Configuration','Exceptions','Level','MeasurementType','MFIFunctionalMatrix','Observations','SFIFunctionalMatrix',
	'Training','FieldTypes','ValidationTypes')
GO
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
ROLLBACK TRAN