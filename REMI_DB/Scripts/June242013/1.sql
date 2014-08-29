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
PRINT N'Altering [dbo].[remispCopyTestConfiguration]'
GO
ALTER PROCEDURE [dbo].[remispCopyTestConfiguration] @ProductID INT, @TestID INT, @copyFromProductID INT, @LastUser NVARCHAR(255)
AS
BEGIN
	BEGIN TRANSACTION
	
	BEGIN TRY
		DECLARE @FromCount INT
		DECLARE @ToCount INT
		DECLARE @max INT
		SET @max = (SELECT MAX(ID) +1 FROM ProductConfiguration)
		
		SELECT @FromCount = COUNT(*) FROM ProductConfiguration WHERE TestID=@TestID AND ProductID=@copyFromProductID
		
		SELECT tempID=IDENTITY (int, 1, 1), CONVERT(int,ID) As ID, ParentId, ViewOrder, NodeName, @TestID AS TestID, @ProductID AS ProductID, @LastUser AS LastUser, 0 AS newproID, NULL AS newParentID
		INTO #ProductConfiguration
		FROM ProductConfiguration
		WHERE TestID=@TestID AND ProductID=@copyFromProductID
		
		IF ((SELECT COUNT(*) FROM #ProductConfiguration) > 0)
		BEGIN
			UPDATE #ProductConfiguration SET newproID=@max+tempid
			
			UPDATE #ProductConfiguration 
			SET #ProductConfiguration.newParentID = pc2.newproID
			FROM #ProductConfiguration
				LEFT OUTER JOIN #ProductConfiguration pc2 ON #ProductConfiguration.ParentID=pc2.ID
				
			SET Identity_Insert ProductConfiguration ON
			
			INSERT INTO ProductConfiguration (ID, ParentId, ViewOrder, NodeName, TestID, ProductID, LastUser)
			SELECT newproID, newParentId, ViewOrder, NodeName, TestID, ProductID, LastUser
			FROM #ProductConfiguration
			
			SET Identity_Insert ProductConfiguration OFF
			
			SELECT @ToCount = COUNT(*) FROM ProductConfiguration WHERE TestID=@TestID AND ProductID=@ProductID

			IF (@FromCount = @ToCount)
			BEGIN
				SELECT @FromCount = COUNT(*) FROM ProductConfiguration pc INNER JOIN ProductConfigValues pcv ON pc.ID=pcv.ProductConfigID WHERE TestID=@TestID AND ProductID=@copyFromProductID
			
				INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
				SELECT Value, LookupID, #ProductConfiguration.newproID AS ProductConfigID, @LastUser AS LastUser, IsAttribute
				FROM ProductConfigValues
					INNER JOIN ProductConfiguration ON ProductConfigValues.ProductConfigID=ProductConfiguration.ID
					INNER JOIN #ProductConfiguration ON ProductConfiguration.ID=#ProductConfiguration.ID	
					
				SELECT @ToCount = COUNT(*) FROM ProductConfiguration pc INNER JOIN ProductConfigValues pcv ON pc.ID=pcv.ProductConfigID WHERE TestID=@TestID AND ProductID=@ProductID
				
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
		END
		ELSE
		BEGIN
			GOTO HANDLE_SUCESS
		END
	END TRY
	BEGIN CATCH
		  SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_SEVERITY() AS ErrorSeverity, ERROR_STATE() as ErrorState, ERROR_PROCEDURE() as ErrorProcedure, ERROR_LINE() as ErrorLine, ERROR_MESSAGE() as ErrorMessage

		  GOTO HANDLE_ERROR
	END CATCH
	
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
PRINT N'Altering [Relab].[ResultsParametersComma]'
GO
ALTER FUNCTION Relab.ResultsParametersComma(@ResultMeasurementID INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @listStr NVARCHAR(MAX)
	SELECT @listStr = COALESCE(@listStr+', ' ,'') + ParameterName + ': ' + Value
	FROM Relab.ResultsParameters
	WHERE Relab.ResultsParameters.ResultMeasurementID=@ResultMeasurementID
	ORDER BY Relab.ResultsParameters.ID ASC
	
	Return @listStr
END
GO
GRANT EXECUTE ON Relab.ResultsParametersComma TO Remi
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispResultMeasurements]'
GO
ALTER PROCEDURE [Relab].[remispResultMeasurements] @ResultID INT, @OnlyFails INT = 0
AS
BEGIN
	SET NOCOUNT ON
	SELECT rm.ID, lt.[Values] As MeasurementType, LowerLimit, UpperLimit, MeasurementValue, lu.[Values] As UnitType, 
		CASE WHEN PassFail=1 THEN 'Pass' ELSE 'Fail' END AS PassFail,
		Relab.ResultsParametersComma(rm.ID) AS [Parameters], rm.MeasurementTypeID
	FROM Relab.ResultsMeasurements rm
		LEFT OUTER JOIN Lookups lu ON lu.Type='UnitType' AND lu.LookupID=rm.MeasurementUnitTypeID
		LEFT OUTER JOIN Lookups lt ON lt.Type='MeasurementType' AND lt.LookupID=rm.MeasurementTypeID
	WHERE ResultID=@ResultID AND ((@OnlyFails = 1 AND PassFail=0) OR (@OnlyFails = 0))
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispResultMeasurements] TO Remi
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
ALTER PROCEDURE Relab.remispResultsGraph @MeasurementTypeID INT, @BatchID INT, @StageIDs NVARCHAR(MAX), @UnitIDs NVARCHAR(MAX), @VerNum INT, @Parameters NVARCHAR(MAX) = null, @ShowUpperLowerLimits INT = 1
AS
BEGIN
	DECLARE @TestStageID INT
	CREATE TABLE #stages (id INT)
	CREATE TABLE #units (id INT)
	CREATE TABLE #parameters (ParameterName NVARCHAR(255), ParameterValue NVARCHAR(500))
	EXEC (@StageIDs)
	EXEC (@UnitIDs)
	EXEC (@Parameters)		

	SELECT @TestStageID = MIN(id) FROM #stages
	
	WHILE @TestStageID IS NOT NULL
	BEGIN
		PRINT @TestStageID
		
		SELECT DISTINCT rm.ID, rm.MeasurementValue AS MeasurementValue, tu.BatchUnitNumber, ts.TestStageName, rm.UpperLimit AS UpperLimit, rm.LowerLimit AS LowerLimit
			,(SELECT COUNT(*) FROM Relab.ResultsParameters pp WHERE pp.Value=#parameters.ParameterValue AND pp.ResultMeasurementID=rm.ID) AS Missing
		into #Graph
		FROM Relab.Results r
			INNER JOIN TestUnits tu ON r.TestUnitID=tu.ID
			INNER JOIN Relab.ResultsMeasurements rm ON r.ID=rm.ResultID
			INNER JOIN TestStages ts ON r.TestStageID=ts.ID
			LEFT OUTER JOIN Relab.ResultsParameters rp ON rm.ID=rp.ResultMeasurementID 
			LEFT OUTER JOIN #parameters on rp.ParameterName=#parameters.ParameterName
		WHERE tu.BatchID=@BatchID AND r.TestStageID = @TestStageID AND MeasurementTypeID=@MeasurementTypeID AND tu.BatchUnitNumber IN (SELECT id FROM #units) AND r.VerNum=@VerNum
		
		UPDATE #Graph SET MeasurementValue=1 WHERE MeasurementValue IN ('True','Pass')
		UPDATE #Graph SET MeasurementValue=0 WHERE MeasurementValue IN ('Fail','False')		
		
		IF ((SELECT COUNT(*) FROM #parameters) > 0)
		BEGIN
			delete from #Graph WHERE ID IN (SELECT ID FROM #Graph WHERE Missing=0)
		END
		
		SELECT ROUND(MeasurementValue, 3) AS MeasurementValue, BatchUnitNumber, TestStageName 
		FROM #Graph 
		WHERE MeasurementValue IS NOT NULL AND ISNUMERIC(MeasurementValue)=1
		ORDER BY BatchUnitNumber

		IF (@ShowUpperLowerLimits = 1)
		BEGIN
			SELECT ROUND(Lowerlimit, 3) AS MeasurementValue, BatchUnitNumber, (TestStageName + ' Lower Specification Limit') AS TestStageName 
			FROM #Graph
			WHERE LowerLimit IS NOT NULL AND ISNUMERIC(LowerLimit)=1
			ORDER BY BatchUnitNumber
			
			SELECT ROUND(UpperLimit, 3) AS MeasurementValue, BatchUnitNumber, (TestStageName + ' Upper Specification Limit') AS TestStageName 
			FROM #Graph 
			WHERE UpperLimit IS NOT NULL AND ISNUMERIC(UpperLimit)=1
			ORDER BY BatchUnitNumber
		END

		DROP TABLE #Graph
			
		SELECT @TestStageID = MIN(id) FROM #stages WHERE id > @TestStageID
	END

	DROP TABLE #stages
	DROP TABLE #units
	DROP TABLE #parameters
END
GO
GRANT EXECUTE ON Relab.remispResultsGraph TO REMI
GO


IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Relab].[remispGetUnitsByTestStageMeasurement]'
GO
CREATE PROCEDURE Relab.remispGetUnitsByTestStageMeasurement @StageIDs NVARCHAR(MAX), @MeasurementTypeID INT, @BatchID INT, @VerNum INT
AS
BEGIN
	CREATE Table #temp(id int) 
	EXEC(@StageIDs)
	DECLARE @Count INT
	
	SELECT @Count = COUNT(*) FROM #temp
	
	SELECT tu.BatchUnitNumber
	FROM TestUnits tu
		INNER JOIN Relab.Results r ON r.TestUnitID=tu.ID
		INNER JOIN #temp ON #temp.id=r.TestStageID
		INNER JOIN Relab.ResultsMeasurements m on m.ResultID=r.ID AND m.MeasurementTypeID=@MeasurementTypeID
	WHERE BatchID=@BatchID AND r.VerNum=@VerNum
	GROUP BY tu.BatchUnitNumber
	HAVING COUNT(DISTINCT r.TestStageID) >= @Count	
	 
	DROP TABLE #temp
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Relab].[remispGetMeasurementsByTestStage]'
GO
CREATE PROCEDURE Relab.remispGetMeasurementsByTestStage @StageIDs NVARCHAR(MAX), @BatchID INT, @VerNum INT
AS
BEGIN
	CREATE Table #temp(id int) 
	EXEC(@StageIDs)
	DECLARE @Count INT
	
	SELECT @Count = COUNT(*) FROM #temp
	
	SELECT DISTINCT m.MeasurementTypeID, Lookups.[Values] As Measurement
	FROM TestUnits tu
		INNER JOIN Relab.Results r ON r.TestUnitID=tu.ID
		INNER JOIN #temp ON #temp.id=r.TestStageID
		INNER JOIN Relab.ResultsMeasurements m on m.ResultID=r.ID 
		INNER JOIN Lookups ON m.MeasurementTypeID=Lookups.LookupID
	WHERE BatchID=@BatchID AND r.VerNum=@VerNum
	GROUP BY m.MeasurementTypeID, Lookups.[Values]
	HAVING COUNT(DISTINCT r.TestStageID) >=@Count
	
	DROP TABLE #temp
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [Relab].[remispResultsGraph]'
GO
GRANT EXECUTE ON  [Relab].[remispResultsGraph] TO [remi]
GO
PRINT N'Altering permissions on [Relab].[remispGetUnitsByTestStageMeasurement]'
GO
GRANT EXECUTE ON  [Relab].[remispGetUnitsByTestStageMeasurement] TO [remi]
GO
PRINT N'Altering permissions on [Relab].[remispGetMeasurementsByTestStage]'
GO
GRANT EXECUTE ON  [Relab].[remispGetMeasurementsByTestStage] TO [remi]
GO
alter table TrackingLocations Add IsMultiDeviceZone BIT DEFAULT(0) NOT NULL
GO
ALTER TABLE TrackingLocations ADD PluginName NVARCHAR(250)
GO
alter table TrackingLocationsAudit Add IsMultiDeviceZone BIT NULL
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
	ISNULL(tl.Decommissioned, 0) AS Decommissioned, ISNULL(tl.IsMultiDeviceZone, 0) AS IsMultiDeviceZone, PluginName As PluginName
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
GRANT EXECUTE ON remispTrackingLocationsSearchFor TO Remi
GO
ALTER PROCEDURE [dbo].[remispTrackingLocationsInsertUpdateSingleItem]
/*	'===============================================================
	'   NAME:                	remispTrackingLocationsInsertUpdateSingleItem
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates or updates an item in a table: TrackingLocations
	'   IN:        ID, TrackingLocationName, UnitCapacity, TrackingLocationType, GeoLocationId,  InsertUser, UpdateUser, Visible      
	'   OUT: 		ID, ConcurrencyID         
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
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
	@PluginName NVARCHAR(250)
	AS

	DECLARE @ReturnValue int
	declare @AlreadyExists as integer 
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

		INSERT INTO TrackingLocations (TrackingLocationName, TestCenterLocationID, TrackingLocationTypeID, LastUser, Comment, Decommissioned, IsMultiDeviceZone, PluginName)
		VALUES (@TrackingLocationname, @GeoLocationID, @TrackingLocationtypeID, @LastUser, @Comment, @Decommissioned, @IsMultiDeviceZone, @PluginName)
			
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
			PluginName = @PluginName
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
GRANT EXECUTE ON remispTrackingLocationsInsertUpdateSingleItem TO Remi
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[TrackingLocationsAuditDelete]
   ON  dbo.TrackingLocations
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into TrackingLocationsaudit (
	TrackingLocationId, 
	TrackingLocationName, 
	TrackingLocationTypeID,
	TestCenterLocationID, 
	--Status,
	Comment,
	--HostName,
	Username,
	Action, IsMultiDeviceZone)
	Select 
	Id, 
	TrackingLocationName, 
	TrackingLocationTypeID,
	TestCenterLocationID, 
	--Status,
	Comment,
	--HostName,
	lastuser,
'D', IsMultiDeviceZone from deleted

END
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[TrackingLocationsAuditInsertUpdate]
   ON  dbo.TrackingLocations
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
   select TrackingLocationName, TrackingLocationTypeID, TestCenterLocationID, Comment, IsMultiDeviceZone from Inserted
   except
   select TrackingLocationName, TrackingLocationTypeID, TestCenterLocationID, Comment, IsMultiDeviceZone from Deleted
) a

if ((@count) >0)
begin
	insert into TrackingLocationsaudit (
		TrackingLocationId, 
		TrackingLocationName, 
		TrackingLocationTypeID,
		TestCenterLocationID, 
		--Status,
		Comment,
		--HostName,
		Username,
		Action, IsMultiDeviceZone)
		Select 
		Id, 
		TrackingLocationName, 
		TrackingLocationTypeID,
		TestCenterLocationID, 
		--Status,
		Comment,
		--HostName,
		lastuser,
	@action, IsMultiDeviceZone from inserted
END
END
GO
ALTER PROCEDURE [dbo].[remispTestUnitsAvailable] @QRANumber NVARCHAR(11)
AS
BEGIN
	SELECT tu.BatchUnitNumber
	FROM Batches b
		INNER JOIN TestUnits tu ON b.ID=tu.BatchID
	WHERE QRANumber=@QRANumber
		AND tu.ID NOT IN (SELECT dtl.TestUnitID
					FROM DeviceTrackingLog dtl
						INNER JOIN TrackingLocations tl ON dtl.TrackingLocationID=tl.ID AND tl.ID NOT IN (25,81)
					WHERE TestUnitID = 214734 AND OutTime IS NULL)
END
GO
GRANT EXECUTE ON remispTestUnitsAvailable TO REMI
GO
ALTER PROCEDURE [Relab].[remispOverallResultsSummary] @BatchID INT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @OverAllID INT
	DECLARE @TestStageID INT
	DECLARE @TestID INT
	DECLARE @TestUnitID INT
	DECLARE @VerNum INT
	DECLARE @ResultID INT
	CREATE TABLE #failures (MeasurementType NVARCHAR(MAX), Parameter NVARCHAR(MAX), resultid int, vernum int)
	CREATE TABLE #success (MeasurementType NVARCHAR(MAX), Parameter NVARCHAR(MAX), resultid int, vernum int)

	SELECT DISTINCT j.JobName, ts.TestStageName, t.TestName, tu.BatchUnitNumber, (CASE WHEN (SELECT COUNT(*) FROM Relab.Results r2 where r2.TestID=r.TestID and r2.TestStageID=r.TestStageID and r.TestUnitID=r2.TestUnitID )=1 THEN r.PassFail ELSE -1 END ) AS PassFail, 
	r.TestID, r.TestStageID, r.TestUnitID, 0 AS ResultID
	INTO #Overall
	FROM Relab.Results r
		INNER JOIN TestStages ts ON r.TestStageID=ts.ID
		INNER JOIN Tests t ON r.TestID=t.ID
		INNER JOIN TestUnits tu ON tu.ID=r.TestUnitID
		INNER JOIN Jobs j ON j.ID=ts.JobID
	WHERE tu.BatchID=@BatchID

	ALTER TABLE #Overall ADD ID INT IDENTITY(1,1)

	SELECT @OverAllID = MIN(ID) FROM #Overall

	WHILE (@OverAllID IS NOT NULL)
	BEGIN
		SELECT @TestID=TestID, @TestStageID=TestStageID, @TestUnitID=TestUnitID FROM #Overall WHERE ID = @OverAllID
		TRUNCATE TABLE #success
		TRUNCATE TABLE #failures

		SELECT r.ID AS ResultID, r.VerNum
		INTO #Versions
		FROM Relab.Results r
			INNER JOIN TestUnits tu ON tu.ID=r.TestUnitID
		WHERE tu.BatchID=@BatchID AND TestID=@TestID AND TestStageID=@TestStageID AND TestUnitID=@TestUnitID
		
		SELECT @VerNum = MIN(VerNum) FROM #Versions
		
		WHILE @VerNum IS NOT NULL
		BEGIN
			SELECT @ResultID=ResultID FROM #Versions WHERE VerNum = @VerNum
			PRINT @ResultID
			
			IF ((SELECT COUNT(*) FROM Relab.ResultsMeasurements rm WHERE rm.PassFail=0 AND rm.ResultID=@ResultID) > 0)
			BEGIN
				INSERT INTO #failures (MeasurementType, Parameter, resultid, vernum)
				SELECT l.[Values] As MeasurementType, Relab.ResultsParametersComma(Relab.ResultsMeasurements.ID) As Parameter, @ResultID AS Result, @VerNum
				FROM Relab.ResultsMeasurements
					INNER JOIN Lookups l ON l.LookupID=Relab.ResultsMeasurements.MeasurementTypeID
				WHERE ResultID=@ResultID AND PassFail=0
				ORDER BY l.[Values]
			END

			INSERT INTO #success (MeasurementType, Parameter, resultid, vernum)
			SELECT l.[Values] As MeasurementType, Relab.ResultsParametersComma(Relab.ResultsMeasurements.ID) As Parameter, Relab.ResultsMeasurements.ResultID, r.VerNum
			FROM Relab.ResultsMeasurements
				INNER JOIN Lookups l ON l.LookupID=Relab.ResultsMeasurements.MeasurementTypeID
				INNER JOIN #failures f ON l.[Values]=f.MeasurementType AND Relab.ResultsParametersComma(Relab.ResultsMeasurements.ID)=f.Parameter
				INNER JOIN Relab.Results r ON r.ID=Relab.ResultsMeasurements.ResultID
			WHERE Relab.ResultsMeasurements.ResultID=@ResultID AND Relab.ResultsMeasurements.PassFail=1
			ORDER BY l.[Values]
			
			SELECT @VerNum = MIN(VerNum) FROM #Versions WHERE VerNum > @VerNum
		END
		
		IF ((SELECT COUNT(*) FROM #failures) > (SELECT COUNT(*) FROM #success))
		BEGIN
			UPDATE #Overall SET PassFail=0, ResultID = (SELECT ResultID FROM #Versions WHERE VerNum = (SELECT MAX(VerNum) FROM #Versions)) WHERE ID = @OverAllID
		END
		ELSE IF ((SELECT COUNT(*) FROM #failures) = (SELECT COUNT(*) FROM #success))
		BEGIN
			SELECT #failures.MeasurementType, #failures.Parameter, MAX(#failures.VerNum) AS FailureVerNum, MAX(#success.VerNum) AS SuccessVerNum
			INTO #result
			FROM #failures
				LEFT OUTER JOIN #success ON #failures.MeasurementType=#success.MeasurementType AND #failures.Parameter=#success.Parameter
			GROUP BY #failures.MeasurementType, #failures.Parameter
			
			UPDATE #Overall
			SET PassFail = (CASE WHEN ISNULL((SELECT COUNT(*)
				FROM #result
				WHERE SuccessVerNum IS NULL OR SuccessVerNum < FailureVerNum),0) = 0 THEN 1 ELSE 0 END),
				ResultID = (SELECT ResultID FROM #Versions WHERE VerNum = (SELECT MAX(VerNum) FROM #Versions))
			WHERE ID=@OverAllID
			
			DROP TABLE #result		
		END
		
		DROP TABLE #Versions

		SELECT @OverAllID = MIN(ID) FROM #Overall WHERE ID > @OverAllID
	END

	SELECT JobName, TestStageName, TestName, BatchUnitNumber, (CASE WHEN PassFail = 0 THEN 'Fail' ELSE 'Pass' END) AS PassFail, ResultID FROM #Overall

	DROP TABLE #Overall
	DROP TABLE #failures
	DROP TABLE #success

	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispOverallResultsSummary] TO Remi
GO
DROP FUNCTION  Relab.DetermineOverallPassFail
GO
ALTER PROCEDURE [dbo].[remispDeleteProductConfiguration] @ProductID INT, @TestID INT, @LastUser NVARCHAR(255)
AS
BEGIN
	UPDATE ProductConfigValues 
	SET LastUser=@LastUser
	WHERE ProductConfigID IN (SELECT ID FROM ProductConfiguration WHERE TestID=@TestID AND ProductID=@ProductID)
	
	UPDATE ProductConfiguration 
	SET LastUser=@LastUser
	WHERE TestID=@TestID AND ProductID=@ProductID
	
	DELETE FROM ProductConfigValues WHERE ProductConfigID IN (SELECT ID FROM ProductConfiguration WHERE TestID=@TestID AND ProductID=@ProductID)
	DELETE FROM ProductConfiguration WHERE TestID=@TestID AND ProductID=@ProductID
	
	DELETE FROM ProductConfigurationUpload WHERE TestID=@TestID AND ProductID=@ProductID
END
GO
GRANT EXECUTE ON remispDeleteProductConfiguration TO REMI
GO
ALTER PROCEDURE Relab.remispResultsFileProcessing
AS
BEGIN
	BEGIN TRANSACTION

	BEGIN TRY
		DECLARE @ID INT
		DECLARE @idoc INT
		DECLARE @RowID INT
		DECLARE @xml XML
		DECLARE @xmlPart XML
		DECLARE @FinalResult BIT
		DECLARE @EndDate NVARCHAR(MAX)
		DECLARE @Duration NVARCHAR(MAX)

		IF ((SELECT COUNT(*) FROM Relab.Results WHERE ISNULL(IsProcessed,0)=0)=0)
			RETURN

		SELECT TOP 1 @ID=ID, @xml = ResultsXML
		FROM Relab.Results
		WHERE ISNULL(IsProcessed,0)=0

		SELECT @xmlPart = T.c.query('.') 
		FROM @xml.nodes('/TestResults/Header') T(c)

		exec sp_xml_preparedocument @idoc OUTPUT, @xmlPart

		SELECT * 
		INTO #temp
		FROM OPENXML(@idoc, '/')

		PRINT 'Insert Header values'
		INSERT INTO Relab.ResultsHeader (ResultID, Name, Value)
		SELECT @ID As ResultID, LocalName AS Name,(SELECT t2.text FROM #temp t2 WHERE t2.ParentID=t.ID) AS Value
		FROM #temp t
		WHERE t.NodeType=1 AND t.ParentID IS NOT NULL AND t.LocalName NOT IN ('FinalResult','DateCompleted')
			AND LTRIM(RTRIM(CONVERT(NVARCHAR(1500), (SELECT t2.text FROM #temp t2 WHERE t2.ParentID=t.ID)))) <> ''

		select @FinalResult = (CASE WHEN T.c.query('FinalResult').value('.', 'nvarchar(max)') = 'Pass' THEN 1 ELSE 0 END),
			@EndDate = T.c.query('DateCompleted').value('.', 'nvarchar(max)'),
			@Duration = T.c.query('Duration').value('.', 'nvarchar(max)')
		FROM @xmlPart.nodes('/Header') T(c)

		SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ' ')
		SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ':')
		SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ':')

		PRINT 'Get Measurements'
		SELECT  ROW_NUMBER() OVER (ORDER BY T.c) AS RowID, T.c.query('.') AS value 
		INTO #temp2
		FROM   @xml.nodes('/TestResults/Measurements/Measurement') T(c)

		SELECT @RowID = MIN(RowID) FROM #temp2

		WHILE (@RowID IS NOT NULL)
		BEGIN
			SELECT @xmlPart  = value FROM #temp2 WHERE RowID=@RowID	

			select T.c.query('MeasurementName').value('.', 'nvarchar(max)') AS MeasurementType,
				T.c.query('LowerLimit').value('.', 'nvarchar(max)') AS LowerLimit,
				T.c.query('UpperLimit').value('.', 'nvarchar(max)') AS UpperLimit,
				T.c.query('MeasuredValue').value('.', 'nvarchar(max)') AS MeasurementValue,
				(CASE WHEN T.c.query('PassFail').value('.', 'nvarchar(max)') = 'Pass' THEN 1 ELSE 0 END) AS PassFail,
				T.c.query('Units').value('.', 'nvarchar(max)') AS UnitType,
				T.c.query('FileName').value('.', 'nvarchar(max)') AS [FileName]
			INTO #measurement
			FROM @xmlPart.nodes('/Measurement') T(c)
		
			PRINT 'INSERT Lookups UnitType'
			INSERT INTO Lookups (LookupID, Type,[Values], IsActive)
			SELECT DISTINCT (SELECT MAX(LookupID)+1 FROM Lookups) AS LookupID, 'UnitType' AS Type, LTRIM(RTRIM(UnitType)) AS [values], 1
			FROM #measurement 
			WHERE LTRIM(RTRIM(UnitType)) NOT IN (SELECT [Values] FROM Lookups WHERE Type='UnitType') AND UnitType IS NOT NULL AND UnitType NOT IN ('N/A')
		
			PRINT 'INSERT Lookups MeasurementType'
			INSERT INTO Lookups (LookupID, Type,[Values], IsActive)
			SELECT DISTINCT (SELECT MAX(LookupID)+1 FROM Lookups) AS LookupID, 'MeasurementType' AS Type, LTRIM(RTRIM(MeasurementType)) AS [values], 1
			FROM #measurement 
			WHERE LTRIM(RTRIM(MeasurementType)) NOT IN (SELECT [Values] FROM Lookups WHERE Type='MeasurementType') AND MeasurementType IS NOT NULL AND MeasurementType NOT IN ('N/A')
		
			PRINT 'INSERT Measurements'
			INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, [File], PassFail)
			SELECT @ID As ResultID, l2.LookupID AS MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, l.[LookupID] AS MeasurementUnitTypeID, FileName AS [File], CONVERT(BIT, PassFail)
			FROM #measurement
				LEFT OUTER JOIN Lookups l ON l.Type='UnitType' AND l.[Values]=LTRIM(RTRIM(#measurement.UnitType))
				LEFT OUTER JOIN Lookups l2 ON l2.Type='MeasurementType' AND l2.[Values]=LTRIM(RTRIM(#measurement.MeasurementType))
		
			DECLARE @ResultMeasurementID INT
			SELECT @ResultMeasurementID = MAX(ID)
			FROM Relab.ResultsMeasurements
			WHERE ResultID=@ID 
			
			PRINT 'INSERT Parameters'
			INSERT INTO Relab.ResultsParameters (ResultMeasurementID, ParameterName, Value)
			SELECT @ResultMeasurementID AS ResultMeasurementID, T.c.value('@ParameterName','nvarchar(max)') AS ParameterName, T.c.query('.').value('.', 'nvarchar(max)') AS Value
			FROM @xmlPart.nodes('/Measurement/Parameters/Parameter') T(c)
		
			DROP TABLE #measurement
		
			SELECT @RowID = MIN(RowID) FROM #temp2 WHERE RowID > @RowID
		END
		
		If (CHARINDEX('.', @Duration) > 0)
			SET @Duration = SUBSTRING(@Duration, 1, CHARINDEX('.', @Duration)-1)

		PRINT 'Update Result'
		UPDATE Relab.Results 
		SET PassFail=@FinalResult, EndDate=CONVERT(DATETIME, @EndDate), 
			StartDate =dateadd(s,datediff(s,0,convert(DATETIME,@Duration)), CONVERT(DATETIME, @EndDate)),  
			IsProcessed=1 
		WHERE ID=@ID
	
		DROP TABLE #temp
		DROP TABLE #temp2

		PRINT 'COMMIT TRANSACTION'
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		  SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_SEVERITY() AS ErrorSeverity, ERROR_STATE() as ErrorState, ERROR_PROCEDURE() as ErrorProcedure, ERROR_LINE() as ErrorLine, ERROR_MESSAGE() as ErrorMessage

		  PRINT 'ROLLBACK TRANSACTION'
		  ROLLBACK TRANSACTION
	END CATCH
END
GO
GRANT EXECUTE ON Relab.remispResultsFileProcessing TO REMI
GO
ALTER procedure [dbo].[remispUsersSearch] @ProductID INT = 0, @TestCenterID INT = 0, @TrainingID INT = 0, @TrainingLevelID INT = 0, @ByPass INT = 0
AS
BEGIN
	SELECT DISTINCT u.ID, u.LDAPLogin
	FROM Users u
		LEFT OUTER JOIN UserTraining ut ON ut.UserID = u.ID
		LEFT OUTER JOIN UsersProducts up ON up.UserID = u.ID
	WHERE u.IsActive=1 AND (
			(u.TestCentreID=@TestCenterID) 
			OR
			(@TestCenterID = 0)
		  )
		  AND
		  (
			(ut.LookupID=@TrainingID) 
			OR
			(@TrainingID = 0)
		  )
		  AND
		  (
			(ut.LevelLookupID=@TrainingLevelID) 
			OR
			(@TrainingLevelID = 0)
		  )
		  AND
		  (
			(u.ByPassProduct=@ByPass) 
			OR
			(@ByPass = 0)
		  )
		  AND
		  (
			(up.ProductID=@ProductID) 
			OR
			(@ProductID = 0)
		  )
	ORDER BY u.LDAPLogin
END
GO
GRANT EXECUTE ON remispUsersSearch TO REMI
GO
create PROCEDURE [dbo].[remispDeleteStationConfiguration] @HostID INT, @LastUser NVARCHAR(255)
AS
BEGIN
	UPDATE TrackingLocationsHostsConfigValues
	SET LastUser=@LastUser
	WHERE TrackingConfigID IN (SELECT ID FROM TrackingLocationsHostsConfiguration WHERE TrackingLocationHostID=@HostID)
	
	UPDATE TrackingLocationsHostsConfiguration 
	SET LastUser=@LastUser
	WHERE TrackingLocationHostID=@HostID
	
	DELETE FROM TrackingLocationsHostsConfigValues WHERE TrackingConfigID IN (SELECT ID FROM TrackingLocationsHostsConfiguration WHERE TrackingLocationHostID=@HostID)
	DELETE FROM TrackingLocationsHostsConfiguration WHERE TrackingLocationHostID=@HostID
	
	DELETE FROM StationConfigurationUpload WHERE TrackingLocationHostID=@HostID
END
GO
GRANT EXECUTE ON [dbo].[remispDeleteStationConfiguration] TO REMI
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectHeldBatches]
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@TestCentreLocation INT =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc',
	@ByPassProductCheck INT = 0,
	@UserID int
	AS
		SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
				 BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,
				 BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName,batchesrows.ProductType, batchesrows.AccessoryGroupName,batchesrows.productID,
				 batchesrows.RFBands, batchesrows.TestStageCompletionStatus, testunitcount,
		(CASE WHEN batchesrows.WILocation IS NULL THEN NULL ELSE batchesrows.WILocation END) AS jobWILocation,			
		(testunitcount -
		(select COUNT(*) 
		from TestUnits as tu
		INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
		where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
		) as HasUnitsToReturnToRequestor,
		(select AssignedTo 
		from TaskAssignments as ta
			--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
			INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
			--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
			INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
		where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions,
		BatchesRows.ProductTypeID, batchesrows.AccessoryGroupID,BatchesRows.RQID As ReqID, batchesrows.TestCenterLocationID
	FROM (SELECT ROW_NUMBER() OVER (ORDER BY 
case when @sortExpression='qra' and @direction='asc' then qranumber end,
case when @sortExpression='qra' and @direction='desc' then qranumber end desc,
case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
case when @sortExpression='job' and @direction='asc' then jobname end,
case when @sortExpression='job' and @direction='desc' then jobname end desc,
case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
case when @sortExpression='priority' and @direction='asc' then Priority end asc,
case when @sortExpression='priority' and @direction='desc' then Priority end desc,
case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
case when @sortExpression is null then Priority end desc
		) AS Row, 
		           ID, 
                      QRANumber, 
                      Comment,
                      RequestPurpose, 
                      Priority,
                      TestStageName, 
                      BatchStatus, 
                      ProductGroupName, 
					  ProductType,
					  AccessoryGroupName,
					  ProductTypeID,
					  AccessoryGroupID,
					  productID,
                      JobName, 
                      TestCenterLocation,
					  TestCenterLocationID,
                      LastUser, 
                      ConcurrencyID,
                      b.RFBands,
                      b.TestStageCompletionStatus ,
                      (select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
                      b.WILocation,b.RQID
                      from
(SELECT DISTINCT 
                      b.ID, 
                      b.QRANumber, 
                      b.Comment,
                      b.RequestPurpose, 
                      b.Priority,
                      b.TestStageName, 
                      b.BatchStatus, 
                      p.ProductGroupName,
					  b.ProductTypeID, 
					  b.AccessoryGroupID,
					  l.[Values] As ProductType,
					  l2.[Values] As AccessoryGroupName,
					  l3.[Values] As TestCenterLocation,
					  p.ID As productID,
                      b.JobName, 
                      b.LastUser, 
                      b.TestCenterLocationID,
                      b.ConcurrencyID,
                      (case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
                      b.TestStageCompletionStatus,
                      j.WILocation,b.RQID                     
FROM Batches AS b
	 inner join Products p on b.ProductID=p.id
	 LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName
	 LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=b.ProductTypeID
	 LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND l2.LookupID=b.AccessoryGroupID
	 LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  
WHERE (b.TestCenterLocationID = @TestCentreLocation or @TestCentreLocation is null) and (b.BatchStatus = 1 or b.BatchStatus = 3) 
AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
)as b) as batchesrows
 	WHERE
	 ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1) order by QRANumber desc
GO
GRANT EXECUTE ON remispBatchesSelectHeldBatches TO Remi
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectBatchesForReport]
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@TestCentreLocation INT =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc',
	@ByPassProductCheck INT = 0,
	@UserID int
AS
SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
	BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,
	batchesrows.ProductID,batchesrows.QRANumber,batchesrows.RQID As ReqID,
	BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName, 
	batchesrows.RFBands, batchesrows.TestStageCompletionStatus, testunitcount,
	(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,
	(
		testunitcount -
		(select COUNT(*) 
		from TestUnits as tu
			INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
		where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
	) as HasUnitsToReturnToRequestor,
	(select AssignedTo 
	from TaskAssignments as ta
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
	where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions,
	batchesrows.ProductType, batchesrows.AccessoryGroupName, batchesrows.TestCenterLocationID
	FROM     
		(
			SELECT ROW_NUMBER() OVER 
			(
				ORDER BY 
					case when @sortExpression='qra' and @direction='asc' then qranumber end,
					case when @sortExpression='qra' and @direction='desc' then qranumber end desc,
					case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
					case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
					case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
					case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
					case when @sortExpression='job' and @direction='asc' then jobname end,
					case when @sortExpression='job' and @direction='desc' then jobname end desc,
					case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
					case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
					case when @sortExpression='priority' and @direction='asc' then Priority end asc,
					case when @sortExpression='priority' and @direction='desc' then Priority end desc,
					case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
					case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
					case when @sortExpression is null then Priority end desc		
			) AS Row, 
			ID, 
			QRANumber, 
			Comment,
			RequestPurpose, 
			Priority,
			TestStageName, 
			BatchStatus, 
			ProductGroupName, 
			productType,
			AccessoryGroupName,
			productTypeID,
			AccessoryGroupID,
			ProductID,
			JobName, 
			TestCenterLocationID,
			TestCenterLocation,
			LastUser, 
			ConcurrencyID,
			b.RFBands,
			b.TestStageCompletionStatus ,
			b.WILocation,
			(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
			b.RQID
			FROM
				(
					SELECT DISTINCT b.ID, 
						b.QRANumber, 
						b.Comment,
						b.RequestPurpose, 
						b.Priority,
						b.TestStageName, 
						b.BatchStatus, 
						p.ProductGroupName, 
						b.ProductTypeID,
						b.AccessoryGroupID,
						l.[Values] As ProductType,
						l2.[Values] As AccessoryGroupName,
						l3.[Values] As TestCenterLocation,
						p.ID As ProductID,
						b.JobName, 
						b.LastUser, 
						b.TestCenterLocationID,
						b.ConcurrencyID,
						(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
						b.TestStageCompletionStatus,
						j.WILocation,
						b.rqID
					FROM Batches AS b
						inner join Products p on p.ID=b.ProductID
						LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName
						LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
						LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
						LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  
						INNER JOIN TestStages ts ON ts.TestStageName=b.TestStageName
					WHERE (b.TestCenterLocationID = @TestCentreLocation or @TestCentreLocation is null) and (b.BatchStatus != 5)
						AND ts.TestStageType=4	
						AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
					-- and (b.TestStageName = 'Report')
				)as b
		) as batchesrows
 	WHERE (
 			(Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1
		  )
	order by QRANumber desc
GO
GRANT EXECUTE ON remispBatchesSelectBatchesForReport TO Remi
GO
ALTER PROCEDURE [dbo].[remispBatchesSearch]
	@ByPassProductCheck INT = 0,
	@ExecutingUserID int,
	@Status int = null,
	@Priority int = null,
	@UserID int = null,
	@TrackingLocationID int = null,
	@TestStageID int = null,
	@TestID int = null,
	@ProductTypeID int = null,
	@ProductID int = null,
	@AccessoryGroupID int = null,
	@GeoLocationID INT = null,
	@JobName nvarchar(400) = null,
	@RequestReason int = null,
	@StartRowIndex int = null,
	@MaximumRows int = null,
	@BatchStart DateTime = NULL,
	@BatchEnd DateTime = NULL
AS
	DECLARE @TestName NVARCHAR(400)
	DECLARE @TestStageName NVARCHAR(400)
	
	SELECT @TestName = TestName FROM Tests WHERE ID=@TestID 
	SELECT @TestStageName = TestStageName FROM TestStages WHERE ID=@TestStageID 
		
	SELECT TOP 100 BatchesRows.row,BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroup As ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName,batchesrows.ProductID, BatchesRows.QRANumber,BatchesRows.RequestPurpose,
		BatchesRows.TestCenterLocationID,BatchesRows.TestStageName,BatchesRows.RFBands, BatchesRows.TestStageCompletionStatus, testUnitCount, 
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation, batchesrows.RQID AS ReqID,
		(testunitcount -
			(select COUNT(*) 
			from TestUnits as tu
			INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
		) as HasUnitsToReturnToRequestor,
		(select AssignedTo 
		from TaskAssignments as ta
			--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
			INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
			--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
			INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
		where ta.BatchID = BatchesRows.ID and ta.Active=1) as ActiveTaskAssignee,
		CONVERT(BIT,0) AS HasBatchSpecificExceptions, batchesrows.ProductTypeID,batchesrows.AccessoryGroupID, BatchesRows.CurrentTest, BatchesRows.CPRNumber, BatchesRows.RelabJobID, BatchesRows.TestCenterLocation
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
				b.BatchStatus,b.Comment,(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
				b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority,b.ProductTypeID,b.AccessoryGroupID,p.ID As ProductID,
				p.ProductGroupName As ProductGroup,b.QRANumber,b.RequestPurpose,b.TestCenterLocationID,b.TestStageName,j.WILocation,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, l3.[Values] As TestCenterLocation,
				(
					SELECT top(1) tu.CurrentTestName as CurrentTestName 
					FROM TestUnits AS tu, DeviceTrackingLog AS dtl 
					where tu.ID = dtl.TestUnitID 
					and tu.CurrentTestName is not null
					and (dtl.OutUser IS NULL) AND tu.BatchID=b.ID
				) As CurrentTest, b.CPRNumber,b.RelabJobID, b.RQID
			FROM Batches as b
				inner join Products p on b.ProductID=p.id 
				LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  
			WHERE (BatchStatus = @Status or @Status is null) 
				AND (p.ID = @ProductID OR @ProductID IS NULL)
				AND (b.Priority = @Priority OR @Priority IS NULL)
				AND (b.ProductTypeID = @ProductTypeID OR @ProductTypeID IS NULL)
				AND (b.AccessoryGroupID = @AccessoryGroupID OR @AccessoryGroupID IS NULL)
				AND (b.TestCenterLocationID = @GeoLocationID OR @GeoLocationID IS NULL)
				AND (b.JobName = @JobName OR @JobName IS NULL)
				AND (b.RequestPurpose = @RequestReason OR @RequestReason IS NULL)
				AND (b.TestStageName = @TestStageName OR @TestStageName IS NULL)
				AND
				(
					(
						SELECT top(1) tu.CurrentTestName as CurrentTestName 
						FROM TestUnits AS tu, DeviceTrackingLog AS dtl 
						where tu.ID = dtl.TestUnitID 
						and tu.CurrentTestName is not null
						and (dtl.OutUser IS NULL) AND tu.BatchID=b.ID
					) = @TestName 
					OR 
					@TestName IS NULL
				)
				AND
				(
					(
						SELECT top 1 u.id 
						FROM TestUnits as tu, devicetrackinglog as dtl, TrackingLocations as tl, Users u
						WHERE tl.ID = dtl.TrackingLocationID and tu.id  = dtl.testunitid and tu.batchid = b.id and  inuser = u.LDAPLogin and outuser is null
					) = @UserID
					OR
					@UserID IS NULL
				)
				AND
				(
					@TrackingLocationID IS NULL
					OR
					(					
						select top 1 tu.BatchID
						from TrackingLocations tl
						inner join devicetrackinglog dtl ON tl.ID=dtl.TrackingLocationID
						inner join TestUnits tu on tu.ID=dtl.TestUnitID
						where TrackingLocationTypeID=@TrackingLocationID
					) = b.ID
				)
				AND b.ID IN (Select distinct batchid FROM BatchesAudit WHERE InsertTime BETWEEN @BatchStart AND @BatchEnd)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@ExecutingUserID)))
		)AS BatchesRows		
	WHERE (Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex is null OR @maximumRows is null
	ORDER BY BatchesRows.QRANumber DESC
	RETURN
GO
GRANT EXECUTE ON remispBatchesSearch TO Remi
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectTestingCompleteBatches]
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@TestCentreLocation INT =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'desc',
	@ByPassProductCheck INT = 0,
	@UserID int
AS
IF @TestCentreLocation = 0 
BEGIN
	SET @TestCentreLocation = NULL
END

DECLARE @comments NVARCHAR(max) 
SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
	BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,
	BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName, batchesrows.RFBands, 
	batchesrows.TestStageCompletionStatus,batchesrows.testUnitCount,BatchesRows.ProductType,batchesrows.AccessoryGroupName,BatchesRows.ProductID,
	batchesrows.HasUnitsToReturnToRequestor,
	batchesrows.jobWILocation
	,(select AssignedTo 
	from TaskAssignments as ta
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
	where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee,
	(select  bc.Text + '####' from BatchComments as bc 
	where bc.BatchID = batchesrows.ID and bc.Active = 1 for xml path('')) as BatchCommentsConcat, CONVERT(BIT,0) AS HasBatchSpecificExceptions,
	BatchesRows.ProductTypeID, BatchesRows.AccessoryGroupID,batchesrows.RQID As ReqID, batchesrows.TestCenterLocationID
FROM
	(
		SELECT ROW_NUMBER() OVER 
			(
				ORDER BY 
				case when @sortExpression='qranumber' and @direction='asc' then qranumber end,
				case when @sortExpression='qranumber' and @direction='desc' then qranumber end desc,
				case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
				case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
				case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
				case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
				case when @sortExpression='job' and @direction='asc' then jobname end,
				case when @sortExpression='job' and @direction='desc' then jobname end desc,
				case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
				case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
				case when @sortExpression='priority' and @direction='asc' then Priority end asc,
				case when @sortExpression='priority' and @direction='desc' then Priority end desc,
				case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
				case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
				case when @sortExpression='HasUnitsToReturnToRequestor' and @direction='asc' then HasUnitsToReturnToRequestor end,
				case when @sortExpression='HasUnitsToReturnToRequestor' and @direction='desc' then HasUnitsToReturnToRequestor end desc,
				case when @sortExpression='jobwilocation' and @direction='asc' then jobWILocation end,
				case when @sortExpression='jobwilocation' and @direction='desc' then jobWILocation end desc,
				case when @sortExpression='testunitcount' and @direction='asc' then testUnitCount end,
				case when @sortExpression='testunitcount' and @direction='desc' then testUnitCount end desc,
				case when @sortExpression='comments' and @direction='asc' then comment end,
				case when @sortExpression='comments' and @direction='desc' then comment end desc,
				case when @sortExpression='testcenterlocation' and @direction='asc' then TestCenterLocationID end,
				case when @sortExpression='testcenterlocation' and @direction='desc' then TestCenterLocationID end desc,
				case when @sortExpression is null then qranumber end desc
			) AS Row, 
			ID, 
			QRANumber, 
			Comment,
			RequestPurpose, 
			Priority,
			TestStageName, 
			BatchStatus, 
			ProductGroupName, 
			ProductType,
			AccessoryGroupName,
			ProductTypeID,
			AccessoryGroupID,
			ProductID,
			JobName, 
			TestCenterLocation,
			TestCenterLocationID,
			LastUser, 
			ConcurrencyID,
			b.RFBands,
			b.TestStageCompletionStatus,
			b.testUnitCount,
			b.HasUnitsToReturnToRequestor,
			b.jobWILocation,
			b.RQID
		from
			(
				SELECT DISTINCT 
				b.ID, 
				b.QRANumber, 
				b.Comment,
				b.RequestPurpose, 
				b.Priority,
				b.TestStageName, 
				b.BatchStatus, 
				p.ProductGroupName, 
				p.ID As ProductID,
				b.ProductTypeID,
				b.AccessoryGroupID,
				l.[Values] As ProductType,
				l2.[Values] As AccessoryGroupName,
				l3.[Values] As TestCenterLocation,
				b.JobName, 
				b.LastUser, 
				b.TestCenterLocationID,
				b.ConcurrencyID,
				(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
				b.TestStageCompletionStatus,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				(select Jobs.WILocation from Jobs where Jobs.JobName = b.jobname) as jobWILocation,
				(
					(select COUNT(*) from TestUnits as tu where tu.batchid = b.ID) -
					(
						select COUNT(*) 
						from TestUnits as tu, DeviceTrackingLog as dtl, TrackingLocations as tl 
						where dtl.TrackingLocationID = tl.ID and tu.BatchID = b.ID 
							and tl.ID = 81 and dtl.OutTime IS null and dtl.TestUnitID = tu.ID
					)
				) as HasUnitsToReturnToRequestor,b.RQID
				FROM Batches AS b
					INNER JOIN Products p ON b.ProductID=p.ID
					LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
					LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
					LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  	
				WHERE (b.TestCenterLocationID = @TestCentreLocation or @TestCentreLocation is null) and b.BatchStatus = 8
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			)as b
	) as batchesrows
WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
OR @startRowIndex = -1 OR @maximumRows = -1) order by Row

GO
GRANT EXECUTE ON remispBatchesSelectTestingCompleteBatches TO Remi
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectChamberBatches]
/*	'===============================================================
	'   NAME:                	remispBatchesSelectDailyList
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retreives the batches in chamber
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/

	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@TestCentreLocation Int =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc',
	@ByPassProductCheck INT = 0,
	@UserID int
	AS
SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
	BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName,
	batchesrows.ProductID,batchesrows.QRANumber,
	BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName, 
	batchesrows.RFBands, batchesrows.TestStageCompletionStatus,testunitcount,
	(CASE WHEN batchesrows.WILocation IS NULL THEN NULL ELSE batchesrows.WILocation END) AS jobWILocation,
	(testUnitCount -
		(select COUNT(*) 
			  from TestUnits as tu
			  INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			  where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
	) as HasUnitsToReturnToRequestor,
	(select AssignedTo 
	from TaskAssignments as ta
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
	where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions,
	batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,batchesrows.RQID As ReqID, batchesrows.TestCenterLocationID
	FROM     
	(
		SELECT ROW_NUMBER() OVER 
			(ORDER BY 
				case when @sortExpression='qra' and @direction='asc' then qranumber end,
				case when @sortExpression='qra' and @direction='desc' then qranumber end desc,
				case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
				case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
				case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
				case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
				case when @sortExpression='job' and @direction='asc' then jobname end,
				case when @sortExpression='job' and @direction='desc' then jobname end desc,
				case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
				case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
				case when @sortExpression='priority' and @direction='asc' then Priority end asc,
				case when @sortExpression='priority' and @direction='desc' then Priority end desc,
				case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
				case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
				case when @sortExpression is null then Priority end desc
			) AS Row, 
			ID, 
			QRANumber, 
			Comment,
			RequestPurpose, 
			Priority,
			TestStageName, 
			BatchStatus, 
			ProductGroupName, 
			ProductType,
			AccessoryGroupName,
			ProductTypeID,
			AccessoryGroupID,
			ProductID,
			JobName, 
			TestCenterLocationID,
			TestCenterLocation,
			LastUser, 
			ConcurrencyID,
			b.RFBands,
			b.TestStageCompletionStatus,
			(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
			b.WILocation,b.RQID
		FROM 
		(
			SELECT DISTINCT b.ID, 
				b.QRANumber, 
				b.Comment,
				b.RequestPurpose, 
				b.Priority,
				b.TestStageName, 
				b.BatchStatus, 
				p.ProductGroupName, 
				b.ProductTypeID,
				b.AccessoryGroupID,
				l.[Values] AS ProductType,
				l2.[Values] As AccessoryGroupName,
				p.ID As ProductID,
				b.JobName, 
				b.LastUser, 
				b.TestCenterLocationID,
				l3.[Values] As TestCenterLocation,
				b.ConcurrencyID,
				(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
				b.TestStageCompletionStatus, j.WILocation,b.RQID
			FROM Batches AS b 
				LEFT OUTER JOIN Jobs as j on b.jobname = j.JobName 
				inner join TestStages as ts on j.ID = ts.JobID
				inner join Tests as t on ts.TestID = t.ID
				inner join DeviceTrackingLog AS dtl 
				INNER JOIN TrackingLocations AS tl ON dtl.TrackingLocationID = tl.ID
				INNER JOIN TrackingLocationTypes as tlt on tl.TrackingLocationTypeID = tlt.id 
				inner join TestUnits AS tu ON dtl.TestUnitID = tu.ID on tu.CurrentTestName = t.TestName and b.id = tu.batchid  --batches where there's a tracking log
				INNER JOIN Products p ON b.ProductID=p.id
				LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  
			WHERE (b.TestCenterLocationID = @TestCentreLocation or @TestCentreLocation is null) and j.TechnicalOperationsTest = 1 and j.MechanicalTest=0 and  tlt.TrackingLocationFunction= 4  and t.ResultBasedOntime = 1 AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL
			AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
		)as b
	) as batchesrows
 	WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex = -1 OR @maximumRows = -1) 
GO
GRANT EXECUTE ON remispBatchesSelectChamberBatches TO Remi
GO
ALTER PROCEDURE [dbo].[remispGetProducts] @ByPassProductCheck INT, @UserID INT
AS
BEGIN
	DECLARE @TrueBit BIT
	SET @TrueBit = CONVERT(BIT, 1)

	SELECT ID, ProductGroupName
	FROM Products
	WHERE IsActive = @TrueBit
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND Products.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	ORDER BY ProductGroupname
END
GO
GRANT EXECUTE ON remispGetProducts TO Remi
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectDailyList]
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@RecordCount int = NULL OUTPUT,
	@ProductID INT = null,
	@sortExpression varchar(100) = null,
	@GetBatchesAtEnvStages int = 1,
	@direction varchar(100) = 'desc',
	@TestCenterLocation as Int= null,
	@GetOperationsTests as bit = 0,
	@GetTechnicalOperationsTests as bit = 1,
	@TestStageCompletion as int = null,
	@ByPassProductCheck INT = 0,
	@UserID int
AS


	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (select COUNT(*) from (SELECT distinct b.* FROM Batches as b, TestStages as ts, TestUnits as tu, Jobs as j, Products p where 
			( ts.TestStageName = b.TestStageName) 
			and tu.BatchID = b.id
			and ts.JobID = j.id
			and j.JobName = b.JobName
			and ((j.OperationsTest = @getoperationstests and @GetOperationsTests = 1)
			or (j.TechnicalOperationsTest = @GetTechnicalOperationsTests and @GetTechnicalOperationsTests = 1 ))
			and ((b.batchstatus=2 or b.BatchStatus = 4) and (ts.TestStageType =  @GetBatchesAtEnvStages))
			and (@ProductID is null or p.ID = @ProductID)
			and ((@TestStageCompletion is null or b.TestStageCompletionStatus = @TestStageCompletion)
			or  (@TestStageCompletion = 2 and (b.TestStageCompletionStatus = 2 or b.TestStageCompletionStatus = 3)))
			and (@TestCenterLocation is null or TestCenterLocationID = @TestCenterLocation)
			AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))) as batchcount)
		RETURN
	END
	
	SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
		BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName, BatchesRows.ProductID ,BatchesRows.QRANumber,
		BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName, BatchesRows.RFBands, BatchesRows.TestStageCompletionStatus,
		(select count(*) from testunits where testunits.batchid = BatchesRows.id) as testUnitCount,
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,
		testunitcount,(testunitcount -
						(select COUNT(*) 
						from TestUnits as tu
						INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
						where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
					   ) as HasUnitsToReturnToRequestor,
		(select AssignedTo 
		from TaskAssignments as ta
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName AND BatchesRows.JobID = ts.JobID
		where ta.BatchID = BatchesRows.ID and ta.Active=1) as ActiveTaskAssignee, batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,BatchesRows.RQID As ReqID,
		(
			SELECT TOP 1 CONVERT(BIT, 1) FROM TestExceptions WHERE LookupID=3 AND Value IN (SELECT ID FROM TestUnits WHERE BatchID=BatchesRows.ID)
		) AS HasBatchSpecificExceptions, BatchesRows.TestCenterLocationID
	FROM
		(
			SELECT ROW_NUMBER() OVER 
			(
				ORDER BY 
				case when @sortExpression='qra' and @direction='asc' then qranumber end,
				case when @sortExpression='qra' and @direction='desc' then qranumber end desc,
				case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
				case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
				case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
				case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
				case when @sortExpression='job' and @direction='asc' then jobname end,
				case when @sortExpression='job' and @direction='desc' then jobname end desc,
				case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
				case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
				case when @sortExpression='priority' and @direction='asc' then Priority end asc,
				case when @sortExpression='priority' and @direction='desc' then Priority end desc,
				case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
				case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
				case when @sortExpression='testcenter' and @direction='asc' then TestCenterLocationID end,
				case when @sortExpression='testcenter' and @direction='desc' then TestCenterLocationID end desc,
				case when @sortExpression is null then (cast(priority as varchar(10)) + qranumber) end desc
			) AS Row, 
			b.ID,
			b.QRANumber, 
			b.Priority, 
			b.TestStageName,
			b.BatchStatus, 
			b.ProductGroupName,
			b.ProductTypeID,
			b.AccessoryGroupID,
			b.AccessoryGroupName,
			b.ProductType,
			b.ProductID As ProductID,
			b.Jobname,
			b.LastUser,
			b.ConcurrencyID,
			b.Comment,
			b.TestCenterLocationID,
			b.TestCenterLocation,
			b.RequestPurpose,
			b.WILocation,
			(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = b.ProductGroupName)  end) as rfBands,
			b.TestStageCompletionStatus,
			(select COUNT (*) from TestUnits as tu where tu.id = b.ID) as testunitcount,b.RQID,
			JobID
			FROM
			(
				select distinct b.* ,p.ProductGroupName,j.WILocation, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName,j.ID As JobID, l3.[Values] As TestCenterLocation
				from Batches as b--, TestStages as ts, TestUnits as tu, Jobs j--, Products p
					LEFT OUTER join TestStages ts ON ts.TestStageName = b.TestStageName and ts.TestStageType =  @GetBatchesAtEnvStages
					LEFT OUTER join TestUnits tu ON tu.BatchID = b.ID
					LEFT OUTER JOIN Products p ON p.ID = b.ProductID
					LEFT OUTER join Jobs j ON j.JobName =b.JobName and ts.JobID = j.ID
					LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
					LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID 
				WHERE --(ts.TestStageName = b.TestStageName) and (tu.BatchID = b.ID)	and (j.JobName =b.JobName )
				--and
				(
					(j.OperationsTest = @getoperationstests and @GetOperationsTests = 1)
					or
					(j.TechnicalOperationsTest = @GetTechnicalOperationsTests and @GetTechnicalOperationsTests = 1)
				)
				--and ts.JobID = j.ID
				--modified above to stop recieved batches (status=4) appearing in daily list				
				--and (ts.TestStageType =  @GetBatchesAtEnvStages)
				and (b.batchstatus=2)
				and (@ProductID is null or p.ID = @ProductID)
				and 
				(
					(@TestStageCompletion is null or b.TestStageCompletionStatus = @TestStageCompletion)
					or
					(@TestStageCompletion = 2 and (b.TestStageCompletionStatus = 2 or b.TestStageCompletionStatus = 3))
				)
				and (@TestCenterLocation is null or TestCenterLocationID = @TestCenterLocation)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			) as b
		) AS BatchesRows 
	WHERE
		(
			(Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR 
			@startRowIndex = -1 OR @maximumRows = -1
		) order by row		
GO
GRANT EXECUTE ON remispBatchesSelectDailyList TO Remi
GO
ALTER procedure [dbo].[remispEnvironmentalReport]
	@startDate datetime,
	@enddate datetime,
	@reportBasedOn int = 1,
	@testLocationID INT,
	@ByPassProductCheck INT,
	@UserID INT
AS
SET NOCOUNT ON

IF @testLocationID = 0
BEGIN
	SET @testLocationID = NULL
END

DECLARE @TrueBit BIT
SET @TrueBit = CONVERT(BIT, 1)

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Completed Testing], p.ProductGroupName 
FROM Batches b WITH(NOLOCK)
	INNER JOIN TestUnits tu ON b.ID = tu.BatchID
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus = 8 and ba.inserttime between @startdate and @enddate
	INNER JOIN BatchesAudit ba2 WITH(NOLOCK) ON b.ID = ba2.BatchID AND ba2.BatchStatus <> 8 and ba2.inserttime between @startdate and @enddate
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# in Chamber], p.productgroupname 
FROM DeviceTrackingLog dtl WITH(NOLOCK)
	INNER JOIN TestUnits tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID
	INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
	INNER JOIN TrackingLocations tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.id
	INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tl.TrackingLocationTypeID = tlt.ID AND tlt.TrackingLocationFunction = 4 --4 means chamber type device (environmentstressing)
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE dtl.InTime BETWEEN @startdate AND @enddate
	and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT count(tr.ID) as [# Units in FA], p.productgroupname 
FROM (
		SELECT tra.TestRecordId 
		FROM TestRecordsaudit tra WITH(NOLOCK)
		WHERE tra.Action IN ('I','U') AND tra.Status IN (3, 4) and tra.InsertTime BETWEEN @startdate AND @enddate--FQRaised and FARequired
		GROUP BY TestRecordId
	) as xer
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tr.ID= xer.TestRecordId
	INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE (b.TestCenterLocationID = @testLocationID or @testLocationID is null)
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID))) 
GROUP BY ProductGroupName
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Parametric], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = @TrueBit
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE ba.inserttime between @startdate and @enddate and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Completed Parametric], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = @TrueBit
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE ba.inserttime between @startdate and @enddate and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Drop/Tumble], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE ba.inserttime between @startdate and @enddate
	and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Completed Drop/Tumble], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE ba.inserttime between @startdate and @enddate
	and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Accessories], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Products p ON p.ID=b.ProductID
	INNER JOIN Lookups l ON b.ProductTypeID = l.LookupID AND l.Type='ProductType'
WHERE ba.inserttime between @startdate and @enddate AND l.[Values] = 'Accessory'
	and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Component], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN Products p ON p.ID=b.ProductID
	INNER JOIN Lookups l ON b.ProductTypeID = l.LookupID AND l.Type='ProductType'
WHERE ba.inserttime between @startdate and @enddate AND l.[Values] = 'Component'
	and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Handheld], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Products p ON p.ID=b.ProductID
	INNER JOIN Lookups l ON b.ProductTypeID = l.LookupID AND l.Type='ProductType'
WHERE ba.inserttime between @startdate and @enddate	AND l.[Values] = 'Handheld'
	and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SET NOCOUNT OFF
GO
GRANT EXECUTE ON remispEnvironmentalReport TO Remi
GO
ALTER PROCEDURE RemispGetTestCountByType @StartDate DateTime = NULL, @EndDate DateTime = NULL, @ReportBasedOn INT = NULL, @GeoLocationID INT, @GroupByType INT = 1, @BasedOn NVARCHAR(60), @ByPassProductCheck INT, @UserID INT
AS
BEGIN
	If (@StartDate IS NULL)
	BEGIN
		SET @StartDate = GETDATE()
	END

	IF (@GroupByType IS NULL)
	BEGIN
		SET @GroupByType = 1
	END
	
	IF (@ReportBasedOn IS NULL)
	BEGIN
		SET @ReportBasedOn = 1
	END

	DECLARE @TrueBit BIT
	SET @TrueBit = CONVERT(BIT, 1)

	IF (@BasedOn = '# Completed Testing')
	BEGIN
		WITH data AS 
		(
			SELECT tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
			FROM TrackingLocations tl
				LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus = 8 and ba.inserttime between @startdate and @enddate
				INNER JOIN BatchesAudit ba2 WITH(NOLOCK) ON b.ID = ba2.BatchID AND ba2.BatchStatus <> 8 and ba2.inserttime between @startdate and @enddate
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			GROUP BY tl.TrackingLocationName, tr.TestName
		)
		SELECT *
		FROM data
		ORDER BY TrackingLocationName, TestName
	END
	ELSE IF (@BasedOn = '# in Chamber')
	BEGIN
		WITH data AS 
		(
			SELECT tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
			FROM TrackingLocations tl
				INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tl.TrackingLocationTypeID = tlt.ID AND tlt.TrackingLocationFunction = 4
				LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b ON tu.BatchID = b.ID
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			GROUP BY tl.TrackingLocationName, tr.TestName
		)
		SELECT *
		FROM data
		ORDER BY TrackingLocationName, TestName
	END
	ELSE IF (@BasedOn = '# Units in FA')
	BEGIN
		WITH data AS 
		(
			SELECT tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
			FROM (
					SELECT tra.TestRecordId 
					FROM TestRecordsaudit tra WITH(NOLOCK)
					WHERE tra.Action IN ('I','U') AND tra.Status IN (3, 4) and tra.InsertTime BETWEEN @startdate AND @enddate--FQRaised and FARequired
					GROUP BY TestRecordId
				  ) as xer 
				INNER JOIN TestRecords tr ON xer.TestRecordID = tr.ID  
				INNER JOIN TestUnits tu ON tu.ID = tr.TestUnitID
				INNER JOIN TestRecordsXTrackingLogs trtl ON trtl.TestRecordID = tr.ID
				INNER JOIN DeviceTrackingLog dtl ON dtl.ID = trtl.TrackingLogID
				INNER JOIN TrackingLocations tl ON tl.ID = dtl.TrackingLocationID
				LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
				INNER JOIN Batches b ON tu.BatchID = b.ID
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			GROUP BY tl.TrackingLocationName, tr.TestName
		)
		SELECT *
		FROM data
		ORDER BY TrackingLocationName, TestName
	END
	ELSE IF (@BasedOn = '# Worked On Parametric')
	BEGIN
		WITH data AS 
		(
			SELECT tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
			FROM TrackingLocations tl
				LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
				INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
				INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = @TrueBit
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			GROUP BY tl.TrackingLocationName, tr.TestName
		)
		SELECT *
		FROM data
		ORDER BY TrackingLocationName, TestName
	END
	ELSE IF (@BasedOn = '# Completed Parametric')
	BEGIN
		WITH data AS 
		(
			SELECT tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
			FROM TrackingLocations tl
				LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
				INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
				INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = @TrueBit
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			GROUP BY tl.TrackingLocationName, tr.TestName
		)
		SELECT *
		FROM data
		ORDER BY TrackingLocationName, TestName
	END
	ELSE IF (@BasedOn = '# Worked On Drop/Tumble')
	BEGIN
		WITH data AS 
		(
			SELECT tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
			FROM TrackingLocations tl
				LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
				INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit
				INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			GROUP BY tl.TrackingLocationName, tr.TestName
		)
		SELECT *
		FROM data
		ORDER BY TrackingLocationName, TestName
	END
	ELSE IF (@BasedOn = '# Completed Drop/Tumble')
	BEGIN
		WITH data AS 
		(
			SELECT tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
			FROM TrackingLocations tl
				LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
				INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit
				INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			GROUP BY tl.TrackingLocationName, tr.TestName
		)
		SELECT *
		FROM data
		ORDER BY TrackingLocationName, TestName
	END
	ELSE IF (@BasedOn = '# Worked On Accessories')
	BEGIN
		WITH data AS 
		(
			SELECT tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
			FROM TrackingLocations tl
				LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
				INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
				INNER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=b.ProductTypeID
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate AND l.[Values] = 'Accessory'
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			GROUP BY tl.TrackingLocationName, tr.TestName
		)
		SELECT *
		FROM data
		ORDER BY TrackingLocationName, TestName
	END
	ELSE IF (@BasedOn = '# Worked On Component')
	BEGIN
		WITH data AS 
		(
			SELECT tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
			FROM TrackingLocations tl
				LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
				INNER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=b.ProductTypeID
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate AND l.[Values] = 'Component'
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			GROUP BY tl.TrackingLocationName, tr.TestName
		)
		SELECT *
		FROM data
		ORDER BY TrackingLocationName, TestName
	END
	ELSE IF (@BasedOn = '# Worked On Handheld')
	BEGIN
		WITH data AS 
		(
			SELECT tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
			FROM TrackingLocations tl
				LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
				INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
				INNER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=b.ProductTypeID
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate AND l.[Values] = 'Handheld'
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			GROUP BY tl.TrackingLocationName, tr.TestName
		)
		SELECT *
		FROM data
		ORDER BY TrackingLocationName, TestName
	END
END
GO
GRANT EXECUTE ON RemispGetTestCountByType TO REMI
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
ROLLBACK TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO