CREATE PROCEDURE [dbo].[remispTestUnitsInsertUpdateSingleItem]
/*	'===============================================================
	'   NAME:                	remispTestUnitsInsertUpdateSingleItem
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates or updates an item in a table: TestUnits
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@ID int OUTPUT,
	@QRANumber nvarchar(11), 
	@BSN bigint, 
	@BatchUnitNumber int, 
	@AssignedTo nvarchar(255) = null,
	@CurrentTestStageName nvarchar(400) = null,
	@CurrentTestName nvarchar(400) = null,
	@LastUser nvarchar(255),
	@Comment nvarchar(1000) = null,
	@ConcurrencyID rowversion OUTPUT

	AS

	DECLARE @ReturnValue int
	declare @batchid int
		--get the batch id
	set @BatchID = (select ID from Batches where QRANumber = @QRANumber)
	
	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO TestUnits
		(
			BatchID, 
			BSN, 
			BatchUnitNumber,
			AssignedTo,
			CurrentTestStageName, 
			CurrentTestName,
			LastUser,
			Comment
		)
		VALUES
		(
			@BatchID, 
			@BSN, 
			@BatchUnitNumber,
			@AssignedTo,
			@CurrentTestStageName, 
			@CurrentTestName,
			@LastUser,
			@Comment
		)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE TestUnits SET
			batchid = @batchid, 
			BSN = @BSN, 
			BatchUnitNumber =@BatchUnitNumber,
			AssignedTo = @AssignedTo,
			CurrentTestStageName = @CurrentTestStageName, 
			CurrentTestName = @CurrentTestName,
			LastUser = @LastUser,
			Comment = @Comment
		WHERE 
			ID = @ID
			AND ConcurrencyID = @ConcurrencyID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM TestUnits WHERE ID = @ReturnValue)
	SET @ID = @ReturnValue
	
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN 0
	END
