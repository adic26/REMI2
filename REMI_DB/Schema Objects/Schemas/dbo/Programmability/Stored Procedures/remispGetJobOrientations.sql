ALTER PROCEDURE [dbo].[remispGetJobOrientations] @JobID INT
AS
BEGIN
	SELECT jo.ID, jo.Name, jo.ProductTypeID, l.[Values] AS ProductType, jo.NumUnits, jo.NumDrops,
		jo.Description, jo.CreatedDate, jo.IsActive, jo.Definition
	FROM JobOrientation jo
		INNER JOIN Lookups l ON l.LookupID=jo.ProductTypeID AND l.[Type]='ProductType'
	WHERE jo.JobID=@JobID
END
GO
GRANT EXECUTE ON [dbo].[remispGetJobOrientations] TO REMI
GO