ALTER PROCEDURE [dbo].[remispTestStagesRestoreSingleItem]
	@ID int,
	@UserName nvarchar(255),
	@RestoreJob BIT = 0,
	@RestoreExceptions BIT = 0
AS
DECLARE @TestID INT
DECLARE @teststagetype INT
DECLARE @JobID INT
DECLARE @ExceptionsID TABLE (ID INT)

--Meaning the test stage wasn't already restored based on ID or TestStageName.
--The test stage could have been manually inserted or created but the ID would differ due to identity insert.
--If one of these exist bail out and notify the user.
IF NOT EXISTS (SELECT 1 FROM TestStages WHERE ID=@ID OR TestStages.TestStageName = (SELECT TestStageName FROM TestStagesAudit WHERE Action='D' AND TestStageID=@ID))
	BEGIN
		select @TestID = testid, @teststagetype = teststagetype, @JobID = JobID
		from TestStagesAudit as tsa 
		where tsa.Action='D' AND tsa.TestStageID = @ID

		--Meaning the job either exists or we are asked to restore the job from audit table.
		IF EXISTS (SELECT 1 FROM Jobs WHERE ID=@JobID) OR @RestoreJob=1
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM Jobs WHERE ID=@JobID)
			BEGIN
				PRINT 'Creating Missing Jobs Link As Requested'
				SET IDENTITY_INSERT Jobs ON

				INSERT INTO Jobs ([ID],[JobName], [WILocation], [Comment], [LastUser], [OperationsTest], [MechanicalTest], [TechnicalOperationsTest])
				SELECT JobID AS ID, [JobName], [WILocation], [Comment], @UserName AS [LastUser], 0 AS [OperationsTest], 0 AS [MechanicalTest], 0 AS [TechnicalOperationsTest]
				FROM JobsAudit
				WHERE Action='D' AND JobID=@JobID

				SET IDENTITY_INSERT Jobs OFF
			END
			
			PRINT 'Creating Missing TestStages Record As Requested'

			SET IDENTITY_INSERT TestStages ON

			INSERT INTO TestStages (ID, TestStageName, TestStageType, JobID, LastUser, Comment, TestID, ProcessOrder)
			SELECT TestStageID AS ID, TestStageName, TestStageType, JobID, @UserName AS LastUser, Comment, TestID, ProcessOrder
			FROM TestStagesAudit as tsa 
			where tsa.Action='D' AND tsa.TestStageID = @ID
		
			SET IDENTITY_INSERT TestStages OFF

			PRINT 'No Audit table exists for TaskAssignments so unfortunately they will not be restored.'

			IF (@RestoreExceptions=1)
			BEGIN
				PRINT 'Restoring ALL Exceptions that have been previously deleted that contain the TestStageID specified for restore!'

				INSERT INTO @ExceptionsID (ID)
				SELECT ID
				FROM TestExceptionsAudit
				WHERE Action='D' AND ID IN (SELECT DISTINCT ID FROM TestExceptionsAudit WHERE LookupID=4 AND Action='D' AND Value=@ID)

				INSERT INTO TestExceptions (ID, LookupID, Value, LastUser)
				SELECT ID, LookupID, Value, @UserName AS LastUser
				FROM TestExceptionsAudit
				WHERE Action='D' AND ID IN (SELECT ID FROM @ExceptionsID)
			END
			ELSE
			BEGIN
				PRINT 'Exceptions will not be restored for Test Stages as selected!'
			END

			--If this was an environmental stress test restore the deleted corrisponding test
			IF (@teststagetype = 2)
			BEGIN
				PRINT 'No Audit table exists for TrackingLocationsForTests so unfortunately they will not be restored.'

				IF NOT EXISTS (SELECT 1 FROM Tests WHERE ID=@TestID)
				BEGIN
					PRINT 'Restoring Test'
					SET IDENTITY_INSERT Tests ON

					INSERT INTO Tests ([ID], [TestName], [Duration], [TestType], [WILocation], [Comment], [LastUser], [ResultBasedOntime])
					SELECT TestID AS [ID], [TestName], [Duration], [TestType], [WILocation], [Comment], @UserName AS [LastUser], [ResultBasedOntime]
					FROM TestsAudit
					WHERE Action='D' AND TestID=@TestID
					
					SET IDENTITY_INSERT Tests OFF

					IF NOT EXISTS (SELECT 1 FROM BatchSpecificTestDurations WHERE TestID=@TestID)
					BEGIN
						PRINT 'Restoring BatchSpecificTestDurations'
						SET IDENTITY_INSERT BatchSpecificTestDurations ON

						INSERT INTO BatchSpecificTestDurations ([ID], [BatchID], [TestID], [Duration], [LastUser], [Comment])
						SELECT BatchSpecificTestDurationID AS ID, BatchID, TestID, Duration, @UserName AS LastUser, Comment
						FROM BatchSpecificTestDurationsAudit
						WHERE Action='D' AND TestID=@TestID
					
						SET IDENTITY_INSERT BatchSpecificTestDurations OFF
					END
					ELSE
					BEGIN
						PRINT 'BatchSpecificTestDurations For Test Already Exists!'
					END

					IF (@RestoreExceptions=1)
					BEGIN
						PRINT 'Restoring ALL Exceptions that have been previously deleted that contain the TestID associate to TestStage for restore!'

						--Donn't insert exceptions that have been previously inserted by the TestStage Exception restore
						INSERT INTO TestExceptions (ID, LookupID, Value, LastUser)
						SELECT ID, LookupID, Value, @UserName AS LastUser
						FROM TestExceptionsAudit
						WHERE Action='D' AND ID IN (SELECT DISTINCT ID FROM TestExceptionsAudit WHERE LookupID=5 AND Action='D' AND Value=@TestID AND ID NOT IN (SELECT ID FROM @ExceptionsID))
					END
					ELSE
					BEGIN
						PRINT 'Exceptions will not be restored for Test as selected!'
					END
				END
				ELSE
				BEGIN
					PRINT 'Test Already Exists. It will not be restored.'
				END
			END
		END
		ELSE
		BEGIN
			RAISERROR ('Job associated with Test Stage doesn''t exist! No action. Please pass in create job bit to create the job.', 16, 1)			
		END
	END
else
	BEGIN
		RAISERROR ('TestStage ID or TestStageName appears to have already been restored! No action. Please review', 16, 1)
	END