ALTER procedure [dbo].[remispTestExceptionsCopyExceptionsForProduct] 
	@oldProductID nvarchar(400),
	@newProductID nvarchar(400),
	@username nvarchar(255)
AS
DECLARE @MAX INT
DECLARE @LookupID INT
SELECT @MAX = MAX(ID) FROM TestExceptions

SELECT @LookupID = LookupID FROM Lookups WHERE Type='Exceptions' AND [Values]='ProductID'

SELECT pvt.ID, ROW_NUMBER() OVER( ORDER BY ID )  + @MAX AS NEW_ID
INTO #temp
FROM vw_ExceptionsPivoted as pvt 
WHERE ProductID=@oldProductID AND TestUnitID IS NULL

INSERT INTO TestExceptions (ID, LookupID, Value, LastUser)
SELECT NEW_ID as ID, LookupID, 
CASE WHEN LookupID=@LookupID THEN @newProductID ELSE Value END, @username
FROM TestExceptions te
	INNER JOIN #temp on te.ID=#temp.ID

DROP TABLE #temp
GO
GRANT EXECUTE On remispTestExceptionsCopyExceptionsForProduct TO Remi
GO