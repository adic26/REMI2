CREATE PROCEDURE [dbo].[remispTestRecordsAddTLLink]
/*	'===============================================================
	'   NAME:                	remispTestRecordsAddTLLink
	'   DATE CREATED:       	12 Nov 2009
	'   CREATED BY:          	Darragh O Riordan
	'   FUNCTION:            	Creates or updates an item in a table: TestRecordsXTrackingLogs
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@TestRecordID int,
	@TrackingLogID int

as
declare @ID int

Set @id = (select ID from TestRecordsXTrackingLogs where TestRecordID = @TestRecordID and TrackingLogID = @TrackingLogID)
	
	DECLARE @ReturnValue int

	IF (@ID IS NULL) -- New Item so insert it
	BEGIN
		INSERT INTO TestRecordsXTrackingLogs
		(
			TestRecordID,
			TrackingLogID
					
					)
		VALUES
		(
		@TestRecordID,
		@TrackingLogID
		)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
		
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN 0
	END


