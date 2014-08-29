ALTER PROCEDURE [dbo].remispStationGroupConfiguration @hostID INT, @ProfileName NVARCHAR(250) AS
BEGIN
	DECLARE @rows VARCHAR(8000)
	DECLARE @rows2 VARCHAR(8000)
	DECLARE @query VARCHAR(4000)
	DECLARE @ProfileID INT
	DECLARE @id INT
	CREATE TABLE #results (idkey [int] IDENTITY(1,1),  NodeName varchar(150), ID int, ParentID int, Example varchar(800), Attribute varchar(800), Closing varchar(800))
	CREATE TABLE #results2 (idkey [int] IDENTITY(1,1),  NodeName varchar(150), ID int, ParentID int, Example varchar(800), Attribute varchar(800), Closing varchar(800))

	IF (@ProfileName <> '' AND @ProfileName IS NOT NULL)
	BEGIN
		SELECT @ProfileID = ID FROM TrackingLocationsPlugin WHERE PluginName=@ProfileName
	END
	ELSE
	BEGIN
		SET @ProfileID = 0
	END

	SELECT @rows=  ISNULL(STUFF(
	( 
	SELECT DISTINCT '],[' + l.[Values] 
	FROM  dbo.TrackingLocationsHostsConfiguration tc
		inner join dbo.TrackingLocationsHostsConfigValues val on tc.ID = val.TrackingConfigID and ISNULL(isattribute,0)=0
		inner join Lookups l on val.LookupID=l.LookupID
	where TrackingLocationHostID=@hostID
		AND (@ProfileID = 0 OR (@ProfileID > 0 AND tc.TrackingLocationProfileID = @ProfileID))
	ORDER BY '],[' +  l.[Values]
	FOR XML PATH('')), 1, 2, '') + ']','[na]')

	SELECT @rows2=  ISNULL(STUFF(
	( 
	SELECT DISTINCT '],[' + l.[Values] 
	FROM    TrackingLocationsHostsConfiguration tc
		inner join TrackingLocationsHostsConfigValues val on tc.ID = val.TrackingConfigID and ISNULL(isattribute,0)=1
		inner join Lookups l on val.LookupID=l.LookupID
	where TrackingLocationHostID=@hostID
		AND (@ProfileID = 0 OR (@ProfileID > 0 AND tc.TrackingLocationProfileID = @ProfileID))
	ORDER BY '],[' +  l.[Values]
	FOR XML PATH('')), 1, 2, '') + ']','[na]')

	SET @query = '
	select NodeName, ID, ParentID, 
	(
		SELECT pvt.* 
		FROM
		(
			SELECT  l.[Values], val.Value
			FROM TrackingLocationsHostsConfiguration tc
				inner join TrackingLocationsHostsConfigValues val on tc.ID=val.TrackingConfigID and ISNULL(isattribute,0)=0
				inner join Lookups l on val.LookupID=l.LookupID
			where TrackingLocationHostID=''' + CONVERT(varchar,@hostID) + ''' and TrackingLocationsHostsConfiguration.ID=tc.ID
				AND (''' + CONVERT(varchar,@ProfileID) + ''' = 0 OR (''' + CONVERT(varchar,@ProfileID) + ''' > 0 AND tc.TrackingLocationProfileID = ''' + CONVERT(varchar,@ProfileID) + ''' ))
		)t
		PIVOT (max(Value) FOR t.[Values]
		IN ('+@rows+')) AS pvt
		for xml Path('''')
	) as example,
	(
		select ''<'' + TrackingLocationsHostsConfiguration.NodeName + '' '' + cast
		(
			(select CAST
				(
					(SELECT pvt.*
					FROM
						(
							SELECT  l.[Values], val.Value
							FROM TrackingLocationsHostsConfiguration tc
							inner join TrackingLocationsHostsConfigValues val on tc.ID=val.TrackingConfigID and ISNULL(isattribute,0)= 1
							inner join Lookups l on val.LookupID=l.LookupID
							where TrackingLocationHostID=''' + CONVERT(varchar,@hostID) + ''' and TrackingLocationsHostsConfiguration.ID=tc.ID
								AND (''' + CONVERT(varchar,@ProfileID) + ''' = 0 OR (''' + CONVERT(varchar,@ProfileID) + ''' > 0 AND tc.TrackingLocationProfileID = ''' + CONVERT(varchar,@ProfileID) + ''' ))
						)t
					PIVOT (max(Value) FOR t.[Values]
					IN ('+@rows2+')) AS pvt
					for xml Path(''Attribute''))
				as xml)
			).query(''for $i in /Attribute/* return concat(local-name($i), "=""", data($i), """")'')
		as nvarchar(max)) + '' />''
	) AS Attribute, ''</'' + TrackingLocationsHostsConfiguration.NodeName + ''>'' AS Closing
	from TrackingLocationsHostsConfiguration
	where TrackingLocationHostID=''' + CONVERT(varchar,@hostID) + '''
		AND (''' + CONVERT(varchar,@ProfileID) + ''' = 0 OR (''' + CONVERT(varchar,@ProfileID) + ''' > 0 AND TrackingLocationProfileID = ''' + CONVERT(varchar,@ProfileID) + ''' ))
	ORDER BY ViewOrder'

	INSERT INTO #results
		EXECUTE (@query)	

	SELECT @id= MIN(idkey) FROM #results WHERE ParentID IS NOT NULL

	IF EXISTS (SELECT idkey FROM #results WHERE ParentID IS NULL)
		INSERT INTO #results2 SELECT NodeName, ID, ParentID, Example, Attribute, Closing FROM #results WHERE ParentID IS NULL

	WHILE (@id is not null)
	BEGIN
		IF EXISTS (SELECT idkey FROM #results WHERE idkey=@id)
			INSERT INTO #results2 SELECT NodeName, ID, ParentID, Example, Attribute, Closing FROM #results WHERE idkey=@id

		SELECT @id= MIN(idkey) FROM #results WHERE idkey > @id AND ParentID IS NOT NULL
	END

	SELECT idkey, 
		CASE WHEN Attribute IS NOT NULL AND Example IS NULL AND EXISTS (SELECT 1 FROM #results2 r WHERE r.ParentID=#results2.ID) THEN REPLACE(REPLACE(Attribute,' />',''),'<','') 
		WHEN Attribute IS NOT NULL AND Example IS NULL THEN Attribute 
		WHEN Attribute IS NOT NULL AND Example IS NOT NULL THEN NULL 		
		ELSE NodeName END AS NodeName, ID, ParentID, 
		CASE WHEN Closing IS NOT NULL AND Attribute IS NOT NULL THEN REPLACE(Attribute,'/','') + Example + Closing 
		ELSE Example END As Example
	FROM #results2

	DROP TABLE #results
	DROP TABLE #results2
END
GO
GRANT EXECUTE ON remispStationGroupConfiguration TO REMI
GO