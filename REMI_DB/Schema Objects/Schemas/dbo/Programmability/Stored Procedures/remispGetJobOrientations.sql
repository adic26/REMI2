ALTER PROCEDURE [dbo].[remispGetJobOrientations] @JobID INT = 0, @JobName NVARCHAR(400) = NULL
AS
BEGIN
	SELECT jo.ID, jo.Name, jo.ProductTypeID, l.[Values] AS ProductType, jo.NumUnits, jo.NumDrops,
		jo.Description, jo.CreatedDate, jo.IsActive, jo.Definition
	FROM JobOrientation jo
		INNER JOIN Lookups l ON l.LookupID=jo.ProductTypeID AND l.[Type]='ProductType'
		INNER JOIN Jobs j ON j.ID=jo.JobID
	WHERE ( 
			(jo.JobID=@JobID AND @JobID > 0)
			OR
			(j.JobName = @JobName AND @JobName IS NOT NULL)
		  )
END
GO
GRANT EXECUTE ON [dbo].[remispGetJobOrientations] TO REMI
GO