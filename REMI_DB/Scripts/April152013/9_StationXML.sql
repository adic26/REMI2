/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        ci0000001593275\SQLDeveloper.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 4/11/2013 10:52:28 AM

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
PRINT N'Creating [dbo].[TrackingLocationsHostsConfigValues]'
GO
CREATE TABLE [dbo].[TrackingLocationsHostsConfigValues]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[Value] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LookupID] [int] NOT NULL,
[TrackingConfigID] [int] NOT NULL,
[LastUser] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[IsAttribute] [bit] NOT NULL CONSTRAINT [DF_TrackingLocationsHostsConfigValues_IsAttribute] DEFAULT ((0))
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_TrackingLocationsHostsConfigValues] on [dbo].[TrackingLocationsHostsConfigValues]'
GO
ALTER TABLE [dbo].[TrackingLocationsHostsConfigValues] ADD CONSTRAINT [PK_TrackingLocationsHostsConfigValues] PRIMARY KEY CLUSTERED  ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[TrackingLocationsHostsConfiguration]'
GO
CREATE TABLE [dbo].[TrackingLocationsHostsConfiguration]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[TrackingLocationHostID] [int] NOT NULL,
[ParentID] [int] NULL,
[ViewOrder] [int] NULL,
[NodeName] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LastUser] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_TrackingLocationsHostsConfiguration] on [dbo].[TrackingLocationsHostsConfiguration]'
GO
ALTER TABLE [dbo].[TrackingLocationsHostsConfiguration] ADD CONSTRAINT [PK_TrackingLocationsHostsConfiguration] PRIMARY KEY CLUSTERED  ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispDeleteStationConfigurationHeader]'
GO
CREATE PROCEDURE [dbo].[remispDeleteStationConfigurationHeader] @HostConfigID INT, @LastUser NVARCHAR(255)
AS
BEGIN
	IF (EXISTS (SELECT 1 FROM TrackingLocationsHostsConfiguration WHERE ID=@HostConfigID) AND NOT EXISTS (SELECT 1 FROM dbo.TrackingLocationsHostsConfigValues WHERE TrackingConfigID=@HostConfigID))
	BEGIN
		DELETE FROM TrackingLocationsHostsConfiguration WHERE ID=@HostConfigID
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispDeleteStationConfigurationDetail]'
GO
CREATE PROCEDURE [dbo].[remispDeleteStationConfigurationDetail] @ConfigID INT, @LastUser NVARCHAR(255)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TrackingLocationsHostsConfigValues WHERE ID=@ConfigID)
	BEGIN
		DELETE FROM dbo.TrackingLocationsHostsConfigValues WHERE ID=@ConfigID
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispCopyStationConfiguration]'
GO
CREATE PROCEDURE [dbo].[remispCopyStationConfiguration] @HostID INT, @copyFromHostID INT, @LastUser NVARCHAR(255)
AS
BEGIN
	BEGIN TRANSACTION
	
	DECLARE @FromCount INT
	DECLARE @ToCount INT
	DECLARE @max INT
	SET @max = (SELECT MAX(ID) +1 FROM dbo.TrackingLocationsHostsConfiguration)
	
	SELECT @FromCount = COUNT(*) FROM TrackingLocationsHostsConfiguration WHERE TrackingLocationHostID=@copyFromHostID
	
	SELECT tempID=IDENTITY (int, 1, 1), CONVERT(int,ID) As ID, ParentId, ViewOrder, NodeName, @HostID AS TrackingLocationHostID, @LastUser AS LastUser, 0 AS newproID, NULL AS newParentID
	INTO #TrackingLocationsHostsConfiguration
	FROM TrackingLocationsHostsConfiguration
	WHERE TrackingLocationHostID=@copyFromHostID
	
	UPDATE #TrackingLocationsHostsConfiguration SET newproID=@max+tempid
	
	UPDATE #TrackingLocationsHostsConfiguration 
	SET #TrackingLocationsHostsConfiguration.newParentID = pc2.newproID
	FROM #TrackingLocationsHostsConfiguration
		LEFT OUTER JOIN #TrackingLocationsHostsConfiguration pc2 ON #TrackingLocationsHostsConfiguration.ParentID=pc2.ID
		
	SET Identity_Insert TrackingLocationsHostsConfiguration ON
	
	INSERT INTO TrackingLocationsHostsConfiguration (ID, ParentId, ViewOrder, NodeName, TrackingLocationHostID, LastUser)
	SELECT newproID, newParentId, ViewOrder, NodeName, TrackingLocationHostID, LastUser
	FROM #TrackingLocationsHostsConfiguration
	
	SET Identity_Insert TrackingLocationsHostsConfiguration OFF
	
	SELECT @ToCount = COUNT(*) FROM TrackingLocationsHostsConfiguration WHERE TrackingLocationHostID=@HostID

	IF (@FromCount = @ToCount)
	BEGIN
		SELECT @FromCount = COUNT(*) FROM TrackingLocationsHostsConfiguration pc INNER JOIN dbo.TrackingLocationsHostsConfigValues pcv ON pc.ID=pcv.TrackingConfigID WHERE TrackingLocationHostID=@copyFromHostID
	
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
PRINT N'Creating [dbo].[remispGetSimilarStationConfiguration]'
GO
CREATE PROCEDURE [dbo].[remispGetSimilarStationConfiguration] @HostID INT
AS
BEGIN
	SELECT sc.TrackingLocationHostID AS ID, tl.TrackingLocationName
	FROM TrackingLocationsHostsConfiguration sc
		INNER JOIN TrackingLocationsHosts tlh on sc.TrackingLocationHostID = tlh.ID
		INNER JOIN TrackingLocations tl ON tlh.TrackingLocationID=tl.ID
	WHERE tl.TrackingLocationTypeID = (SELECT TrackingLocationTypeID FROM TrackingLocations tl2 INNER JOIN TrackingLocationsHosts tlh2 ON tl2.ID=tlh2.TrackingLocationID WHERE tlh2.ID=@HostID)
	GROUP BY sc.TrackingLocationHostID, tl.TrackingLocationName
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispSaveStationConfigurationDetails]'
GO
CREATE PROCEDURE [dbo].[remispSaveStationConfigurationDetails] @HostConfigID INT, @configID INT, @lookupID INT, @lookupValue NVARCHAR(200), @HostID INT, @LastUser NVARCHAR(255), @IsAttribute BIT = 0
AS
BEGIN	
	If ((@configID IS NULL OR @configID = 0 OR NOT EXISTS (SELECT 1 FROM TrackingLocationsHostsConfigValues WHERE ID=@configID)) AND @lookupValue IS NOT NULL AND LTRIM(RTRIM(@lookupValue)) <> '' AND @LookupID IS NOT NULL AND @LookupID > 0 AND EXISTS(SELECT 1 FROM TrackingLocationsHostsConfiguration WHERE ID=@HostConfigID))
	BEGIN
		INSERT INTO TrackingLocationsHostsConfigValues (Value, LookupID, TrackingConfigID, LastUser, IsAttribute)
		VALUES (@lookupValue, @LookupID, @HostConfigID, @LastUser, ISNULL(@IsAttribute,0))
	END
	ELSE IF (@configID > 0)
	BEGIN
		UPDATE TrackingLocationsHostsConfigValues
		SET Value=@lookupValue, LookupID=@LookupID, LastUser=@LastUser, TrackingConfigID=@HostConfigID, IsAttribute=ISNULL(@IsAttribute,0)
		WHERE ID=@configID
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispSaveStationConfiguration]'
GO
CREATE PROCEDURE [dbo].[remispSaveStationConfiguration] @HostConfigID INT, @parentID INT, @ViewOrder INT, @NodeName NVARCHAR(200), @HostID INT, @LastUser NVARCHAR(255)
AS
BEGIN
	If ((@HostConfigID IS NULL OR @HostConfigID = 0 OR NOT EXISTS (SELECT 1 FROM TrackingLocationsHostsConfiguration WHERE TrackingLocationHostID=@HostID)) AND @NodeName IS NOT NULL AND LTRIM(RTRIM(@NodeName)) <> '')
	BEGIN
		INSERT INTO TrackingLocationsHostsConfiguration (ParentId, ViewOrder, NodeName, TrackingLocationHostID, LastUser)
		VALUES (CASE WHEN @parentID = 0 THEN NULL ELSE @parentID END, @ViewOrder, @NodeName, @HostID, @LastUser)
		
		SET @HostConfigID = SCOPE_IDENTITY()
	END
	ELSE IF (@HostConfigID > 0)
	BEGIN
		UPDATE TrackingLocationsHostsConfiguration
		SET ParentId=CASE WHEN @parentID = 0 THEN NULL ELSE @parentID END, ViewOrder=@ViewOrder, NodeName=@NodeName, LastUser=@LastUser
		WHERE ID=@HostConfigID
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispGetStationConfigurationDetails]'
GO
CREATE PROCEDURE [dbo].[remispGetStationConfigurationDetails] @hostConfigID INT
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispGetStationConfiguration]'
GO
CREATE PROCEDURE [dbo].[remispGetStationConfiguration] @hostID INT
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
		), CASE WHEN tc.ParentId IS NOT NULL THEN tcParent.NodeName ELSE NULL END) As ParentScheme
	FROM dbo.TrackingLocationsHostsConfiguration tc
		LEFT OUTER JOIN TrackingLocationsHostsConfiguration tcParent ON tc.ParentId=tcParent.ID
	WHERE tc.TrackingLocationHostID=@hostID
	ORDER BY tc.ViewOrder
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispStationGroupConfiguration]'
GO
CREATE PROCEDURE [dbo].remispStationGroupConfiguration @hostID INT AS
BEGIN
	DECLARE @rows VARCHAR(8000)
	DECLARE @rows2 VARCHAR(8000)
	DECLARE @query VARCHAR(4000)
	DECLARE @id INT
	CREATE TABLE #results (idkey [int] IDENTITY(1,1),  NodeName varchar(150), ID int, ParentID int, Example varchar(800), Attribute varchar(800), Closing varchar(800))
	CREATE TABLE #results2 (idkey [int] IDENTITY(1,1),  NodeName varchar(150), ID int, ParentID int, Example varchar(800), Attribute varchar(800), Closing varchar(800))

	SELECT @rows=  ISNULL(STUFF(
	( 
	SELECT DISTINCT '],[' + l.[Values] 
	FROM  dbo.TrackingLocationsHostsConfiguration tc
	inner join dbo.TrackingLocationsHostsConfigValues val on tc.ID = val.TrackingConfigID and ISNULL(isattribute,0)=0
	inner join Lookups l on val.LookupID=l.LookupID
	where TrackingLocationHostID=@hostID
	ORDER BY '],[' +  l.[Values]
	FOR XML PATH('')), 1, 2, '') + ']','[na]')
	
	SELECT @rows2=  ISNULL(STUFF(
	( 
	SELECT DISTINCT '],[' + l.[Values] 
	FROM    TrackingLocationsHostsConfiguration tc
	inner join TrackingLocationsHostsConfigValues val on tc.ID = val.TrackingConfigID and ISNULL(isattribute,0)=1
	inner join Lookups l on val.LookupID=l.LookupID
	where TrackingLocationHostID=@hostID
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
@HostName nvarchar(255) = null
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
	)
	RETURN
END

SELECT DISTINCT tl.ID, tl.TrackingLocationName, tl.TestCenterLocationID, CASE WHEN tlh.Status IS NULL THEN 3 ELSE tlh.Status END AS Status, tl.LastUser, tlh.HostName,
	tl.ConcurrencyID, tl.comment,l3.[Values] AS GeoLocationName, ISNULL(tlh.ID,0) AS TrackingLocationHostID,
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
	ISNULL(tl.Decommissioned, 0) AS Decommissioned
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
	ORDER BY ISNULL(tl.Decommissioned, 0), tl.TrackingLocationName
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[StationConfigurationUpload]'
GO
CREATE TABLE [dbo].[StationConfigurationUpload]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[StationConfigXML] [xml] NOT NULL,
[IsProcessed] [bit] NOT NULL CONSTRAINT [StationConfigurationUpload_isProcessed] DEFAULT ((0)),
[TrackingLocationHostID] [int] NOT NULL,
[LastUser] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_StationConfigurationUpload] on [dbo].[StationConfigurationUpload]'
GO
ALTER TABLE [dbo].[StationConfigurationUpload] ADD CONSTRAINT [PK_StationConfigurationUpload] PRIMARY KEY CLUSTERED  ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispStationConfigurationProcess]'
GO
CREATE PROCEDURE [dbo].remispStationConfigurationProcess @HostID INT, @XML AS NTEXT, @LastUser As NVARCHAR(255)
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM StationConfigurationUpload WHERE TrackingLocationHostID=@HostID)
		INSERT INTO StationConfigurationUpload (StationConfigXML, TrackingLocationHostID, LastUser) Values (CONVERT(XML, @XML), @HostID, @LastUser)
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispStationConfigurationUpload]'
GO
CREATE PROCEDURE [dbo].remispStationConfigurationUpload AS
BEGIN
	CREATE TABLE #temp2 (ID INT, ParentID INT, NodeType INT, LocalName NVARCHAR(100), Text NVARCHAR(100), ID_temp INT IDENTITY(1,1), ID_NEW INT, ParentID_NEW INT)
	DECLARE @TrackingLocationHostID INT
	DECLARE @MaxID INT
	DECLARE @MaxLookupID INT
	DECLARE @idoc INT
	DECLARE @ID INT
	DECLARE @xml XML
	DECLARE @LastUser NVARCHAR(255)

	IF ((SELECT COUNT(*) FROM StationConfigurationUpload WHERE ISNULL(IsProcessed,0)=0)=0)
		RETURN

	SELECT TOP 1 @ID=ID, @xml =StationConfigXML, @TrackingLocationHostID=TrackingLocationHostID, @LastUser=LastUser
	FROM StationConfigurationUpload 
	WHERE ISNULL(IsProcessed,0)=0

	exec sp_xml_preparedocument @idoc OUTPUT, @xml
	
	SELECT @MaxID = ISNULL(MAX(ID),0)+1 FROM TrackingLocationsHostsConfiguration
	SELECT @MaxLookupID = MAX(LookupID)+1 FROM Lookups

	SELECT * 
	INTO #temp
	FROM OPENXML(@idoc, '/')

	INSERT INTO #temp2 (ID, ParentID, NodeType, LocalName, Text, ParentID_NEW)
	SELECT ID, ParentID, NodeType, LocalName, '' AS Text, 0 AS ParentID_NEW
	FROM #temp 
	WHERE NodeType=1 AND (SELECT COUNT(ParentID) FROM #temp t WHERE t.ParentID=#temp.ID)>1
	UNION
	SELECT ID, ParentID, NodeType, LocalName, '' AS Text, 0 AS ParentID_NEW
	FROM #temp 
	WHERE NodeType=1 AND (SELECT COUNT(*) FROM #temp t1 WHERE t1.NodeType=1 AND t1.ParentID=#temp.ID  GROUP BY t1.ParentID )=1
	UNION
	SELECT ID, ParentID, NodeType, LocalName, '' AS Text, 0 AS ParentID_NEW
	FROM #temp 
	WHERE NodeType=1 AND (SELECT COUNT(ParentID) FROM #temp t WHERE t.ParentID=#temp.ID)=1
	
	UPDATE #temp2
	SET ID_NEW = ID_temp + @MaxID

	UPDATE #temp2
	SET ParentID_NEW = (SELECT t.ID_NEW FROM #temp2 t WHERE #temp2.ParentID=t.ID)
	WHERE #temp2.ParentID IS NOT NULL

	SET IDENTITY_INSERT TrackingLocationsHostsConfiguration ON

	INSERT INTO TrackingLocationsHostsConfiguration (ID, ParentId, ViewOrder, NodeName, LastUser, TrackingLocationHostID)
	SELECT ID_NEW, CASE WHEN ParentID_NEW = 0 THEN NULL ELSE ParentID_NEW END, ROW_NUMBER() OVER (ORDER BY id) AS ViewOrder, LocalName, @LastUser, @TrackingLocationHostID
	FROM #temp2
	ORDER BY ID, parentid

	SET IDENTITY_INSERT TrackingLocationsHostsConfiguration OFF
	
	SELECT DISTINCT 0 AS LookupID, 'Configuration' AS Type, LTRIM(RTRIM(LocalName)) AS LocalName, IDENTITY(int,1,1) As ID
	INTO #temp3
	FROM #temp 
	WHERE NodeType=2 AND LocalName NOT IN (SELECT Lookups.[Values] FROM Lookups WHERE Type='Configuration')

	UPDATE #temp3 SET LookupID=ID+@MaxLookupID

	insert into Lookups (LookupID, Type, [Values])
	select LookupID, Type, localname as [Values] from #temp3
	
	INSERT INTO TrackingLocationsHostsConfigValues (Value, LookupID, TrackingConfigID, LastUser, IsAttribute)
	SELECT (SELECT t2.Text FROM #temp t2 WHERE t2.NodeType=3 AND t2.ParentID=#temp.ID) AS Value, 
		CASE WHEN #temp.NodeType=2 THEN (SELECT LookupID FROM Lookups WHERE Type='Configuration' AND [values]=#temp.LocalName) ELSE NULL END As LookupID, 
		(SELECT ID_NEW FROM #temp2 WHERE #temp.ParentID=#temp2.ID) AS TrackingConfigID, @LastUser As LastUser, 1 AS IsAttribute
	FROM #temp
	WHERE #temp.NodeType=2

	INSERT INTO TrackingLocationsHostsConfigValues (Value, LookupID, TrackingConfigID, LastUser, IsAttribute)
	SELECT #temp.Text AS Value, (SELECT Lookups.LookupID FROM #temp t INNER JOIN Lookups ON Type='Configuration' AND [Values]=t.LocalName WHERE t.NodeType=1 AND t.id=#temp.parentid) AS LookupID,
		(SELECT #temp2.ID_NEW 
		FROM #temp2 	
			INNER JOIN #temp t1 ON t1.NodeType=1 AND #temp2.ID=t1.parentid
		WHERE #temp.ParentID=t1.ID) AS TrackingConfigID, 
		@LastUser As LastUser, 0 AS IsAttribute
	FROM #temp
	WHERE NodeType=3 AND ParentID NOT IN (Select ID FROM #temp WHERE #temp.NodeType=2)

	DROP TABLE #temp2
	DROP TABLE #temp
	DROP TABLE #temp3
	
	UPDATE StationConfigurationUpload SET IsProcessed=1 WHERE ID=@ID
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [dbo].[TrackingLocationsHostsConfigValues]'
GO
ALTER TABLE [dbo].[TrackingLocationsHostsConfigValues] ADD CONSTRAINT [FK_TrackingLocationsHostsConfigValues_TrackingLocationsHostsConfiguration] FOREIGN KEY ([TrackingConfigID]) REFERENCES [dbo].[TrackingLocationsHostsConfiguration] ([ID])
ALTER TABLE [dbo].[TrackingLocationsHostsConfigValues] ADD CONSTRAINT [FK_TrackingLocationsHostsConfigValues_Lookups] FOREIGN KEY ([LookupID]) REFERENCES [dbo].[Lookups] ([LookupID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remispDeleteStationConfigurationHeader]'
GO
GRANT EXECUTE ON  [dbo].[remispDeleteStationConfigurationHeader] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispDeleteStationConfigurationDetail]'
GO
GRANT EXECUTE ON  [dbo].[remispDeleteStationConfigurationDetail] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispCopyStationConfiguration]'
GO
GRANT EXECUTE ON  [dbo].[remispCopyStationConfiguration] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispGetSimilarStationConfiguration]'
GO
GRANT EXECUTE ON  [dbo].[remispGetSimilarStationConfiguration] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispSaveStationConfigurationDetails]'
GO
GRANT EXECUTE ON  [dbo].[remispSaveStationConfigurationDetails] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispSaveStationConfiguration]'
GO
GRANT EXECUTE ON  [dbo].[remispSaveStationConfiguration] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispGetStationConfigurationDetails]'
GO
GRANT EXECUTE ON  [dbo].[remispGetStationConfigurationDetails] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispGetStationConfiguration]'
GO
GRANT EXECUTE ON  [dbo].[remispGetStationConfiguration] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispStationGroupConfiguration]'
GO
GRANT EXECUTE ON  [dbo].[remispStationGroupConfiguration] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispStationConfigurationProcess]'
GO
GRANT EXECUTE ON  [dbo].[remispStationConfigurationProcess] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispStationConfigurationUpload]'
GO
GRANT EXECUTE ON  [dbo].[remispStationConfigurationUpload] TO [remi]
GO
CREATE TABLE [dbo].[TrackingLocationsHostsConfigurationAudit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[TrackingConfigID] [int] NOT NULL,
	[TrackingLocationHostID] [int] NOT NULL,
	[ParentID] [int] NULL,
	[ViewOrder] [int] NULL,
	[NodeName] [nvarchar](200) NOT NULL,
	[UserName] [nvarchar](255) NULL,
	[InsertTime] [datetime] NOT NULL,
	[Action] [char](1) NOT NULL,
 CONSTRAINT [PK_TrackingLocationsHostsConfigurationAudit] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].TrackingLocationsHostsConfigurationAudit 
