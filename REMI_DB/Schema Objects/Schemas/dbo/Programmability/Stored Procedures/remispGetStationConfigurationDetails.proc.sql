ALTER PROCEDURE remispGetStationConfigurationDetails @hostConfigID INT
AS
BEGIN	
	SELECT sc.ID, sc.ParentId AS ParentID, sc.ViewOrder, sc.NodeName, tcv.ID AS TrackingConfigID, l.[Values] As LookupName, 
		l.LookupID, Value As LookupValue, ISNULL(tcv.IsAttribute, 0) AS IsAttribute
	FROM TrackingLocationsHostsConfiguration sc
		INNER JOIN TrackingLocationsHostsConfigValues tcv ON sc.ID = tcv.TrackingConfigID
		INNER JOIN Lookups l ON l.LookupID = tcv.LookupID
	WHERE tcv.TrackingConfigID=@hostConfigID
	ORDER BY sc.ViewOrder	
END
GO
GRANT EXECUTE ON remispGetStationConfigurationDetails TO REMI
GO