ALTER PROCEDURE [dbo].[remispTestExceptionsDeleteTestUnitException]
	@QRANumber nvarchar(11),
	@BatchUnitNumber int,
	@TestName nvarchar(400) = null,
	@TestStageName nvarchar(400) = null,
	@LastUser nvarchar(255),
	@TestUnitID INT = NULL,
	@TestStageID INT = NULL
AS
BEGIN
	DECLARE @TestID INT
	DECLARE @txID int
	
	If (@TestName = '')
		SET @TestName = NULL
	
	IF (@TestUnitID IS NULL)
		SET @TestUnitID = (SELECT ID FROM TestUnits WHERE BatchID = (SELECT ID FROM Batches WHERE QRANumber = @QRAnumber) and BatchUnitNumber = @BatchUnitNumber)
	
	if (@teststageid is null and @TestStageName is not null)
	begin
		SET @TestStageID = (SELECT ts.ID 
						FROM TestStages ts
							INNER JOIN Jobs j ON j.ID = ts.JobID
							INNER JOIN Batches b ON b.JobName = j.JobName
							INNER JOIN TestUnits tu ON tu.BatchID = b.ID
						WHERE tu.ID=@TestUnitID AND ts.TestStageName = @TestStageName)
	END
	
	select * from vw_ExceptionsPivoted where ID=1060448 
	print @teststageid
	
	IF (@TestName IS NOT NULL AND (SELECT COUNT(*) FROM Tests WHERE TestName=@TestName) = 1)
	BEGIN
		SET @TestID = (SELECT ID FROM Tests WHERE TestName=@TestName)

		SET @txID = (SELECT ID 
				FROM vw_ExceptionsPivoted 
				WHERE TestUnitID = @TestUnitID 
					AND 
					(
						(@TestID IS NOT NULL AND Test = @TestID)
						OR
						(
							@TestID IS NULL AND Test IS NULL
						)
					)
					AND 
					(
						TestStageID = @TestStageID 
						OR
						(
							@TestStageId IS NULL AND TestStageID IS NULL
						)
					)
				)
		
		--set the deleting user
		UPDATE TestExceptions SET LastUser = @LastUser WHERE TestExceptions.ID = @txid
		
		--finally delete the item
		DELETE FROM TestExceptions WHERE TestExceptions.ID = @txid
	END
	ELSE IF (@TestName IS NOT NULL AND (SELECT COUNT(*) FROM Tests WHERE TestName=@TestName) > 1)
	BEGIN
		SELECT ID
		INTO #temp
		FROM vw_ExceptionsPivoted 
		WHERE TestUnitID = @TestUnitID 
			AND 
			(
				Test IN (SELECT ID FROM Tests WHERE TestName=@TestName)
			)
			AND 
			(
				TestStageID = @TestStageID 
				OR
				(
					@TestStageId IS NULL AND TestStageID IS NULL
				)
			)
		UPDATE TestExceptions SET LastUser = @LastUser WHERE TestExceptions.ID IN (SELECT ID FROM #temp)
		DELETE FROM TestExceptions WHERE TestExceptions.ID IN (SELECT ID FROM #temp)
		
		SET @txID = (SELECT TOP 1 ID FROM #temp)
		DROP TABLE #temp
	END
	ELSE IF (@TestStageName IS NOT NULL And @TestStageID IS NOT NULL)
	BEGIN
		SET @txID = (SELECT ID 
				FROM vw_ExceptionsPivoted 
				WHERE TestUnitID = @TestUnitID 
					AND 
					(
						@TestID IS NULL AND Test IS NULL
					)
					AND 
					(
						TestStageID = @TestStageID
					)
				)
		
		--set the deleting user
		UPDATE TestExceptions SET LastUser = @LastUser WHERE TestExceptions.ID = @txid
		
		--finally delete the item
		DELETE FROM TestExceptions WHERE TestExceptions.ID = @txid
	END
	ELSE
	BEGIN
		SET @txID = 0
	END
	
	RETURN @txid
END
GO
GRANT EXECUTE ON remispTestExceptionsDeleteTestUnitException TO REMI
GO