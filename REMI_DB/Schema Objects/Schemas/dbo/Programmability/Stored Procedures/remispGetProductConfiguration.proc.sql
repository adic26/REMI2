ALTER PROCEDURE remispGetProductConfiguration @PCUID INT
AS
BEGIN
	SELECT pc.ID, pcParent.NodeName As ParentName, pc.ParentId AS ParentID, pc.ViewOrder, pc.NodeName,
		ISNULL((
			(SELECT ISNULL(ProductConfiguration.NodeName, '')
			FROM ProductConfiguration
				LEFT OUTER JOIN ProductConfiguration pc2 ON ProductConfiguration.ID = pc2.ParentId
			WHERE pc2.ID = pc.ParentID)
			+ '/' + 
			ISNULL(pcParent.NodeName, '')
		), CASE WHEN pc.ParentId IS NOT NULL THEN pcParent.NodeName ELSE NULL END) As ParentScheme
	FROM ProductConfiguration pc
		LEFT OUTER JOIN ProductConfiguration pcParent ON pc.ParentId=pcParent.ID
		INNER JOIN productConfigurationUpload pcu ON pcu.ID=pc.UploadID
	WHERE pcu.ID=@PCUID
	ORDER BY pc.ViewOrder
END
GO
GRANT EXECUTE ON remispGetProductConfiguration TO REMI
GO