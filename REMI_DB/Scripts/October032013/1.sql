/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        CI0000001593275.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 9/27/2013 3:25:40 PM

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
PRINT N'Altering [dbo].[remispEnvironmentalReport]'
GO
ALTER procedure [dbo].[remispEnvironmentalReport]
	@startDate datetime,
	@enddate datetime,
	@reportBasedOn int = 1,
	@testLocationID INT,
	@ByPassProductCheck INT,
	@UserID INT, @NewWay BIT = 0
AS
SET NOCOUNT ON
DECLARE @TrueBit BIT
SET @TrueBit = CONVERT(BIT, 1)

If (@NewWay <> 0)
BEGIN
	IF @testLocationID IS NULL
	BEGIN
		SET @testLocationID = 0
	END

	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	DECLARE @sql2 VARCHAR(8000)
	DECLARE @sql3 VARCHAR(8000)

	SELECT @rows=  ISNULL(STUFF((
		SELECT DISTINCT '],[' + p.ProductGroupName
		FROM Batches b WITH(NOLOCK)
			INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
			INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID and ba.inserttime between @startdate and @enddate
		WHERE (b.TestCenterLocationID = @testLocationID or @testLocationID = 0) 
			AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
		ORDER BY '],[' +  p.ProductGroupName
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

	SET @sql = 'SELECT '' '' AS '' '', *, SUM(ISNULL(' + REPLACE(@rows, ',',', 0) + ISNULL(') + ',0)) As Total 
	FROM (
		SELECT ''# Completed Testing'' As Item, (CASE WHEN ' + CONVERT(VARCHAR, @reportBasedOn) + '=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS num, p.ProductGroupName 
		FROM Batches b WITH(NOLOCK)
			INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
			INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus = 8 and ba.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			INNER JOIN BatchesAudit ba2 WITH(NOLOCK) ON b.ID = ba2.BatchID AND ba2.BatchStatus <> 8 and ba2.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		WHERE (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY p.productgroupname
		UNION
		SELECT ''# in Chamber'' As Item, (CASE WHEN ' + CONVERT(VARCHAR, @reportBasedOn) + '=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS num, p.productgroupname 
		FROM DeviceTrackingLog dtl WITH(NOLOCK)
			INNER JOIN TestUnits tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID
			INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
			INNER JOIN TrackingLocations tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.id
			INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tl.TrackingLocationTypeID = tlt.ID AND tlt.TrackingLocationFunction = 4 --4 means chamber type device (environmentstressing)
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		WHERE dtl.InTime BETWEEN ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			AND (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY p.productgroupname
		UNION
		SELECT ''# Units in FA'' As Item, COUNT(tr.ID) as num, p.productgroupname 
		FROM (
				SELECT tra.TestRecordId 
				FROM TestRecordsaudit tra WITH(NOLOCK)
				WHERE tra.Action IN (''I'',''U'') AND tra.Status IN (3, 4) and tra.InsertTime BETWEEN ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''--FQRaised and FARequired
				GROUP BY TestRecordId
			) as xer
			INNER JOIN TestRecords tr WITH(NOLOCK) ON tr.ID= xer.TestRecordId
			INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
			INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		WHERE (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY ProductGroupName
		UNION
		SELECT ''# Worked On Parametric'' As Item, (CASE WHEN ' + CONVERT(VARCHAR, @reportBasedOn) + '=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS num, p.productgroupname
		FROM Batches b WITH(NOLOCK)
			INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
			INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
			INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
			INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = ' + CONVERT(VARCHAR, @TrueBit) + '
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		WHERE ba.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + ''' 
			and (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY p.productgroupname
		UNION
		SELECT ''# Completed Parametric'' As Item, (CASE WHEN ' + CONVERT(VARCHAR, @reportBasedOn) + '=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS num, p.productgroupname
		FROM Batches b WITH(NOLOCK)
			INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
			INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
			INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
			INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = ' + CONVERT(VARCHAR, @TrueBit) + '
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		WHERE ba.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + ''' 
			AND (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY p.productgroupname
		UNION'
		SET @sql2 = ' SELECT ''# Worked On Drop'' As Item, (CASE WHEN ' + CONVERT(VARCHAR, @reportBasedOn) + '=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS num, p.productgroupname
		FROM Batches b WITH(NOLOCK)
			INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
			INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
			INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = ' + CONVERT(VARCHAR, @TrueBit) + ' AND j.JobName LIKE ''%Drop%''
			INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
			INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		WHERE ba.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			and (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY p.productgroupname
		UNION
		SELECT ''# Worked On Tumble'' As Item, (CASE WHEN ' + CONVERT(VARCHAR, @reportBasedOn) + '=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS num, p.productgroupname
		FROM Batches b WITH(NOLOCK)
			INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
			INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
			INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = ' + CONVERT(VARCHAR, @TrueBit) + ' AND j.JobName LIKE ''%Tumble%''
			INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
			INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		WHERE ba.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			and (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY p.productgroupname
		UNION
		SELECT ''# Completed Drop'' As Item, (CASE WHEN ' + CONVERT(VARCHAR, @reportBasedOn) + '=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS num, p.productgroupname
		FROM Batches b WITH(NOLOCK)
			INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
			INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
			INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = ' + CONVERT(VARCHAR, @TrueBit) + ' AND j.JobName LIKE ''%Drop%''
			INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
			INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		WHERE ba.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			and (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY p.productgroupname
		UNION
		SELECT ''# Completed Tumble'' As Item, (CASE WHEN ' + CONVERT(VARCHAR, @reportBasedOn) + '=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS num, p.productgroupname
		FROM Batches b WITH(NOLOCK)
			INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
			INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
			INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = ' + CONVERT(VARCHAR, @TrueBit) + ' AND j.JobName LIKE ''%Tumble%''
			INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
			INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		WHERE ba.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			and (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY p.productgroupname
		UNION
		SELECT ''# Worked On Accessories'' As Item, (CASE WHEN ' + CONVERT(VARCHAR, @reportBasedOn) + '=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS num, p.productgroupname
		FROM Batches b WITH(NOLOCK)
			INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
			INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
			INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
			INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
			INNER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID = l.LookupID AND l.Type=''ProductType''
		WHERE ba.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + ''' AND l.[Values] = ''Accessory''
			and (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY p.productgroupname
		UNION'
		SET @sql3 = ' SELECT ''# Worked On Component'' As Item, (CASE WHEN ' + CONVERT(VARCHAR, @reportBasedOn) + '=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS num, p.productgroupname
		FROM Batches b WITH(NOLOCK)
			INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
			INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
			INNER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID = l.LookupID AND l.Type=''ProductType''
		WHERE ba.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + ''' AND l.[Values] = ''Component''
			and (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY p.productgroupname
		UNION
		SELECT ''# Worked On Handheld'' As Item, (CASE WHEN ' + CONVERT(VARCHAR, @reportBasedOn) + '=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS num, p.productgroupname
		FROM Batches b WITH(NOLOCK)
			INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
			INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
			INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
			INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + '''
			INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
			INNER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID = l.LookupID AND l.Type=''ProductType''
		WHERE ba.inserttime between ''' + CONVERT(VARCHAR, @startdate) + ''' and ''' + CONVERT(VARCHAR, @enddate) + ''' AND l.[Values] = ''Handheld''
			and (b.TestCenterLocationID = ' + CONVERT(VARCHAR, @testLocationID) + ' or ' + CONVERT(VARCHAR, @testLocationID) + ' = 0) 
			AND (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 1 OR (' + CONVERT(VARCHAR, @ByPassProductCheck) + ' = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=' + CONVERT(VARCHAR, @UserID) + ')))
		GROUP BY p.productgroupname
	) p PIVOT (MAX(num) FOR ProductGroupName IN (' + @rows + ')) AS pvt GROUP BY Item, ' + @rows + ' ORDER BY Item '

	EXEC (@sql + @sql2 + @sql3)
END
ELSE
BEGIN
	IF @testLocationID = 0
	BEGIN
		SET @testLocationID = NULL
	END

	SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Completed Testing], p.ProductGroupName 
	FROM Batches b WITH(NOLOCK)
		INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus = 8 and ba.inserttime between @startdate and @enddate
		INNER JOIN BatchesAudit ba2 WITH(NOLOCK) ON b.ID = ba2.BatchID AND ba2.BatchStatus <> 8 and ba2.inserttime between @startdate and @enddate
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
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
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
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
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
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
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
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
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
	WHERE ba.inserttime between @startdate and @enddate and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY p.productgroupname
	ORDER BY p.productgroupname

	SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Drop], p.productgroupname
	FROM Batches b WITH(NOLOCK)
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
		INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
		INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit AND j.JobName LIKE '%Drop%'
		INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
	WHERE ba.inserttime between @startdate and @enddate
		and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY p.productgroupname
	ORDER BY p.productgroupname

	SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Tumble], p.productgroupname
	FROM Batches b WITH(NOLOCK)
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
		INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
		INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit AND j.JobName LIKE '%Tumble%'
		INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
	WHERE ba.inserttime between @startdate and @enddate
		and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY p.productgroupname
	ORDER BY p.productgroupname

	SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Completed Drop], p.productgroupname
	FROM Batches b WITH(NOLOCK)
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
		INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
		INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit AND j.JobName LIKE '%Drop%'
		INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
	WHERE ba.inserttime between @startdate and @enddate
		and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY p.productgroupname
	ORDER BY p.productgroupname
	
	SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Completed Tumble], p.productgroupname
	FROM Batches b WITH(NOLOCK)
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
		INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
		INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit AND j.JobName LIKE '%Tumble%'
		INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
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
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		INNER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID = l.LookupID AND l.Type='ProductType'
	WHERE ba.inserttime between @startdate and @enddate AND l.[Values] = 'Accessory'
		and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY p.productgroupname
	ORDER BY p.productgroupname

	SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Component], p.productgroupname
	FROM Batches b WITH(NOLOCK)
		INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
		INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		INNER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID = l.LookupID AND l.Type='ProductType'
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
		INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
		INNER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID = l.LookupID AND l.Type='ProductType'
	WHERE ba.inserttime between @startdate and @enddate	AND l.[Values] = 'Handheld'
		and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
		AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	GROUP BY p.productgroupname
	ORDER BY p.productgroupname
END

SET NOCOUNT OFF
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[RemispGetTestCountByType]'
GO
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
COMMIT TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO