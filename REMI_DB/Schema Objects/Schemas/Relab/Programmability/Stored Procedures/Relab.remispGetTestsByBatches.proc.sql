﻿ALTER PROCEDURE Relab.remispGetTestsByBatches @BatchIDs NVARCHAR(MAX)
AS
BEGIN
	DECLARE @batches TABLE(ID INT)
	INSERT INTO @batches SELECT s FROM dbo.Split(',',@BatchIDs)
	DECLARE @Count INT
	
	SELECT @Count = COUNT(*) FROM @batches
	
	SELECT DISTINCT TestID, tname
	FROM dbo.vw_GetTaskInfo i WITH(NOLOCK)
	WHERE i.processorder > -1 AND (i.Testtype=1 or i.TestID=1029) AND i.BatchID IN (SELECT id FROM @batches)
	GROUP BY TestID, tname
	HAVING COUNT(DISTINCT BatchID) >= @Count
	ORDER BY tname
END
GO
GRANT EXECUTE ON Relab.remispGetTestsByBatches TO REMI
GO