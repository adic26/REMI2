CREATE PROCEDURE [dbo].[remispTestUnitsAddUnitToBatch]
/*	'===============================================================
	'   NAME:                	remispTestUnitsAddUnitToBatch
	'   DATE CREATED:       	20 Nov 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Adds a new test unit to a batch if it does not already exist.
	'   VERSION: 1                   
	'   COMMENTS: 
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@ID int = 0 OUTPUT ,
	@QRANumber nvarchar(11), 
	@BSN bigint, 
	@BatchUnitNumber int, 
	@LastUser nvarchar(255),
	@Comment nvarchar(1000)=null,
	@TestStageName nvarchar(400)
	AS

	DECLARE @ReturnValue int
	declare @BatchID int
	declare @TestUnitID int
	
	--get the batch id
	set @BatchID = (select ID from Batches where QRANumber = @QRANumber)
	
			--check if the unit already exists
			set @TestUnitID = (select ID from TestUnits where 
			(batchid = @BatchID and BatchUnitNumber = @batchunitnumber) )
			
			if (@TestUnitID is null) --it does not so save the unit.
			begin
			INSERT INTO TestUnits
					(
					BatchID, 
					BSN, 
					BatchUnitNumber,
					LastUser,
					Comment,
					CurrentTestStageName
					)
					VALUES
					(
					@Batchid, 
					@BSN, 
					@BatchUnitNumber, 
					@lastUser,
					@comment,
					@TestStageName
					)
			
				set @ID = SCOPE_IDENTITY()
			end

	
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN 0
	END
