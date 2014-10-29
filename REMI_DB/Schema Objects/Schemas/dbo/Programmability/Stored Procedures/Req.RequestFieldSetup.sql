ALTER PROCEDURE [Req].[RequestFieldSetup] @RequestID INT, @IncludeArchived BIT = 0
AS
BEGIN
	SELECT rfs.ReqFieldSetupID, lrt.[Values] AS RequestType, rfs.Name, lft.[Values] AS FieldType, rfs.FieldTypeID, 
		lvt.[Values] AS ValidationType, rfs.FieldValidationID, ISNULL(rfs.IsRequired, 0) AS IsRequired, rfs.DisplayOrder, 
		ISNULL(rfs.Archived, 0) AS Archived, rfs.Description, rfs.OptionsTypeID, rt.RequestTypeID AS RequestID
	FROM Req.ReqFieldSetup rfs
		INNER JOIN Lookups lft ON lft.LookupID=rfs.FieldTypeID
		LEFT OUTER JOIN Lookups lvt ON lvt.LookupID=rfs.FieldValidationID
		INNER JOIN Req.RequestType rt ON rt.ID=rfs.RequestID
		INNER JOIN Lookups lrt ON lrt.LookupID=rt.RequestTypeID
	WHERE rfs.RequestID=@RequestID AND 
		(
			(@IncludeArchived = 1)
			OR
			(@IncludeArchived = 0 AND ISNULL(rfs.Archived, 0) = 0)
		)
	ORDER BY ISNULL(rfs.DisplayOrder, 0) ASC
END
GO
GRANT EXECUTE ON [Req].[RequestFieldSetup] TO REMI
GO