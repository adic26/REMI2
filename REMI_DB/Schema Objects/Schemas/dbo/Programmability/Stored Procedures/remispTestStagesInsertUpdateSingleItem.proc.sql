ALTER PROCEDURE [dbo].[remispTestStagesInsertUpdateSingleItem]
	@ID int OUTPUT,
	@TestStageName nvarchar(400), 
	@TestStageType int,
	@JobName  nvarchar(400),
	@Comment  nvarchar(1000)=null,
	@TestID int = null,
	@LastUser  nvarchar(255),
	@ConcurrencyID rowversion OUTPUT,
	@ProcessOrder int = 0,
	@IsArchived BIT = 0
AS
	BEGIN TRANSACTION AddTestStage
	
	DECLARE @jobID int
	DECLARE @ReturnValue int
	
	SET @jobID = (SELECT ID FROM Jobs WHERE JobName = @jobname)
	
	if @jobID is null and @JobName is not null --the job was not added to the db yet so add it to get an id.
	begin
		execute remispJobsInsertUpdateSingleItem null, @jobname,null,null,@lastuser,null
	end
	
	SET @jobID = (select ID from Jobs where JobName = @jobname)

	IF (@ID IS NULL AND NOT EXISTS (SELECT 1 FROM TestStages WHERE JobID=@jobID AND TestStageName=@TestStageName)) -- New Item
	BEGIN
		INSERT INTO TestStages (TestStageName, TestStageType, JobID, TestID, LastUser, Comment, ProcessOrder, IsArchived)
		VALUES (@TestStageName, @TestStageType, @JobID, @TestID, @LastUser, @Comment, @ProcessOrder, @IsArchived)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE IF (@ConcurrencyID IS NOT NULL) -- Exisiting Item
	BEGIN
		UPDATE TestStages SET
			TestStageName = @TestStageName, 
			TestStageType = @TestStageType,
			JobID = @JobID,
			TestID=@TestID,
			LastUser = @LastUser,
			Comment = @Comment,
			ProcessOrder = @ProcessOrder,
			IsArchived = @IsArchived
		WHERE ID = @ID AND ConcurrencyID = @ConcurrencyID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM TestStages WHERE ID = @ReturnValue)
	SET @ID = @ReturnValue
	
	COMMIT TRANSACTION AddTestStage
	
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN 0
	END
GO
GRANT EXECUTE On remispTestStagesInsertUpdateSingleItem TO REMI
GO