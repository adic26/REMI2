ALTER procedure remispTestExceptionsCopyExceptions 
	@oldTeststageID int,
	@newTeststageID int,
	@username nvarchar(255)
AS
DECLARE @MAX INT
SELECT @MAX = MAX(ID) FROM TestExceptions

SELECT pvt.ID, ROW_NUMBER() OVER( ORDER BY ID )  + @MAX AS NEW_ID
INTO #temp
FROM vw_ExceptionsPivoted pvt
WHERE TestStageID=@oldTeststageID AND TestUnitID IS NULL

INSERT INTO TestExceptions (ID, LookupID, Value, LastUser)
SELECT NEW_ID as ID, LookupID, 
CASE WHEN LookupID=4 THEN @newTeststageID ELSE Value END, @username
FROM TestExceptions te
INNER JOIN #temp on te.ID=#temp.ID

DROP TABLE #temp