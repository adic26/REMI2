ALTER PROCEDURE [dbo].[remispJobsInsertUpdateSingleItem]
/*	'===============================================================
	'   NAME:                	remispJobsInsertUpdateSingleItem
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates or updates an item in a table: Jobs
    '   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@ID int OUTPUT,
	@JobName nvarchar(400),
	@WILocation nvarchar(400)=null,
	@Comment nvarchar(1000)=null,
	@LastUser nvarchar(255),
	@ConcurrencyID rowversion OUTPUT,
	@OperationsTest bit = 0,
	@TechOperationsTest bit = 0,
	@MechanicalTest bit = 0,
	@ProcedureLocation nvarchar(400)=null,
	@IsActive bit = 0, @NoBSN BIT = 0, @ContinueOnFailures BIT = 0
	AS

	DECLARE @ReturnValue int
	
	set @ID = (select ID from Jobs WITH(NOLOCK) where jobs.JobName=LTRIM(RTRIM(@JobName)))
	
	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO Jobs(JobName, WILocation, Comment, LastUser, OperationsTest, TechnicalOperationsTest, MechanicalTest, ProcedureLocation, IsActive, NoBSN, ContinueOnFailures)
		VALUES(LTRIM(RTRIM(@JobName)), @WILocation, LTRIM(RTRIM(@Comment)), @LastUser, @OperationsTest, @TechOperationsTest, @MechanicalTest, @ProcedureLocation, @IsActive, @NoBSN, @ContinueOnFailures)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE Jobs SET
			JobName = LTRIM(RTRIM(@JobName)), 
			LastUser = @LastUser,
			Comment = LTRIM(RTRIM(@Comment)),
			WILocation = @WILocation,
			OperationsTest = @OperationsTest,
			TechnicalOperationsTest = @TechOperationsTest,
			MechanicalTest = @MechanicalTest,
			ProcedureLocation = @ProcedureLocation,
			IsActive = @IsActive,
			NoBSN = @NoBSN,
			ContinueOnFailures = @ContinueOnFailures
		WHERE ID = @ID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM Jobs WITH(NOLOCK) WHERE ID = @ReturnValue)
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
GRANT EXECUTE ON remispJobsInsertUpdateSingleItem TO REMI
GO