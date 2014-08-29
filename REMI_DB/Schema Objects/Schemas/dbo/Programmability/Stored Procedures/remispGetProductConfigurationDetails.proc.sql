alter PROCEDURE remispGetProductConfigurationDetails @PCID INT
AS
BEGIN	
	SELECT pc.ID, pc.ParentId AS ParentID, pc.ViewOrder, pc.NodeName, pcv.ID AS ProdConfID, l.[Values] As LookupName, 
		l.LookupID, Value As LookupValue, ISNULL(pcv.IsAttribute, 0) AS IsAttribute
	FROM ProductConfiguration pc
		INNER JOIN ProductConfigValues pcv ON pc.ID = pcv.ProductConfigID
		INNER JOIN Lookups l ON l.LookupID = pcv.LookupID
	WHERE pcv.ProductConfigID=@PCID
	ORDER BY pc.ViewOrder	
END
GO
GRANT EXECUTE ON remispGetProductConfigurationDetails TO REMI
GO