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
	
	SELECT rfd.ReqFieldSetupID, rfd.InstanceID, rfd.Value
	FROM Req.ReqFieldData rfd WITH(NOLOCK)
		INNER JOIN Req.ReqFieldSetup rfs WITH(NOLOCK) ON rfs.ReqFieldSetupID=rfd.ReqFieldSetupID
		INNER JOIN Req.ReqFieldSetupSibling rfss WITH(NOLOCK) ON rfss.ReqFieldSetupID=rfs.ReqFieldSetupID
	WHERE RequestID = @RequestID

	SELECT rfs.ReqFieldSetupID, @RequestType AS RequestType, rfs.Name, lft.[Values] AS FieldType, rfs.FieldTypeID, 
			lvt.[Values] AS ValidationType, rfs.FieldValidationID, ISNULL(rfs.IsRequired, 0) AS IsRequired, ISNULL(rfs.DisplayOrder, 0) AS DisplayOrder,
			rfs.ColumnOrder, ISNULL(rfs.Archived, 0) AS Archived, rfs.Description, rfs.OptionsTypeID, @RequestTypeID AS RequestTypeID,
			@RequestNumber AS RequestNumber, @RequestID AS RequestID, 
			CASE WHEN rfm.IntField = 'RequestLink' AND Value IS NULL THEN 'http://go/requests/' + @RequestNumber ELSE CASE WHEN ISNULL(rfss.DefaultDisplayNum, 1) = 1 THEN rfd.Value ELSE '' END END AS Value, 
			rfm.IntField, rfm.ExtField,
			CASE WHEN rfm.ID IS NOT NULL THEN 1 ELSE 0 END AS InternalField,
			CASE WHEN @RequestID = 0 THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END AS NewRequest, rt.IsExternal AS IsFromExternalSystem, rfs.Category,
			rfs.ParentReqFieldSetupID, rt.HasIntegration, rfsp.Name As ParentFieldSetupName, rfs.DefaultValue, 
			ISNULL(rfd.ReqFieldDataID, -1) AS ReqFieldDataID, rt.HasDistribution,
			CASE
				WHEN (SELECT MAX(InstanceID) FROM Req.ReqFieldData d WHERE d.RequestID=@RequestID AND d.ReqFieldSetupID=rfs.ReqFieldSetupID) > ISNULL(rfss.DefaultDisplayNum, 1)
				THEN (SELECT MAX(InstanceID) FROM Req.ReqFieldData d WHERE d.RequestID=@RequestID AND d.ReqFieldSetupID=rfs.ReqFieldSetupID)
				ELSE ISNULL(rfss.DefaultDisplayNum, 1)
				END AS DefaultDisplayNum, 
			ISNULL(rfss.MaxDisplayNum, 1) AS MaxDisplayNum 
	FROM Req.RequestType rt WITH(NOLOCK)
		INNER JOIN Lookups lrt WITH(NOLOCK) ON lrt.LookupID=rt.TypeID
		INNER JOIN Req.ReqFieldSetup rfs WITH(NOLOCK) ON rfs.RequestTypeID=rt.RequestTypeID                  
		INNER JOIN Lookups lft WITH(NOLOCK) ON lft.LookupID=rfs.FieldTypeID
		LEFT OUTER JOIN Lookups lvt WITH(NOLOCK) ON lvt.LookupID=rfs.FieldValidationID
		LEFT OUTER JOIN Req.ReqFieldSetupRole rfsr WITH(NOLOCK) ON rfsr.ReqFieldSetupID=rfs.ReqFieldSetupID
		LEFT OUTER JOIN Req.Request r WITH(NOLOCK) ON RequestNumber=@RequestNumber
		LEFT OUTER JOIN Req.ReqFieldMapping rfm WITH(NOLOCK) ON rfm.RequestTypeID=rt.RequestTypeID AND rfm.ExtField=rfs.Name AND ISNULL(rfm.IsActive, 0) = 1
		LEFT OUTER JOIN Req.ReqFieldSetup rfsp WITH(NOLOCK) ON rfsp.ReqFieldSetupID=rfs.ParentReqFieldSetupID
		LEFT OUTER JOIN Req.ReqFieldSetupSibling rfss WITH(NOLOCK) ON rfss.ReqFieldSetupID=rfs.ReqFieldSetupID
		LEFT OUTER JOIN Req.ReqFieldData rfd WITH(NOLOCK) ON rfd.ReqFieldSetupID=rfs.ReqFieldSetupID AND rfd.RequestID=r.RequestID AND ISNULL(rfd.InstanceID, 1) = 1
	WHERE (lrt.[Values] = @RequestType) AND 
		(
			(@IncludeArchived = @TrueBit)
			OR
			(@IncludeArchived = @FalseBit AND ISNULL(rfs.Archived, @FalseBit) = @FalseBit)
			OR
			(@IncludeArchived = @FalseBit AND rfd.Value IS NOT NULL AND ISNULL(rfs.Archived, @FalseBit) = @TrueBit)
		)
	ORDER BY 22, 9 ASC
END
GO
GRANT EXECUTE ON [Req].[RequestFieldSetup] TO REMI
GO