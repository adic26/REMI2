ALTER PROCEDURE [dbo].[remispTestsInsertUpdateSingleItem]
	@TestName nvarchar(400), 
	@Duration real, 
	@TestType int,
	@WILocation nvarchar(800)=null,
	@Comment nvarchar(1000)=null,	
	@ID int OUTPUT,
	@LastUser nvarchar(255),
	@ResultBasedOnTime bit,
	@ConcurrencyID rowversion OUTPUT,
	@IsArchived BIT = 0,
	@Owner NVARCHAR(255) = NULL,
	@Trainee NVARCHAR(255) = NULL,
	@DegradationVal DECIMAL(10,3)
AS
	DECLARE @ReturnValue int
	
	IF (@ID IS NULL) and (((select count (*) from Tests where TestName = @TestName)= 0) or @TestType != 1)-- New Item
	BEGIN
		INSERT INTO Tests (TestName, Duration, TestType, WILocation, Comment, lastUser, ResultBasedOntime, IsArchived, [Owner], Trainee, DegradationVal)
		VALUES (LTRIM(RTRIM(@TestName)), @Duration, @TestType, @WILocation, LTRIM(RTRIM(@Comment)), @lastUser, @ResultBasedOnTime, @IsArchived, @Owner, @Trainee, @DegradationVal)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE Tests SET
			TestName = LTRIM(RTRIM(@TestName)), 
			Duration = @Duration, 
			TestType = @TestType, 
			WILocation = @WILocation,
			Comment = LTRIM(RTRIM(@Comment)),
			lastUser = @LastUser,
			ResultBasedOntime = @ResultBasedOnTime,
			IsArchived = @IsArchived,
			[Owner]=@Owner, Trainee=@Trainee, DegradationVal = @DegradationVal
		WHERE ID = @ID AND ConcurrencyID = @ConcurrencyID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM Tests WHERE ID = @ReturnValue)
	SET @ID = @ReturnValue
	
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN 0
	END
GO
GRANT EXECUTE ON remispTestsInsertUpdateSingleItem TO REMI
GO