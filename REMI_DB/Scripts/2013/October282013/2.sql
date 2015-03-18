BEGIN TRAN

SELECT ID
INTO #IDs
from vw_ExceptionsPivoted
where TestUnitID IS NULL AND ProductID IS NULL

INSERT INTO TestExceptions (ID, LookupID, Value, LastUser, OldID, InsertTime)
SELECT ID, 3516 AS LookupID,76 AS Value, 'ogaudreault' AS LastUser, NULL AS OldID, GETDATE() AS InserTime
FROM #IDs

SELECT ID, LookupID, Value, LastUser, OldID, InsertTime
INTO #newExceptions
from TestExceptions
WHERE ID IN (SELECT ID FROM #IDs)

DECLARE @LoopValue INT
DECLARE @MaxID INT
DECLARE select_cursor CURSOR FOR SELECT DISTINCT ID FROM #newExceptions
OPEN select_cursor

FETCH NEXT FROM select_cursor INTO @LoopValue

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @MaxID = MAX(ID)+1 FROM TestExceptions
	
	INSERT INTO TestExceptions (ID, LookupID, Value, LastUser, OldID, InsertTime)
	SELECT @MaxID, LookupID, CASE WHEN LookupID=3516 THEN 77 ELSE Value END, LastUser, OldID, InsertTime from #newExceptions WHERE ID=@LoopValue
	
	SET @MaxID = @MaxID + 1
	
	INSERT INTO TestExceptions (ID, LookupID, Value, LastUser, OldID, InsertTime)
	SELECT @MaxID, LookupID, CASE WHEN LookupID=3516 THEN 122 ELSE Value END, LastUser, OldID, InsertTime from #newExceptions WHERE ID=@LoopValue
	
	SET @MaxID = @MaxID + 1
	
	INSERT INTO TestExceptions (ID, LookupID, Value, LastUser, OldID, InsertTime)
	SELECT @MaxID, LookupID, CASE WHEN LookupID=3516 THEN 123 ELSE Value END, LastUser, OldID, InsertTime from #newExceptions WHERE ID=@LoopValue
	
	SET @MaxID = @MaxID + 1
	
	INSERT INTO TestExceptions (ID, LookupID, Value, LastUser, OldID, InsertTime)
	SELECT @MaxID, LookupID, CASE WHEN LookupID=3516 THEN 78 ELSE Value END, LastUser, OldID, InsertTime from #newExceptions WHERE ID=@LoopValue
	
	FETCH NEXT FROM select_cursor INTO @LoopValue
END

CLOSE select_cursor
DEALLOCATE select_cursor

DROP TABLE #IDs
DROP TABLE #newExceptions

ROLLBACK TRAN