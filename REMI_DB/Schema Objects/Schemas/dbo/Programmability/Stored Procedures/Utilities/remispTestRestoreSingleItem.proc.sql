ALTER PROCEDURE [dbo].[remispTestRestoreSingleItem]
	@ID int,
	@UserName nvarchar(255),
	@RestoreExceptions BIT = 0
AS
PRINT 'No Audit table exists for TrackingLocationsForTests so unfortunately they will not be restored.'

IF NOT EXISTS (SELECT 1 FROM Tests WHERE ID=@ID)
BEGIN
	PRINT 'Restoring Test'
	SET IDENTITY_INSERT Tests ON

	INSERT INTO Tests ([ID], [TestName], [Duration], [TestType], [WILocation], [Comment], [LastUser], [ResultBasedOntime])
	SELECT TestID AS [ID], [TestName], [Duration], [TestType], [WILocation], [Comment], @UserName AS [LastUser], [ResultBasedOntime]
	FROM TestsAudit
	WHERE Action='D' AND TestID=@ID
					
	SET IDENTITY_INSERT Tests OFF

	IF NOT EXISTS (SELECT 1 FROM BatchSpecificTestDurations WHERE TestID=@ID)
	BEGIN
		PRINT 'Restoring BatchSpecificTestDurations'
		SET IDENTITY_INSERT BatchSpecificTestDurations ON

		INSERT INTO BatchSpecificTestDurations ([ID], [BatchID], [TestID], [Duration], [LastUser], [Comment])
		SELECT BatchSpecificTestDurationID AS ID, BatchID, TestID, Duration, @UserName AS LastUser, Comment
		FROM BatchSpecificTestDurationsAudit
		WHERE Action='D' AND TestID=@ID
					
		SET IDENTITY_INSERT BatchSpecificTestDurations OFF
	END
	ELSE
	BEGIN
		PRINT 'BatchSpecificTestDurations For Test to Restore Already Exists!'
	END

	IF (@RestoreExceptions=1)
	BEGIN
		PRINT 'Restoring ALL Exceptions that have been previously deleted that contain the TestID associated for restore!'

		--Donn't insert exceptions that have been previously inserted by the TestStage Exception restore
		INSERT INTO TestExceptions (ID, LookupID, Value, LastUser)
		SELECT ID, LookupID, Value, @UserName AS LastUser
		FROM TestExceptionsAudit
		WHERE Action='D' AND ID IN (SELECT DISTINCT ID FROM TestExceptionsAudit WHERE LookupID=4 AND Action='D' AND Value=@ID)
	END
	ELSE
	BEGIN
		PRINT 'Exceptions will not be restored as selected!'
	END
END
ELSE
BEGIN
	PRINT 'Test Already Exists. It will not be restored.'
END