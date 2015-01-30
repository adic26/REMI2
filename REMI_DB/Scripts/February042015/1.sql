BEGIN TRAN
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


GO
ROLLBACK TRAN