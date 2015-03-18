/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        CI0000001593275.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 10/3/2013 1:33:24 PM

*/
SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#tmpErrors')) DROP TABLE #tmpErrors
GO
CREATE TABLE #tmpErrors (Error int)
GO
SET XACT_ABORT ON
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO
BEGIN TRANSACTION
GO
PRINT N'Creating [dbo].[TrackingLocationsPlugin]'
GO
CREATE TABLE [dbo].[TrackingLocationsPlugin]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[TrackingLocationID] [int] NOT NULL,
[PluginName] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_TrackingLocationPlugin] on [dbo].[TrackingLocationsPlugin]'
GO
ALTER TABLE [dbo].[TrackingLocationsPlugin] ADD CONSTRAINT [PK_TrackingLocationPlugin] PRIMARY KEY CLUSTERED  ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[TrackingLocationsHostsConfiguration]'
GO
ALTER TABLE [dbo].[TrackingLocationsHostsConfiguration] ADD
[TrackingLocationProfileID] [int] NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispTrackingLocationPlugins]'
GO
CREATE PROCEDURE [dbo].[remispTrackingLocationPlugins] @TrackingLocationID INT
AS
BEGIN
	SELECT *, (CASE WHEN (SELECT COUNT(ID) FROM TrackingLocationsHostsConfiguration WHERE TrackingLocationProfileID = tlp.ID) > 0 THEN 0 ELSE 1 END) AS CanDelete
	FROM TrackingLocationsPlugin tlp
	WHERE tlp.TrackingLocationID=@TrackingLocationID
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[StationConfigurationUpload]'
GO
ALTER TABLE [dbo].[StationConfigurationUpload] ADD
[TrackingLocationPluginID] [int] NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispDeleteStationConfigurationHeader]'
GO
ALTER PROCEDURE [dbo].[remispDeleteStationConfigurationHeader] @HostConfigID INT, @LastUser NVARCHAR(255), @ProfileID INT
AS
BEGIN
	IF (EXISTS (SELECT 1 FROM TrackingLocationsHostsConfiguration WHERE ID=@HostConfigID AND TrackingLocationProfileID=@ProfileID) AND NOT EXISTS (SELECT 1 FROM dbo.TrackingLocationsHostsConfigValues WHERE TrackingConfigID=@HostConfigID))
	BEGIN
		DELETE FROM TrackingLocationsHostsConfiguration WHERE ID=@HostConfigID AND TrackingLocationProfileID=@ProfileID
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispCopyStationConfiguration]'
GO
ALTER PROCEDURE [dbo].[remispCopyStationConfiguration] @HostID INT, @copyFromHostID INT, @LastUser NVARCHAR(255), @ProfileID INT = NULL
AS
BEGIN
	BEGIN TRANSACTION
	
	DECLARE @FromCount INT
	DECLARE @ToCount INT
	DECLARE @max INT
	DECLARE @copyFromProfileID INT
	SET @max = (SELECT MAX(ID) +1 FROM dbo.TrackingLocationsHostsConfiguration)
	
	SELECT TOP 1 @copyFromProfileID = TrackingLocationProfileID FROM TrackingLocationsHostsConfiguration WHERE TrackingLocationHostID=@copyFromHostID
	
	if (@copyFromProfileID = 0)
		SET @copyFromProfileID = NULL
	
	SELECT @FromCount = COUNT(*) FROM TrackingLocationsHostsConfiguration WHERE TrackingLocationHostID=@copyFromHostID AND TrackingLocationProfileID=@copyFromProfileID
	
	SELECT tempID=IDENTITY (int, 1, 1), CONVERT(int,ID) As ID, ParentId, ViewOrder, NodeName, @HostID AS TrackingLocationHostID, @LastUser AS LastUser, 0 AS newproID, NULL AS newParentID, @ProfileID As TrackingLocationProfileID
	INTO #TrackingLocationsHostsConfiguration
	FROM TrackingLocationsHostsConfiguration
	WHERE TrackingLocationHostID=@copyFromHostID AND TrackingLocationProfileID=@copyFromProfileID
	
	UPDATE #TrackingLocationsHostsConfiguration SET newproID=@max+tempid
	
	UPDATE #TrackingLocationsHostsConfiguration 
	SET #TrackingLocationsHostsConfiguration.newParentID = pc2.newproID
	FROM #TrackingLocationsHostsConfiguration
		LEFT OUTER JOIN #TrackingLocationsHostsConfiguration pc2 ON #TrackingLocationsHostsConfiguration.ParentID=pc2.ID
		
	SET Identity_Insert TrackingLocationsHostsConfiguration ON
	
	INSERT INTO TrackingLocationsHostsConfiguration (ID, ParentId, ViewOrder, NodeName, TrackingLocationHostID, LastUser, TrackingLocationProfileID)
	SELECT newproID, newParentId, ViewOrder, NodeName, TrackingLocationHostID, LastUser, TrackingLocationProfileID
	FROM #TrackingLocationsHostsConfiguration
	
	SET Identity_Insert TrackingLocationsHostsConfiguration OFF
	
	SELECT @ToCount = COUNT(*) FROM TrackingLocationsHostsConfiguration WHERE TrackingLocationHostID=@HostID

	IF (@FromCount = @ToCount)
	BEGIN
		SELECT @FromCount = COUNT(*) FROM TrackingLocationsHostsConfiguration pc INNER JOIN dbo.TrackingLocationsHostsConfigValues pcv ON pc.ID=pcv.TrackingConfigID WHERE TrackingLocationHostID=@copyFromHostID AND TrackingLocationProfileID=@copyFromProfileID
	
		INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
		SELECT Value, LookupID, #TrackingLocationsHostsConfiguration.newproID AS TrackingConfigID, @LastUser AS LastUser, IsAttribute
		FROM TrackingLocationsHostsConfigValues
			INNER JOIN TrackingLocationsHostsConfiguration ON TrackingLocationsHostsConfigValues.TrackingConfigID=TrackingLocationsHostsConfiguration.ID
			INNER JOIN #TrackingLocationsHostsConfiguration ON TrackingLocationsHostsConfiguration.ID=#TrackingLocationsHostsConfiguration.ID	
			
		SELECT @ToCount = COUNT(*) FROM TrackingLocationsHostsConfiguration pc INNER JOIN TrackingLocationsHostsConfigValues pcv ON pc.ID=pcv.TrackingConfigID WHERE TrackingLocationHostID=@HostID
		
		IF (@FromCount <> @ToCount)
		BEGIN
			GOTO HANDLE_ERROR
		END
		GOTO HANDLE_SUCESS
	END
	ELSE
	BEGIN
		GOTO HANDLE_ERROR
	END
	
	HANDLE_SUCESS:
		IF @@TRANCOUNT > 0
			COMMIT TRANSACTION
			RETURN	
	
	HANDLE_ERROR:
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION
			RETURN	
    
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispSaveStationConfiguration]'
GO
ALTER PROCEDURE [dbo].[remispSaveStationConfiguration] @HostConfigID INT, @parentID INT, @ViewOrder INT, @NodeName NVARCHAR(200), @HostID INT, @LastUser NVARCHAR(255), @PluginID INT
AS
BEGIN
	If ((@HostConfigID IS NULL OR @HostConfigID = 0 OR NOT EXISTS (SELECT 1 FROM TrackingLocationsHostsConfiguration WHERE TrackingLocationHostID=@HostID)) AND @NodeName IS NOT NULL AND LTRIM(RTRIM(@NodeName)) <> '')
	BEGIN
		INSERT INTO TrackingLocationsHostsConfiguration (ParentId, ViewOrder, NodeName, TrackingLocationHostID, LastUser, TrackingLocationProfileID)
		VALUES (CASE WHEN @parentID = 0 THEN NULL ELSE @parentID END, @ViewOrder, @NodeName, @HostID, @LastUser, @PluginID)
		
		SET @HostConfigID = SCOPE_IDENTITY()
	END
	ELSE IF (@HostConfigID > 0)
	BEGIN
		UPDATE TrackingLocationsHostsConfiguration
		SET ParentId=CASE WHEN @parentID = 0 THEN NULL ELSE @parentID END, ViewOrder=@ViewOrder, NodeName=@NodeName, LastUser=@LastUser, TrackingLocationProfileID=@PluginID
		WHERE ID=@HostConfigID
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispGetStationConfiguration]'
GO
ALTER PROCEDURE [dbo].[remispGetStationConfiguration] @hostID INT, @ProfileID INT
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispStationGroupConfiguration]'
GO
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispStationConfigurationProcess]'
GO
ALTER PROCEDURE [dbo].remispStationConfigurationProcess @HostID INT, @XML AS NTEXT, @LastUser As NVARCHAR(255), @PluginID INT = 0
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM StationConfigurationUpload WHERE TrackingLocationHostID=@HostID And TrackingLocationPluginID=@PluginID)
		INSERT INTO StationConfigurationUpload (StationConfigXML, TrackingLocationHostID, LastUser, TrackingLocationPluginID) Values (CONVERT(XML, @XML), @HostID, @LastUser, @PluginID)
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispStationConfigurationUpload]'
GO
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTrackingLocationsSearchFor]'
GO
ALTER PROCEDURE [dbo].[remispTrackingLocationsSearchFor]
/*	'===============================================================
	'   NAME:                	remispTrackingLocationsSearchFor
	'   DATE CREATED:       	21 Oct 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves paged data from table: TrackingLocations OR the number of records in the table
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
@RecordCount int = NULL OUTPUT,
@ID int = null,
@TrackingLocationName nvarchar(400)= null, 
@GeoLocationID INT= null, 
@Status int = null,
@TrackingLocationTypeID int= null,
@TrackingLocationTypeName nvarchar(400)=null,
@TrackingLocationFunction int = null,
@HostName nvarchar(255) = null,
@OnlyActive INT = 0,
@RemoveHosts INT = 0
AS
DECLARE @TrueBit BIT
DECLARE @FalseBit BIT
SET @TrueBit = CONVERT(BIT, 1)
SET @FalseBit = CONVERT(BIT, 0)

IF (@RecordCount IS NOT NULL)
BEGIN
	SET @RecordCount = (SELECT distinct COUNT(*) 
	FROM TrackingLocations as tl 
		INNER JOIN TrackingLocationTypes as tlt ON tl.TrackingLocationTypeID = tlt.ID
		LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
	WHERE (tl.ID = @ID or @ID is null) 
	and (tlh.status = @Status or @Status is null)
	and (tl.TrackingLocationName = @TrackingLocationName or @TrackingLocationName is null)
	and (TestCenterLocationID = @GeoLocationID or @GeoLocationID is null)
	and (tlh.HostName = @HostName or tlh.HostName='all' or @HostName is null)
	and (tl.TrackingLocationTypeID = @TrackingLocationTypeID or @TrackingLocationTypeID is null)
	and ((tl.TrackingLocationTypeID= tlt.id and tlt.TrackingLocationTypeName = @TrackingLocationTypeName) or @TrackingLocationTypeName is null)
	 and ((tl.TrackingLocationTypeID= tlt.id and tlt.TrackingLocationFunction = @TrackingLocationFunction )or @TrackingLocationFunction is null)
	 AND (
				(@OnlyActive = 1 AND ISNULL(tl.Decommissioned, 0) = 0)
				OR
				(@OnlyActive = 0)
			)
	)
	RETURN
END

SELECT DISTINCT tl.ID, tl.TrackingLocationName, tl.TestCenterLocationID, 
	CASE WHEN @RemoveHosts = 1 THEN 1 ELSE CASE WHEN tlh.Status IS NULL THEN 3 ELSE tlh.Status END END AS Status, 
	tl.LastUser, 
	CASE WHEN @RemoveHosts = 1 THEN '' ELSE tlh.HostName END AS HostName,
	tl.ConcurrencyID, tl.comment,l3.[Values] AS GeoLocationName, 
	CASE WHEN @RemoveHosts = 1 THEN 0 ELSE ISNULL(tlh.ID,0) END AS TrackingLocationHostID,
	(
		SELECT COUNT(*) as CurrentCount 
		FROM TestUnits AS tu
			INNER JOIN DeviceTrackingLog AS dtl ON dtl.TestUnitID = tu.ID
		WHERE dtl.TrackingLocationID = tl.ID and (dtl.OutUser IS NULL)
	) AS CurrentCount,
	tlt.wilocation as TLTWILocation, tlt.UnitCapacity as TLTUnitCapacity, tlt.Comment as TLTComment, tlt.ConcurrencyID as TLTConcurrencyID, tlt.LastUser as TLTLastUser,
	tlt.ID as TLTID, tlt.TrackingLocationTypeName as TLTName, tlt.TrackingLocationFunction as TLTFunction,
	(
		SELECT TOP(1) tu.CurrentTestName as CurrentTestName
		FROM TestUnits AS tu
			INNER JOIN DeviceTrackingLog AS dtl ON dtl.TestUnitID = tu.ID
		WHERE tu.CurrentTestName is not null and dtl.TrackingLocationID = tl.ID and (dtl.OutUser IS NULL)
	) AS CurrentTestName,
	(CASE WHEN EXISTS (SELECT TOP 1 1 FROM DeviceTrackingLog dl WHERE dl.TrackingLocationID=tl.ID) THEN @FalseBit ELSE @TrueBit END) As CanDelete,
	ISNULL(tl.Decommissioned, 0) AS Decommissioned, ISNULL(tl.IsMultiDeviceZone, 0) AS IsMultiDeviceZone, tl.Status AS LocationStatus
	FROM TrackingLocations as tl
		INNER JOIN TrackingLocationTypes as tlt ON tl.TrackingLocationTypeID = tlt.ID
		LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
		LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND l3.lookupID=tl.TestCenterLocationID
	WHERE (tl.ID = @ID or @ID is null) and (tlh.status = @Status or @Status is null)
		and (tl.TrackingLocationName = @TrackingLocationName or @TrackingLocationName is null)
		and (TestCenterLocationID = @GeoLocationID or @GeoLocationID is null)
		and 
		(
			tlh.HostName = @HostName 
			or 
			tlh.HostName='all'
			or
			@HostName is null 
			or 
			(
				@HostName is not null 
				and exists 
					(
						SELECT tlt1.TrackingLocationTypeName 
						FROM TrackingLocations as tl1
							INNER JOIN trackinglocationtypes as tlt1 ON tlt1.ID = tl1.TrackingLocationTypeID
							INNER JOIN TrackingLocationsHosts tlh1 ON tl1.ID = tlh1.TrackingLocationID
						WHERE tlh1.HostName = @HostName and tlt1.TrackingLocationTypeName = 'Storage'
					)
			)
		)
		and (tl.TrackingLocationTypeID= tlt.id and tlt.id = @TrackingLocationTypeID or @TrackingLocationTypeID is null)
		and (tl.TrackingLocationTypeID= tlt.id and tlt.TrackingLocationTypeName = @TrackingLocationTypeName or @TrackingLocationTypeName is null)
		and (tl.TrackingLocationTypeID= tlt.id and tlt.TrackingLocationFunction = @TrackingLocationFunction or @TrackingLocationFunction is null)
		AND (
				(@OnlyActive = 1 AND ISNULL(tl.Decommissioned, 0) = 0)
				OR
				(@OnlyActive = 0)
			)
	ORDER BY ISNULL(tl.Decommissioned, 0), tl.TrackingLocationName
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTrackingLocationsInsertUpdateSingleItem]'
GO
ALTER PROCEDURE [dbo].[remispTrackingLocationsInsertUpdateSingleItem]
	@ID int OUTPUT,
	@trackingLocationName nvarchar(400),
	@TrackingLocationTypeID int, 
	@GeoLocationID INT, 
	@ConcurrencyID rowversion OUTPUT,
	@Status int,
	@LastUser nvarchar(255),
	@Comment nvarchar(1000) = null,
	@HostName nvarchar(255) = null,
	@Decommissioned BIT = 0,
	@IsMultiDeviceZone BIT = 0,
	@LocationStatus INT
AS
	DECLARE @ReturnValue int
	DECLARE @AlreadyExists as integer 

	IF (@ID IS NULL) -- New Item
	BEGIN
		IF (@ID IS NULL) -- New Item
		BEGIN
			set @AlreadyExists = (select ID from TrackingLocations 
			where TrackingLocationName = @trackingLocationName and TestCenterLocationID = @GeoLocationID)

			if (@AlreadyExists is not null) 
				return -1
			end

			PRINT 'INSERTING'

			INSERT INTO TrackingLocations (TrackingLocationName, TestCenterLocationID, TrackingLocationTypeID, LastUser, Comment, Decommissioned, IsMultiDeviceZone, Status)
			VALUES (@TrackingLocationname, @GeoLocationID, @TrackingLocationtypeID, @LastUser, @Comment, @Decommissioned, @IsMultiDeviceZone, @LocationStatus)
			
			SELECT @ReturnValue = SCOPE_IDENTITY()

			INSERT INTO TrackingLocationsHosts (TrackingLocationID, HostName, LastUser, Status) VALUES (@ReturnValue, @HostName, @LastUser, @Status)
		END
		ELSE -- Exisiting Item
		BEGIN
			PRINT 'UDPATING TrackingLocations'
		
			UPDATE TrackingLocations 
			SET TrackingLocationName=@TrackingLocationName, 
				TestCenterLocationID=@GeoLocationID, 
				TrackingLocationTypeID=@TrackingLocationtypeID,
				LastUser = @LastUser,
				Comment = @Comment,
				Decommissioned = @Decommissioned,
				IsMultiDeviceZone = @IsMultiDeviceZone,
				Status = @LocationStatus
			WHERE ID = @ID AND ConcurrencyID = @ConcurrencyID
		
			SELECT @ReturnValue = @ID
		END

		SET @ConcurrencyID = (SELECT ConcurrencyID FROM TrackingLocations WHERE ID = @ReturnValue)
		SET @ID = @ReturnValue
	
		IF (@@ERROR != 0)
		BEGIN
			RETURN -1
		END
		ELSE
		BEGIN
			RETURN 0
		END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispDeleteStationConfiguration]'
GO
ALTER PROCEDURE [dbo].[remispDeleteStationConfiguration] @HostID INT, @LastUser NVARCHAR(255), @PluginID INT
AS
BEGIN
	UPDATE TrackingLocationsHostsConfigValues
	SET LastUser=@LastUser
	WHERE TrackingConfigID IN (SELECT ID FROM TrackingLocationsHostsConfiguration WHERE TrackingLocationHostID=@HostID AND TrackingLocationProfileID=@PluginID)
	
	UPDATE TrackingLocationsHostsConfiguration 
	SET LastUser=@LastUser
	WHERE TrackingLocationHostID=@HostID AND TrackingLocationProfileID=@PluginID
	
	DELETE FROM TrackingLocationsHostsConfigValues WHERE TrackingConfigID IN (SELECT ID FROM TrackingLocationsHostsConfiguration WHERE TrackingLocationHostID=@HostID AND TrackingLocationProfileID=@PluginID)
	DELETE FROM TrackingLocationsHostsConfiguration WHERE TrackingLocationHostID=@HostID AND TrackingLocationProfileID=@PluginID
	
	DELETE FROM StationConfigurationUpload WHERE TrackingLocationHostID=@HostID AND TrackingLocationPluginID=@PluginID
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [dbo].[TrackingLocationsHostsConfiguration]'
GO
ALTER TABLE [dbo].[TrackingLocationsHostsConfiguration] ADD CONSTRAINT [FK_TrackingLocationsHostsConfiguration_TrackingLocationsPlugin] FOREIGN KEY ([TrackingLocationProfileID]) REFERENCES [dbo].[TrackingLocationsPlugin] ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [dbo].[TrackingLocationsPlugin]'
GO
ALTER TABLE [dbo].[TrackingLocationsPlugin] ADD CONSTRAINT [FK_TrackingLocationPlugin_TrackingLocations] FOREIGN KEY ([TrackingLocationID]) REFERENCES [dbo].[TrackingLocations] ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remispTrackingLocationPlugins]'
GO
GRANT EXECUTE ON  [dbo].[remispTrackingLocationPlugins] TO [remi]
GO
insert into TrackingLocationsPlugin values (339,'CPC6000_BB10_Altimeter_TestControl')
go
alter table trackinglocations drop column PluginName
go
go
alter table TargetAccess Add WorkstationName NVARCHAR(50) NULL

IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[TargetAccess]') AND name = N'UX_TargetAccess_TargetName')
ALTER TABLE [dbo].[TargetAccess] DROP CONSTRAINT [UX_TargetAccess_TargetName]
GO

/****** Object:  Index [UX_TargetAccess_TargetName]    Script Date: 10/08/2013 12:39:10 ******/
ALTER TABLE [dbo].[TargetAccess] ADD  CONSTRAINT [UX_TargetAccess_TargetName] UNIQUE NONCLUSTERED 
(
	[TargetName] ASC, WorkstationName
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
ALTER procedure [dbo].[remispExceptionSearch] @ProductID INT = 0, @AccessoryGroupID INT = 0, @ProductTypeID INT = 0, @TestID INT = 0, @TestStageID INT = 0, @JobName NVARCHAR(400) = NULL, @IncludeBatches INT = 0, @RequestReason INT = 0
AS
BEGIN
	DECLARE @JobID INT
	SELECT @JobID = ID FROM Jobs WITH(NOLOCK) WHERE JobName=@JobName

	select *
	from 
	(
		select ROW_NUMBER() over (order by p.ProductGroupName desc)as row, pvt.ID, b.QRANumber, ISNULL(tu.Batchunitnumber, 0) as batchunitnumber, pvt.[ReasonForRequest], p.ProductGroupName,
		(select jobname from jobs,TestStages where teststages.id =pvt.TestStageid and Jobs.ID = TestStages.jobid) as jobname, 
		(select teststagename from teststages WITH(NOLOCK) where teststages.id =pvt.TestStageid) as teststagename, 
		t.TestName,pvt.TestStageID, pvt.TestUnitID,
		(select top 1 LastUser from TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
		(select top 1 ConcurrencyID from TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS ConcurrencyID,
		pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName
		FROM vw_ExceptionsPivoted as pvt WITH(NOLOCK)
			LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
			LEFT OUTER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = pvt.TestUnitID
			LEFT OUTER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
			LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
			LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
			LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
		WHERE (
				(pvt.[ProductID]=@ProductID) 
				OR
				(@ProductID = 0)
			)
			AND
			(
				(pvt.ReasonForRequest = @RequestReason)
				OR
				(@RequestReason = 0)
			)
			AND
			(
				(pvt.AccessoryGroupID = @AccessoryGroupID) 
				OR
				(@AccessoryGroupID = 0)
			)
			AND
			(
				(pvt.ProductTypeID = @ProductTypeID) 
				OR
				(@ProductTypeID = 0)
			)
			AND
			(
				(pvt.Test = @TestID) 
				OR
				(@TestID = 0)
			)
			AND
			(
				(pvt.TestStageID = @TestStageID) 
				OR
				(@TestStageID = 0 And @JobID IS NULL OR @JobID = 0)
				OR
				(@JobID > 0 And @TestStageID = 0 AND pvt.TestStageID IN (SELECT ID FROM TestStages WHERE JobID=@JobID))
			)
			AND
			(
				(@IncludeBatches = 1)
				OR
				(@IncludeBatches = 0 AND pvt.TestUnitID IS NULL)
			)
	) as exceptionResults
	ORDER BY QRANumber, Batchunitnumber, TestName
END
GO
GRANT EXECUTE ON remispExceptionSearch TO REMI
GO
alter table batches add [IsMQual] BIT DEFAULT(0)
go
alter table batchesAudit add [IsMQual] BIT NULL
go
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
commit TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO