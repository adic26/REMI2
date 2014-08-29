ALTER PROCEDURE [dbo].[remispTrackingLocationTypesSelectList] @Function as int = null
AS
BEGIN	
	SELECT tlt.Comment,tlt.ConcurrencyID,tlt.ID,tlt.LastUser,tlt.TrackingLocationFunction,tlt.TrackingLocationTypeName,tlt.UnitCapacity,tlt.WILocation,
		ISNULL((SELECT TOP 1 0 FROM TrackingLocations tl WHERE tl.TrackingLocationTypeID=tlt.ID), 1) AS CanDelete
	FROM TrackingLocationTypes as tlt
	WHERE (tlt.TrackingLocationFunction = @function or @function is null)
	ORDER BY TrackingLocationTypeName ASC
END
GO
GRANT EXECUTE ON remispTrackingLocationTypesSelectList TO REMI
GO