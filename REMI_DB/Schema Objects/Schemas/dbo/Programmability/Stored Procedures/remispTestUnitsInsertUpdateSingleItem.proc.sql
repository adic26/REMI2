ALTER PROCEDURE [dbo].[remispTestUnitsInsertUpdateSingleItem]
	@ID int OUTPUT,
	@QRANumber nvarchar(11), 
	@BSN bigint, 
	@BatchUnitNumber int, 
	@AssignedTo nvarchar(255) = null,
	@CurrentTestStageName nvarchar(400) = null,
	@CurrentTestName nvarchar(400) = null,
	@LastUser nvarchar(255),
	@Comment nvarchar(1000) = null,
	@ConcurrencyID rowversion OUTPUT,
	@IMEI NVARCHAR(150) = NULL
AS
BEGIN
	DECLARE @ReturnValue int
	declare @batchid int
		--get the batch id
	set @BatchID = (select ID from Batches where QRANumber = @QRANumber)
	
	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO TestUnits (BatchID, BSN, BatchUnitNumber, AssignedTo, CurrentTestStageName, CurrentTestName, LastUser, Comment, IMEI)
		VALUES (@BatchID, @BSN, @BatchUnitNumber, @AssignedTo, @CurrentTestStageName, @CurrentTestName, @LastUser, @Comment, @IMEI)

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
			Comment = @Comment, IMEI=@IMEI
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
END
GO
GRANT EXECUTE ON [dbo].[remispTestUnitsInsertUpdateSingleItem] TO REMI
GO