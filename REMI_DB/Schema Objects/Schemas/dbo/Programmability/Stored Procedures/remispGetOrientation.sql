ALTER PROCEDURE [dbo].[remispGetOrientation] @ID INT
AS
BEGIN
	SELECT jo.ID, jo.Name, jo.ProductTypeID, l.[Values] AS ProductType, jo.NumUnits, jo.NumDrops,
		jo.Description, jo.CreatedDate, jo.IsActive, jo.Definition, jo.JobID
	FROM JobOrientation jo
		INNER JOIN Lookups l ON l.LookupID=jo.ProductTypeID AND l.[Type]='ProductType'
	WHERE jo.ID = @ID
END
GO
GRANT EXECUTE ON [dbo].[remispGetOrientation] TO REMI
GO