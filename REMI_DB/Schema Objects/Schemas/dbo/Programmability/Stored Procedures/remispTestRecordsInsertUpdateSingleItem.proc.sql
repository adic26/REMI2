ALTER PROCEDURE [dbo].[remispTestRecordsInsertUpdateSingleItem]
	@ID int OUTPUT,	
	@TestUnitID int,
	@TestStageName nvarchar(400),
	@JobName nvarchar(400),
	@TestName nvarchar(400),
	@FailDocRQID int = null,
	@Status int,
	@ResultSource int = null,
	@FailDocNumber nvarchar(500) = null,
	@RelabVersion int,	
	@Comment nvarchar(1000)=null,
	@ConcurrencyID rowversion OUTPUT,
	@LastUser nvarchar(255),
	@TestID INT = NULL,
	@TestStageID INT = NULL,
	@FunctionalType INT = NULL
AS
BEGIN
	DECLARE @JobID INT
	DECLARE @ReturnValue INT
	
	IF (@ID is null or @ID <=0 ) --no dupes allowed here!
	BEGIN
		SET @ID = (SELECT ID FROM TestRecords WITH(NOLOCK) WHERE TestStageName = LTRIM(RTRIM(@TestStageName)) AND JobName = LTRIM(RTRIM(@JobName)) AND testname=LTRIM(RTRIM(@TestName)) AND testunitid=@TestUnitID)
	END
	
	if (@TestID is null and @TestName is not null)
	begin
		SELECT @TestID=ID FROM Tests WITH(NOLOCK) WHERE TestName=LTRIM(RTRIM(@TestName))
	END

	if (@TestStageID is null and @TestStageName is not null)
	begin
		SELECT @JobID=ID FROM Jobs WITH(NOLOCK) WHERE JobName=LTRIM(RTRIM(@JobName))
		SELECT @TestStageID=ID FROM TestStages WITH(NOLOCK) WHERE JobID=@JobID AND TestStageName=LTRIM(RTRIM(@TestStageName))
	END

	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO TestRecords (TestUnitID, Status, FailDocNumber, TestStageName, JobName, TestName, RelabVersion, LastUser, Comment,
			ResultSource, FailDocRQID, TestID, TestStageID, FunctionalType)
		VALUES (@TestUnitID, @Status, @FailDocNumber, LTRIM(RTRIM(@TestStageName)), LTRIM(RTRIM(@JobName)), LTRIM(RTRIM(@TestName)), @RelabVersion, @lastUser, LTRIM(RTRIM(@Comment)),
			@ResultSource, @FailDocRQID, @TestID, @TestStageID, @FunctionalType)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE TestRecords 
		SET TestUnitID = @TestUnitID, 
			Status = @Status, 
			FailDocNumber = @FailDocNumber,
			TestStageName = LTRIM(RTRIM(@TestStageName)),
			JobName = LTRIM(RTRIM(@JobName)),
			TestName = LTRIM(RTRIM(@TestName)),
			RelabVersion = @RelabVersion,
			lastuser = @LastUser,
			Comment = LTRIM(RTRIM(@Comment)),
			ResultSource = @ResultSource,
			FailDocRQID = @FailDocRQID,
			TestID=@TestID,
			TestStageID=@TestStageID, FunctionalType=@FunctionalType
		WHERE ID = @ID AND ConcurrencyID = @ConcurrencyID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM TestRecords WHERE ID = @ReturnValue)
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
GRANT EXECUTE ON remispTestRecordsInsertUpdateSingleItem TO Remi
GO