ALTER PROCEDURE dbo.remispKPIReports @StartDate DATETIME, @EndDate DATETIME, @Type INT, @TestCenterID INT
AS
BEGIN
	DECLARE @BID INT
	CREATE TABLE #batches (ID INT IDENTITY(1,1), BatchID INT, QRANumber NVARCHAR(11), JobName NVARCHAR(250))

	SET NOCOUNT ON

	--Get batches modified during the start and end date
	INSERT INTO #batches (BatchID, QRANumber, JobName)
	SELECT b.ID, b.QRANumber, b.JobName
	FROM Batches b
	WHERE b.ID IN (SELECT BatchID FROM BatchesAudit ba WHERE ba.InsertTime BETWEEN @StartDate AND @EndDate)
		AND b.TestCenterLocationID=@TestCenterID
	ORDER BY b.QRANumber DESC

	SELECT @BID = MIN(ID) FROM #batches

	IF (@Type = 1)
	BEGIN
		CREATE TABLE #result (BatchUnitNumber INT, DiffMinutes REAL, InIncoming DATETIME, FirstOutOfIncoming DATETIME, QRANumber NVARCHAR(11))
		
		SELECT ID
		INTO #incomingMachines
		FROM TrackingLocations 
		WHERE (TrackingLocationName like '%incom%' or TrackingLocationName like '%rems%') and TestCenterLocationID=@TestCenterID and ISNULL(Decommissioned, 0) = 0

		WHILE (@BID IS NOT NULL)
		BEGIN
			INSERT INTO #result
			SELECT tu.BatchUnitNumber, dbo.GetDateDiffInMinutes((SELECT DATEADD(HH,-5, MIN(dtl.InTime)) FROM DeviceTrackingLog dtl WHERE dtl.TestUnitID=tu.ID AND OutTime IS NOT NULL AND TrackingLocationID IN (SELECT ID FROM #incomingMachines)),
					(SELECT DATEADD(HH,-5, MIN(dtl.InTime)) FROM DeviceTrackingLog dtl WHERE dtl.TestUnitID=tu.ID AND TrackingLocationID NOT IN (SELECT ID FROM #incomingMachines))) As DiffMinutes,
				(SELECT DATEADD(HH,-5, MIN(dtl.InTime)) FROM DeviceTrackingLog dtl WHERE dtl.TestUnitID=tu.ID AND OutTime IS NOT NULL AND TrackingLocationID IN (SELECT ID FROM #incomingMachines)) As InIncoming,
				(SELECT DATEADD(HH,-5, MIN(dtl.InTime)) FROM DeviceTrackingLog dtl WHERE dtl.TestUnitID=tu.ID AND TrackingLocationID NOT IN (SELECT ID FROM #incomingMachines)) As FirstOutOfIncoming,
				(SELECT QRANumber FROM #batches WHERE ID=@BID) AS QRANumber
			FROM TestUnits tu
			WHERE tu.BatchID = (SELECT BatchID FROM #batches WHERE ID=@BID)

			SELECT @BID = MIN(ID) FROM #batches WHERE ID > @BID
		END

		SELECT b.QRANumber, b.JobName, ROUND(((SELECT SUM(DiffMinutes) FROM #result r WHERE r.QRANumber= b.QRANumber) / (SELECT COUNT(ID) FROM TestUnits WHERE BatchID=b.BatchID)), 2) AS LostMinutes
		FROM #batches b
		
		DROP TABLE #result
		DROP TABLE #incomingMachines
	END
	
	DROP TABLE #batches
END
GO
GRANT EXECUTE ON dbo.remispKPIReports TO REMI
GO