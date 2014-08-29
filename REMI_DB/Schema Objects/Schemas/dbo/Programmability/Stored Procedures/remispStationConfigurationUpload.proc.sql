ALTER PROCEDURE [dbo].remispStationConfigurationUpload AS
BEGIN
	CREATE TABLE #temp2 (ID INT, ParentID INT, NodeType INT, LocalName NVARCHAR(100), Text NVARCHAR(100), ID_temp INT IDENTITY(1,1), ID_NEW INT, ParentID_NEW INT)
	CREATE TABLE #temp3 (LookupID INT, Type NVARCHAR(150), LocalName NVARCHAR(150), ID INT IDENTITY(1,1))
	DECLARE @TrackingLocationHostID INT
	DECLARE @MaxID INT
	DECLARE @MaxLookupID INT
	DECLARE @idoc INT
	DECLARE @PluginID INT
	DECLARE @ID INT
	DECLARE @xml XML
	DECLARE @LastUser NVARCHAR(255)

	IF ((SELECT COUNT(*) FROM StationConfigurationUpload WHERE ISNULL(IsProcessed,0)=0)=0)
		RETURN

	WHILE ((SELECT COUNT(*) FROM StationConfigurationUpload WHERE ISNULL(IsProcessed,0)=0)>0)
	BEGIN
		SELECT TOP 1 @ID=ID, @xml =StationConfigXML, @TrackingLocationHostID=TrackingLocationHostID, @LastUser=LastUser, @PluginID = TrackingLocationPluginID
		FROM StationConfigurationUpload 
		WHERE ISNULL(IsProcessed,0)=0
				
		IF (@PluginID = 0)
			SET @PluginID = NULL

		exec sp_xml_preparedocument @idoc OUTPUT, @xml
	
		SELECT @MaxID = ISNULL(MAX(ID),0)+1 FROM TrackingLocationsHostsConfiguration
		SELECT @MaxLookupID = ISNULL(MAX(LookupID),0)+1 FROM Lookups

		SELECT * 
		INTO #temp
		FROM OPENXML(@idoc, '/')

		INSERT INTO #temp2 (ID, ParentID, NodeType, LocalName, Text, ParentID_NEW)
		SELECT ID, ParentID, NodeType, LocalName, '' AS Text, 0 AS ParentID_NEW
		FROM #temp 
		WHERE NodeType=1 AND (SELECT COUNT(ISNULL(ParentID,0)) FROM #temp t WHERE t.ParentID=#temp.ID AND t.ParentID IS NOT NULL)>1
		UNION
		SELECT ID, ParentID, NodeType, LocalName, '' AS Text, 0 AS ParentID_NEW
		FROM #temp 
		WHERE NodeType=1 AND (SELECT COUNT(*) FROM #temp t1 WHERE t1.NodeType=1 AND t1.ParentID=#temp.ID AND t1.ParentID IS NOT NULL GROUP BY t1.ParentID )=1
		UNION
		SELECT ID, ParentID, NodeType, LocalName, '' AS Text, 0 AS ParentID_NEW
		FROM #temp 
		WHERE NodeType=1 AND (SELECT COUNT(ISNULL(ParentID,0)) FROM #temp t WHERE t.ParentID=#temp.ID AND t.ParentID IS NOT NULL AND t.NodeType <> 3)=1
	
		UPDATE #temp2
		SET ID_NEW = ID_temp + @MaxID

		UPDATE #temp2
		SET ParentID_NEW = (SELECT t.ID_NEW FROM #temp2 t WHERE #temp2.ParentID=t.ID)
		WHERE #temp2.ParentID IS NOT NULL

		SET IDENTITY_INSERT TrackingLocationsHostsConfiguration ON

		INSERT INTO TrackingLocationsHostsConfiguration (ID, ParentId, ViewOrder, NodeName, LastUser, TrackingLocationHostID, TrackingLocationProfileID)
		SELECT ID_NEW, CASE WHEN ParentID_NEW = 0 THEN NULL ELSE ParentID_NEW END, ROW_NUMBER() OVER (ORDER BY id) AS ViewOrder, LocalName, @LastUser, @TrackingLocationHostID, @PluginID
		FROM #temp2
		ORDER BY ID, parentid

		SET IDENTITY_INSERT TrackingLocationsHostsConfiguration OFF
	
		INSERT INTO #temp3
		SELECT DISTINCT 0 AS LookupID, 'Configuration' AS Type, LTRIM(RTRIM(LocalName)) AS LocalName
		FROM #temp 
		WHERE NodeType=2 AND LocalName NOT IN (SELECT Lookups.[Values] FROM Lookups WHERE Type='Configuration')

		INSERT INTO #temp3
		SELECT DISTINCT 0 AS LookupID, 'Configuration' AS Type, LTRIM(RTRIM(LocalName)) AS LocalName
		FROM #temp 
		WHERE NodeType=1 AND LocalName NOT IN (SELECT Lookups.[Values] FROM Lookups WHERE Type='Configuration')
			AND ID IN (SELECT ParentID FROM #temp WHERE NodeType=3)

		UPDATE #temp3 SET LookupID=ID+@MaxLookupID

		insert into Lookups (LookupID, Type, [Values])
		select LookupID, Type, localname as [Values] from #temp3
	
		INSERT INTO TrackingLocationsHostsConfigValues (Value, LookupID, TrackingConfigID, LastUser, IsAttribute)
		SELECT ISNULL((SELECT t2.Text FROM #temp t2 WHERE t2.NodeType=3 AND t2.ParentID=#temp.ID), '') AS Value, 
			CASE WHEN #temp.NodeType=2 THEN (SELECT LookupID FROM Lookups WHERE Type='Configuration' AND [values]=#temp.LocalName) ELSE NULL END As LookupID, 
			(SELECT ID_NEW FROM #temp2 WHERE #temp.ParentID=#temp2.ID) AS TrackingConfigID, @LastUser As LastUser, 1 AS IsAttribute
		FROM #temp
		WHERE #temp.NodeType=2

		INSERT INTO TrackingLocationsHostsConfigValues (Value, LookupID, TrackingConfigID, LastUser, IsAttribute)
		SELECT ISNULL(#temp.Text,'') AS Value, (SELECT Lookups.LookupID FROM #temp t INNER JOIN Lookups ON Type='Configuration' AND LOWER(LTRIM(RTRIM([Values])))=LOWER(LTRIM(RTRIM(t.LocalName))) WHERE t.NodeType=1 AND t.id=#temp.parentid) AS LookupID,
			(SELECT #temp2.ID_NEW 
			FROM #temp2 	
				INNER JOIN #temp t1 ON t1.NodeType=1 AND #temp2.ID=t1.parentid
			WHERE #temp.ParentID=t1.ID) AS TrackingConfigID, 
			@LastUser As LastUser, 0 AS IsAttribute
		FROM #temp
		WHERE NodeType=3 AND ParentID NOT IN (Select ID FROM #temp WHERE #temp.NodeType=2)

		INSERT INTO TrackingLocationsHostsConfigValues (Value, LookupID, TrackingConfigID, LastUser, IsAttribute)
		SELECT ISNULL(#temp.Text,'') AS Value, (SELECT Lookups.LookupID FROM #temp t INNER JOIN Lookups ON Type='Configuration' AND LOWER(LTRIM(RTRIM([Values])))=LOWER(LTRIM(RTRIM(t.LocalName))) WHERE t.NodeType=1 AND t.id=#temp.id) AS LookupID,
			(SELECT #temp2.ID_NEW 
			FROM #temp2 	
				INNER JOIN #temp t1 ON t1.NodeType=1 AND #temp2.ID=t1.parentid
			WHERE #temp.ID=t1.ID) AS TrackingConfigID, 
			@LastUser As LastUser, 0 AS IsAttribute
		FROM #temp
		WHERE NodeType=1 AND ID NOT IN (Select ParentID FROM #temp t WHERE t.NodeType =3)
			AND ID NOT IN (Select ID FROM #temp2)	

		DELETE FROM #temp2
		DELETE FROM #temp3
		DROP TABLE #temp
		
		UPDATE StationConfigurationUpload SET IsProcessed=1 WHERE ID=@ID
	END

	DROP TABLE #temp2
	DROP TABLE #temp3
END
GO
GRANT EXECUTE ON remispStationConfigurationUpload TO Remi
GO