ALTER PROCEDURE RemispGetTestCountByType @StartDate DateTime = NULL, @EndDate DateTime = NULL, @ReportBasedOn INT = NULL, @GeoLocationID INT, @ByPassProductCheck INT, @UserID INT
AS
BEGIN
	If (@StartDate IS NULL)
	BEGIN
		SET @StartDate = GETDATE()
	END
	
	IF (@ReportBasedOn IS NULL)
	BEGIN
		SET @ReportBasedOn = 1
	END

	DECLARE @TrueBit BIT
	SET @TrueBit = CONVERT(BIT, 1)

	SELECT '# Completed Testing' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM TrackingLocations tl WITH(NOLOCK)
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus = 8 and ba.inserttime between @startdate and @enddate
		INNER JOIN BatchesAudit ba2 WITH(NOLOCK) ON b.ID = ba2.BatchID AND ba2.BatchStatus <> 8 and ba2.inserttime between @startdate and @enddate
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName
	ORDER BY tl.TrackingLocationName, tr.TestName

	SELECT '# in Chamber' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM TrackingLocations tl WITH(NOLOCK)
		INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tl.TrackingLocationTypeID = tlt.ID AND tlt.TrackingLocationFunction = 4
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName

	SELECT '# Units in FA' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM (
			SELECT tra.TestRecordId 
			FROM TestRecordsaudit tra WITH(NOLOCK)
			WHERE tra.Action IN ('I','U') AND tra.Status IN (3, 4) and tra.InsertTime BETWEEN @startdate AND @enddate--FQRaised and FARequired
			GROUP BY TestRecordId
			) as xer 
		INNER JOIN TestRecords tr WITH(NOLOCK) ON xer.TestRecordID = tr.ID  
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON dtl.ID = trtl.TrackingLogID
		INNER JOIN TrackingLocations tl WITH(NOLOCK) ON tl.ID = dtl.TrackingLocationID
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
		INNER JOIN Batches b ON tu.BatchID = b.ID
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName

	SELECT '# Worked On Parametric' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM TrackingLocations tl WITH(NOLOCK)
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
		INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = @TrueBit
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName

	SELECT '# Completed Parametric' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM TrackingLocations tl WITH(NOLOCK)
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
		INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = @TrueBit
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName

	SELECT '# Worked On Drop' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM TrackingLocations tl WITH(NOLOCK)
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
		INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit AND j.JobName LIKE '%Drop%'
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName

	SELECT '# Worked On Tumble' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM TrackingLocations tl WITH(NOLOCK)
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
		INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit AND j.JobName LIKE '%Tumble%'
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName

	SELECT '# Completed Drop' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM TrackingLocations tl WITH(NOLOCK)
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
		INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit AND j.JobName LIKE '%Drop%'
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName

	SELECT '# Completed Tumble' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM TrackingLocations tl WITH(NOLOCK)
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
		INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit AND j.JobName LIKE '%Tumble%'
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName

	SELECT '# Worked On Accessories' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM TrackingLocations tl WITH(NOLOCK)
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
		INNER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=b.ProductTypeID
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate AND l.[Values] = 'Accessory'
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName

	SELECT '# Worked On Component' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM TrackingLocations tl WITH(NOLOCK)
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
		INNER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=b.ProductTypeID
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate AND l.[Values] = 'Component'
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName

	SELECT '# Worked On Handheld' As Item, tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
	FROM Batches b
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
		INNER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=b.ProductTypeID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID=tu.BatchID
		INNER JOIN TestRecords tr WITH(NOLOCK) ON tr.TestUnitID=tu.ID
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
		INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TestRecordID=tr.ID
		INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
		INNER JOIN TrackingLocations tl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
		LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
	WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
		AND dtl.InTime BETWEEN @StartDate AND @EndDate AND l.[Values] = 'Handheld'
		AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ProductID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY tl.TrackingLocationName, tr.TestName
END
GO
GRANT EXECUTE ON RemispGetTestCountByType TO REMI
GO