ADD  CONSTRAINT [DF_TrackingLocationsHostsConfigurationAudit_InsertTime]  DEFAULT (getutcdate()) FOR [InsertTime]
GO
CREATE TABLE [dbo].[TrackingLocationsHostsConfigValuesAudit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[HostConfigID] INT NOT NULL,
	[Value] [nvarchar](250) NOT NULL,
	[LookupID] [int] NOT NULL,
	[TrackingConfigID] [int] NOT NULL,
	[LastUser] [nvarchar](255) NOT NULL,
	[IsAttribute] [bit] NOT NULL,
	[Action] CHAR(1) NOT NULL,
	InsertTime DateTime NOT NULL
 CONSTRAINT [PK_TrackingLocationsHostsConfigValuesAudit] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TrackingLocationsHostsConfigValuesAudit] ADD  CONSTRAINT [DF_TrackingLocationsHostsConfigValuesAudit_InsertTime]  DEFAULT (getutcdate()) FOR [InsertTime]
GO
CREATE TRIGGER [dbo].[TrackingLocationsHostsConfigurationAuditInsertUpdate]
   ON  [dbo].[TrackingLocationsHostsConfiguration]
    after insert, update
AS 
BEGIN
SET NOCOUNT ON;

Declare @action char(1)
DECLARE @count INT

