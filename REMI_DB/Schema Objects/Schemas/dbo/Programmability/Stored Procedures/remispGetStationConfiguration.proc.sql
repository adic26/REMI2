SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE remispGetStationConfiguration @hostID INT, @ProfileID INT
AS
BEGIN
	SELECT tc.ID, tcParent.NodeName As ParentName, tc.ParentId AS ParentID, tc.ViewOrder, tc.NodeName,
		ISNULL((
			(SELECT ISNULL(TrackingLocationsHostsConfiguration.NodeName, '')
			FROM TrackingLocationsHostsConfiguration
				LEFT OUTER JOIN TrackingLocationsHostsConfiguration tc2 ON TrackingLocationsHostsConfiguration.ID = tc2.ParentId
			WHERE tc2.ID = tc.ParentID)
			+ '/' + 
			ISNULL(tcParent.NodeName, '')
		), CASE WHEN tc.ParentId IS NOT NULL THEN tcParent.NodeName ELSE NULL END) As ParentScheme,
		tc.TrackingLocationProfileID
	FROM dbo.TrackingLocationsHostsConfiguration tc
		LEFT OUTER JOIN TrackingLocationsHostsConfiguration tcParent ON tc.ParentId=tcParent.ID
	WHERE tc.TrackingLocationHostID=@hostID AND (@ProfileID = 0 OR (tc.TrackingLocationProfileID=@ProfileID AND @ProfileID <> 0))
	ORDER BY tc.ViewOrder
END
GO
GRANT EXECUTE ON remispGetStationConfiguration TO REMI
GO