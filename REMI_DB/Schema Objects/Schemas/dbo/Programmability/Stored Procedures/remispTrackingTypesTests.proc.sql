ALTER PROCEDURE [dbo].[remispTrackingTypesTests] @TestTypeID INT = 1, @IncludeArchived BIT = 0, @TrackTypeID INT = 0
AS
BEGIN
	DECLARE @rows VARCHAR(8000)
	DECLARE @query VARCHAR(4000)
	SELECT @rows=  ISNULL(STUFF(
	( 
	SELECT DISTINCT '],[' + tlt.TrackingLocationTypeName
	FROM  dbo.TrackingLocationTypes tlt
	WHERE (@TrackTypeID > 0 AND tlt.TrackingLocationFunction = @TrackTypeID) OR (@TrackTypeID = 0)
	ORDER BY '],[' +  tlt.TrackingLocationTypeName
	FOR XML PATH('')), 1, 2, '') + ']','[na]')
	
	SET @query = '
		SELECT *
		FROM
		(
			SELECT CASE WHEN tlft.ID IS NOT NULL THEN 1 ELSE NULL END As Row, t.TestName, tlt.TrackingLocationTypeName
			FROM dbo.TrackingLocationTypes tlt
				LEFT OUTER JOIN dbo.TrackingLocationsForTests tlft ON tlft.TrackingLocationtypeID = tlt.ID
				INNER JOIN dbo.Tests t ON t.ID=tlft.TestID
			WHERE t.TestName IS NOT NULL AND t.TestType=' + CONVERT(VARCHAR, @TestTypeID) + ' AND ISNULL(t.IsArchived, 0)=' + CONVERT(VARCHAR, @IncludeArchived) + '
		)r
		PIVOT 
		(
			MAX(Row) 
			FOR TrackingLocationTypeName 
				IN ('+@rows+')
		) AS pvt
		ORDER BY TestName'
	EXECUTE (@query)
END
GO
GRANT EXECUTE ON remispTrackingTypesTests TO REMI
GO