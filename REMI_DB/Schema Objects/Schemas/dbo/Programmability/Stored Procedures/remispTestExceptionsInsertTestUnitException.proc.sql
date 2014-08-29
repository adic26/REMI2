ALTER PROCEDURE [dbo].[remispTestExceptionsInsertTestUnitException]
/*	'===============================================================
	'   NAME:                	remispTestExceptionsInsertTestUnitException
	'   DATE CREATED:       	22 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates an item in a table: TestUnitTestExceptions
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@QRANumber nvarchar(11),
	@BatchUnitNumber int,
	@TestName nvarchar(400) = null,
	@TestStageName nvarchar(400) = null,
	@LastUser nvarchar(255),
	@TestStageID int = null,
	@testunitid int = null,
	@ProductTypeID INT = NULL,
	@AccessoryGroupID INT = NULL,
	@TestID INT = NULL
AS		
	DECLARE @ReturnValue int	
	
	--get the test unit id
	if @testunitid is  null and (@QRANumber is not null and @BatchUnitNumber is not null)
	begin
		set @testUnitID = (select tu.Id from TestUnits tu WITH(NOLOCK) INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID where b.QRANumber = @QRANumber AND tu.batchunitnumber = @Batchunitnumber)

		PRINT 'TestUnitID: ' + CONVERT(NVARCHAR, ISNULL(@testUnitID,''))
	end	
		
	--Get the test stage id
	if (@teststageid is null and @TestStageName is not null)
	begin
		set @TestStageID = (select ts.ID from TestStages as ts, TestUnits as tu,Jobs as j, Batches as b 
		where tu.ID=@testUnitID and b.ID=tu.BatchID and ts.TestStageName = @TestStageName and ts.JobID = j.ID and
		j.JobName = b.jobname)
		
		PRINT 'TestStageID: ' + CONVERT(NVARCHAR, ISNULL(@TestStageID,''))
	end 
	
	set @ReturnValue = (SELECT DISTINCT pvt.ID
	FROM vw_ExceptionsPivoted as pvt
		LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	where (testunitid = @testunitid)
	and 
	(
		TestStageID = @TestStageID 
		or
		(@TestStageID is null and TestStageID is null)
	)
	and 
	(
		(t.TestName = @testname AND @TestID IS NULL)
		or 
		(@TestName is null and TestName is null AND @TestID IS NULL)
		OR
		(t.ID = @TestID AND @TestID IS NOT NULL)
	)
	)
	
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
			PRINT 'Inserting TestName'
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
			PRINT 'Inserting TestStageID'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 4, @TestStageID, @LastUser)
		END
		
		IF (@TestUnitID IS NOT NULL)
		BEGIN
			PRINT 'Inserting TestUnitID'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 3, @TestUnitID, @LastUser)
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

		SET @ReturnValue = @ID		
	ENd
		
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN @returnvalue
	END
GO
GRANT EXECUTE On remispTestExceptionsInsertTestUnitException TO REMI
GO