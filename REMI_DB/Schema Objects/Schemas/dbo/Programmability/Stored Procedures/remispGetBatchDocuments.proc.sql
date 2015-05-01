ALTER PROCEDURE [dbo].remispGetBatchDocuments @QRANumber nvarchar(11)
AS
BEGIN
	DECLARE @JobName NVARCHAR(400)
	DECLARE @LookupID INT
	DECLARE @ID INT
	SELECT @JobName = JobName, @LookupID = p.LookupID, @ID = b.ID 
	FROM Batches b WITH(NOLOCK)
		INNER JOIN Lookups p WITH(NOLOCK) ON p.LookupID=b.ProductID
	WHERE QRANumber=@QRANumber

	CREATE TABLE #view (QRANumber NVARCHAR(11), expectedDuration REAL, processorder INT, resultbasedontime INT, TestName NVARCHAR(400) COLLATE SQL_Latin1_General_CP1_CI_AS, testtype INT, teststagetype INT, TestStageName NVARCHAR(400), testunitsfortest NVARCHAR(MAX), TestID INT, TestStageID INT, IsArchived BIT, TestIsArchived BIT, TestWI NVARCHAR(400) COLLATE SQL_Latin1_General_CP1_CI_AS, TestCounts NVARCHAR(MAX))

	insert into #view (QRANumber, expectedDuration, processorder, resultbasedontime, TestName, testtype, teststagetype, TestStageName, testunitsfortest, TestID, TestStageID, IsArchived, TestIsArchived, TestWI, TestCounts)
	exec remispBatchGetTaskInfo @BatchID=@ID

	SELECT (j.JobName + ' WI') AS WIType, j.WILocation AS Location
	FROM Jobs j WITH(NOLOCK)
	WHERE j.JobName=@JobName AND LTRIM(RTRIM(ISNULL(j.WILocation, ''))) <> ''
	UNION
	SELECT DISTINCT TestName AS WIType, TestWI AS Location
	FROM #view WITH(NOLOCK)
	WHERE QRANumber=@QRANumber and processorder > 0 AND testtype IN (1,2) AND LTRIM(RTRIM(ISNULL(TestWI,''))) <> ''
	UNION
	SELECT (j.JobName + ' Procedure') AS WIType, j.ProcedureLocation AS Location
	FROM Jobs j WITH(NOLOCK)
	WHERE j.JobName=@JobName AND LTRIM(RTRIM(ISNULL(j.ProcedureLocation, ''))) <> ''
	UNION
	SELECT 'Specification' AS WIType, 'http://hwqaweb.rim.net/pls/trs/data_entry.main?req=QRA-ENG-SP-11-0001' AS Location
	UNION
	SELECT 'QAP' As WIType, l.Description AS Location
	FROM Lookups l WITH(NOLOCK)
	WHERE l.LookupID=@LookupID AND LTRIM(RTRIM(ISNULL(l.Description, ''))) <> ''

	DROP TABLE #view
END
GO
GRANT EXECUTE ON remispGetBatchDocuments TO REMI
GO