--check if this is an insert or an update

If Exists(Select * From Inserted) and Exists(Select * From Deleted) --Update, both tables referenced
	begin
		Set @action= 'U'
	end
else
begin
	If Exists(Select * From Inserted) --insert, only one table referenced
	Begin
		Set @action= 'I'
	end
	if not Exists(Select * From Inserted) and not Exists(Select * From Deleted)--nothing changed, get out of here
	Begin
		RETURN
	end
end

--Only inserts records into the Audit table if the row was either updated or inserted and values actually changed.
select @count= count(*) from
(
   select TrackingLocationHostID, ParentID, ViewOrder, NodeName from Inserted
   except
   select TrackingLocationHostID, ParentID, ViewOrder, NodeName from Deleted
) a


if ((@count) >0)
begin
	insert into TrackingLocationsHostsConfigurationAudit (TrackingConfigID, TrackingLocationHostID, ParentID, ViewOrder, NodeName, UserName, Action)
	Select ID, TrackingLocationHostID, ParentID, ViewOrder, NodeName, LastUser, @action from inserted
end

END

GO
CREATE TRIGGER [dbo].[TrackingLocationsHostsConfigurationAuditDelete]
   ON  [dbo].[TrackingLocationsHostsConfiguration]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into TrackingLocationsHostsConfigurationaudit (TrackingConfigID, TrackingLocationHostID, ParentID, ViewOrder, NodeName, UserName, Action)
Select ID, TrackingLocationHostID, ParentID, ViewOrder, NodeName, LastUser, 'D' from deleted

END

GO
CREATE TRIGGER [dbo].[TrackingLocationsHostsConfigValuesAuditDelete]
   ON  [dbo].[TrackingLocationsHostsConfigValues]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into TrackingLocationsHostsConfigValuesAudit (HostConfigID, Value, LookupID, TrackingConfigID, LastUser, IsAttribute, Action)
Select ID, Value, LookupID, TrackingConfigID, LastUser, IsAttribute, 'D' from deleted

END
GO
CREATE TRIGGER [dbo].[TrackingLocationsHostsConfigValuesAuditInsertUpdate]
   ON  [dbo].[TrackingLocationsHostsConfigValues]
    after insert, update
AS 
BEGIN
SET NOCOUNT ON;

Declare @action char(1)
DECLARE @count INT

--check if this is an insert or an update

If Exists(Select * From Inserted) and Exists(Select * From Deleted) --Update, both tables referenced
	begin
		Set @action= 'U'
	end
else
begin
	If Exists(Select * From Inserted) --insert, only one table referenced
	Begin
		Set @action= 'I'
	end
	if not Exists(Select * From Inserted) and not Exists(Select * From Deleted)--nothing changed, get out of here
	Begin
		RETURN
	end
end

--Only inserts records into the Audit table if the row was either updated or inserted and values actually changed.
select @count= count(*) from
(
   select Value, LookupID, TrackingConfigID, IsAttribute from Inserted
   except
   select Value, LookupID, TrackingConfigID, IsAttribute from Deleted
) a

if ((@count) >0)
begin
	insert into TrackingLocationsHostsConfigValuesAudit (HostConfigID, Value, LookupID, TrackingConfigID, LastUser, IsAttribute, Action)
	select ID, Value, LookupID, TrackingConfigID, LastUser, IsAttribute, @action from inserted
end

END
GO
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