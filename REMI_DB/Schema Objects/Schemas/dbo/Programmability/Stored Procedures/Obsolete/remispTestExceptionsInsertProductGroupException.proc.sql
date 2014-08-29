ALTER PROCEDURE [dbo].[remispTestExceptionsInsertProductGroupException]
/*	'===============================================================
	'   NAME:                	remispTestExceptionsInsertProductGroupException
	'   DATE CREATED:       	22 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates an item in a table: TestUnitTestExceptions
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@ReasonForRequest int = null,
	@TestName nvarchar(400) = null,
	@TestStageName nvarchar(400) = null,
	@JobName nvarchar(400)=null,
	@ProductID INT=null,
	@LastUser nvarchar(255),
	@ProductTypeID INT = NULL,
	@AccessoryGroupID INT = NULL,
	@TestStageID int = null,
	@TestID INT = null,
	@TestCenterID INT = NULL,
	@IsMQual INT  = NULL
AS		
	DECLARE @ReturnValue int
	declare @testUnitID int
	declare @ValidInputParams int = 1
	
	if (@teststageid is null and @TestStageName is not null)
	begin
		set @TestStageID = (select ts.id from TestStages as ts, Jobs as j where j.JobName = @JobName and ts.JobID = j.ID and ts.TestStageName = @TestStageName)
	end

	PRINT 'TestStageID: ' + CONVERT(NVARCHAR, ISNULL(@TestStageID, ''))
		
	--test if item exists in db already

	set @ReturnValue = (SELECT DISTINCT pvt.ID
	FROM vw_ExceptionsPivoted as pvt
		LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	where (ReasonForRequest = @ReasonForRequest)
		and (TestStageID = @TestStageID)
		and (testname = @testname OR t.ID = @TestID)
		and (ProductID = @ProductID))

	IF (@ReturnValue IS NULL) -- if it doesnt already exist then add it
	BEGIN
		PRINT 'INSERTING'
		DECLARE @ID INT
		SELECT @ID = MAX(ID)+1 FROM TestExceptions
		PRINT @ID

		IF (@TestID IS NOT NULL)
		BEGIN
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @TestID, @LastUser)
		END
		ELSE IF (@TestName IS NOT NULL)
		BEGIN
			PRINT 'Inserting TEST'
			DECLARE @tID INT
			IF ((SELECT COUNT(*) FROM Tests WITH(NOLOCK) WHERE TestName=@TestName) = 1)
			BEGIN
				SELECT @tID = ID FROM Tests WITH(NOLOCK) WHERE TestName=@TestName
				INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @tID, @LastUser)
			END
			ELSE
			BEGIN
				IF (@TestStageID IS NOT NULL AND EXISTS (SELECT TestID FROM TestStages WITH(NOLOCK) WHERE ID=@TestStageID AND TestID IS NOT NULL))
				BEGIN
					SET @tID = (SELECT TestID FROM TestStages WITH(NOLOCK) WHERE ID=@TestStageID AND TestID IS NOT NULL)
					INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @tID, @LastUser)
				END
			END
		END

		IF (@TestStageID IS NOT NULL)
		BEGIN
			PRINT 'Inserting TestStage'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 4, @TestStageID, @LastUser)
		END

		IF (@ReasonForRequest IS NOT NULL)
		BEGIN
			PRINT 'Inserting ReasonForRequest'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 2, @ReasonForRequest, @LastUser)
		END

		IF (@ProductID > 0)
		BEGIN
			PRINT 'Inserting ProductID'
			DECLARE @LookupID INT
			SELECT @LookupID=LookupID FROM Lookups WHERE Type='Exceptions' AND [Values]='ProductID'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, @LookupID, @ProductID, @LastUser)
		END

		IF (@ProductTypeID IS NOT NULL AND @ProductTypeID > 0)
		BEGIN
			PRINT 'Inserting ProductType'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 6, @ProductTypeID, @LastUser)
		END

		IF (@AccessoryGroupID IS NOT NULL AND @AccessoryGroupID > 0)
		BEGIN
			PRINT 'Inserting AccessoryGroupName'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 7, @AccessoryGroupID, @LastUser)
		END

		IF (@TestCenterID IS NOT NULL AND @TestCenterID > 0)
		BEGIN
			PRINT 'Inserting TestCenterID'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 3516, @TestCenterID, @LastUser)
		END

		IF (@IsMQual IS NOT NULL)
		BEGIN
			PRINT 'Inserting IsMQual'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 3517, @IsMQual, @LastUser)
		END

		SET @ReturnValue = @ID
	END
	
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN @ReturnValue
	END
GO
GRANT EXECUTE ON remispTestExceptionsInsertProductGroupException TO Remi
GO