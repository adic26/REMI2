ALTER PROCEDURE [dbo].[remispTestStagesInsertUpdateSingleItem]
/*	'===============================================================
	'   NAME:                	remispTestStagesInsertUpdateSingleItem
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates or updates an item in a table: TestStages      
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
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
	begin transaction AddTestStage
	declare @jobID int
	set @jobID = (select ID from Jobs where JobName = @jobname)
	
	if @jobID is null and @JobName is not null --the job was not added to the db yet so add it to get an id.
	begin
		execute remispJobsInsertUpdateSingleItem null, @jobname,null,null,@lastuser,null
	end
	--try again
	set @jobID = (select ID from Jobs where JobName = @jobname)
	DECLARE @ReturnValue int

	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO TestStages
		(
			TestStageName, 
			TestStageType,
			JobID,
			TestID,
			LastUser,
			Comment,
			ProcessOrder,
			IsArchived
		)
		VALUES
		(
			@TestStageName, 
			@TestStageType,
			@JobID,
			@TestID,
			@LastUser,
			@Comment,
			@ProcessOrder,
			@IsArchived
		)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
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
		WHERE 
			ID = @ID
			AND ConcurrencyID = @ConcurrencyID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM TestStages WHERE ID = @ReturnValue)
	SET @ID = @ReturnValue
	commit transaction AddTestStage
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