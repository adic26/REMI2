CREATE PROCEDURE [dbo].[remispTestUnitsSetBSN]
/*	'===============================================================
	'   NAME:                	remispTestUnitsSetBSN
	'   DATE CREATED:       	1 Nov 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates or updates an item in a table: TestUnits
	'   IN:         BSN, QRANumber, UnitNumber     
	'   OUT: 		ID      
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@QRANumber nvarchar(11), 
	@BSN bigint, 
	@UnitNumber int,
	@UpdateUser nvarchar(255)
	
	AS
	
	declare @ReturnValue int
	declare @batchid int
			--get the batch id
	set @BatchID = (select ID from Batches where QRANumber = @QRANumber)
	
	UPDATE TestUnits SET
			BSN = @BSN,
			LastUser = @UpdateUser
					WHERE batchid=@batchid and BatchUnitNumber = @UnitNumber
		

	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN 0
	END
